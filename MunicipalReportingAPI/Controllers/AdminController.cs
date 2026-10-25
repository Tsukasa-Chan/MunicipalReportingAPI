using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MunicipalReportingAPI.Data;
using MunicipalReportingAPI.DTO;
using MunicipalReportingAPI.Models;
using MunicipalReportingAPI.Services;
using System.Security.Claims;
using System.Security.Cryptography;

namespace MunicipalReportingAPI.Controllers
{
    
    [Route("api/admin")]
    [ApiController]
    [Authorize(Roles = "Admin")]
    public class AdminController : ControllerBase
    {
        private const string UserRole = "User";
        private const string SupervisorRole = "Supervisor";
        private const string AdminRole = "Admin";

        private readonly MunicipalDBContext _context;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IUserDeletionService _userDeletionService;
        private readonly IEmailService _emailService;
        private readonly IConfiguration _config;
        private readonly IWebHostEnvironment _env;
        private readonly ILogger<AdminController> _logger;

        public AdminController(
            MunicipalDBContext context,
            UserManager<ApplicationUser> userManager,
            IUserDeletionService userDeletionService,
            IEmailService emailService,
            IConfiguration config,
            IWebHostEnvironment env,
            ILogger<AdminController> logger)
        {
            _context = context;
            _userManager = userManager;
            _userDeletionService = userDeletionService;
            _emailService = emailService;
            _config = config;
            _env = env;
            _logger = logger;
        }

        private int GetCurrentUserId()
        {
            return int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        }

        // Matches a role name case-insensitively and returns the canonical spelling (or null)
        private static string? NormalizeRole(string? role, bool includeAdmin)
        {
            var allowed = includeAdmin
                ? new[] { UserRole, SupervisorRole, AdminRole }
                : new[] { UserRole, SupervisorRole };

            return allowed.FirstOrDefault(r => r.Equals(role?.Trim(), StringComparison.OrdinalIgnoreCase));
        }

        // Shared projection: user + role + report count + assigned issue count
        private IQueryable<AdminUserDTO> ProjectUsers(IQueryable<ApplicationUser> query)
        {
            var now = DateTimeOffset.UtcNow;

            return query.Select(u => new AdminUserDTO
            {
                Id = u.Id,
                FullName = u.FullName,
                Email = u.Email,
                EmailConfirmed = u.EmailConfirmed,
                ProfilePictureUrl = u.ProfilePictureUrl,
                LockedOut = u.LockoutEnd != null && u.LockoutEnd > now,
                Role = (from ur in _context.UserRoles
                        join r in _context.Roles on ur.RoleId equals r.Id
                        where ur.UserId == u.Id
                        select r.Name).FirstOrDefault(),
                ReportCount = _context.Reports.Count(r => r.UserId == u.Id),
                AssignedIssueCount = _context.Issues.Count(i => i.SupervisorId == u.Id)
            });
        }

        
        // 1. Manage users
        // List / search users. Also feeds the "pick a supervisor" dropdown: ?role=Supervisor
        [HttpGet("users")]
        public async Task<IActionResult> GetUsers(
            [FromQuery] string? role,
            [FromQuery] string? search,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20)
        {
            if (page < 1) page = 1;
            pageSize = Math.Clamp(pageSize, 1, 100);

            var query = _userManager.Users.AsQueryable();

            if (!string.IsNullOrWhiteSpace(role))
            {
                var roleName = NormalizeRole(role, includeAdmin: true);
                if (roleName == null)
                {
                    return BadRequest("role must be User, Supervisor or Admin");
                }

                var roleId = await _context.Roles
                    .Where(r => r.Name == roleName)
                    .Select(r => (int?)r.Id)
                    .FirstOrDefaultAsync();

                if (roleId == null)
                {
                    return Ok(new { page, pageSize, totalCount = 0, items = new List<AdminUserDTO>() });
                }

                var rid = roleId.Value;
                query = query.Where(u => _context.UserRoles.Any(ur => ur.UserId == u.Id && ur.RoleId == rid));
            }

            if (!string.IsNullOrWhiteSpace(search))
            {
                var term = search.Trim();
                query = query.Where(u => u.FullName.Contains(term) || (u.Email != null && u.Email.Contains(term)));
            }

            var totalCount = await query.CountAsync();

            var items = await ProjectUsers(
                    query.OrderBy(u => u.FullName).ThenBy(u => u.Id)
                         .Skip((page - 1) * pageSize)
                         .Take(pageSize))
                .ToListAsync();

            return Ok(new { page, pageSize, totalCount, items });
        }

        [HttpGet("users/{id}")]
        public async Task<IActionResult> GetUser(int id)
        {
            var user = await ProjectUsers(_userManager.Users.Where(u => u.Id == id)).FirstOrDefaultAsync();

            if (user == null)
            {
                return NotFound();
            }

            return Ok(user);
        }

        // Promote a User to Supervisor, or demote a Supervisor back to User.
        // Admin can never be granted or changed here.
        [HttpPut("users/{id}/role")]
        public async Task<IActionResult> ChangeRole(int id, [FromBody] ChangeUserRoleDTO dto)
        {
            var newRole = NormalizeRole(dto.Role, includeAdmin: false);
            if (newRole == null)
            {
                return BadRequest("Role must be User or Supervisor");
            }

            if (id == GetCurrentUserId())
            {
                return BadRequest("You cannot change your own role.");
            }

            var user = await _userManager.FindByIdAsync(id.ToString());
            if (user == null)
            {
                return NotFound();
            }

            var currentRoles = await _userManager.GetRolesAsync(user);

            if (currentRoles.Contains(AdminRole))
            {
                return BadRequest("Admin accounts cannot be changed here.");
            }

            if (!currentRoles.Contains(newRole))
            {
                // One role per person keeps /api/auth/me and the token claims unambiguous
                if (currentRoles.Count > 0)
                {
                    var removeResult = await _userManager.RemoveFromRolesAsync(user, currentRoles);
                    if (!removeResult.Succeeded)
                    {
                        return BadRequest(removeResult.Errors.Select(e => e.Description).ToList());
                    }
                }

                var addResult = await _userManager.AddToRoleAsync(user, newRole);
                if (!addResult.Succeeded)
                {
                    return BadRequest(addResult.Errors.Select(e => e.Description).ToList());
                }

                // A demoted supervisor can no longer hold issues. They are kept, just unassigned.
                if (newRole == UserRole)
                {
                    var assignedIssues = await _context.Issues
                        .Where(i => i.SupervisorId == user.Id)
                        .ToListAsync();

                    foreach (var issue in assignedIssues)
                    {
                        issue.SupervisorId = null;
                        issue.UpdatedAt = DateTime.UtcNow;
                    }
                }

                // The person must sign in again. Without a refresh token they cannot renew
                // their session...
                var refreshTokens = await _context.RefreshTokens
                    .Where(rt => rt.UserId == user.Id && !rt.IsRevoked)
                    .ToListAsync();

                foreach (var token in refreshTokens)
                {
                    token.IsRevoked = true;
                }

                await _context.SaveChangesAsync();

                // ...and changing the security stamp makes their current access token invalid
                // on its very next use. Done last, so no token can be issued with the old role
                // after this point.
                var stampResult = await _userManager.UpdateSecurityStampAsync(user);

                if (!stampResult.Succeeded)
                {
                    _logger.LogError("Role changed for user {UserId} but ending their sessions failed: {Errors}",
                        user.Id, string.Join("; ", stampResult.Errors.Select(e => e.Description)));

                    return StatusCode(StatusCodes.Status500InternalServerError,
                        "The role was changed, but the user's current session could not be ended. " +
                        "They will pick up the change when their access token expires.");
                }
            }

            var result = await ProjectUsers(_userManager.Users.Where(u => u.Id == id)).FirstAsync();
            return Ok(result);
        }

        // Remove an account. Same data rules as a user deleting their own account.
        [HttpDelete("users/{id}")]
        public async Task<IActionResult> DeleteUser(int id)
        {
            if (id == GetCurrentUserId())
            {
                return BadRequest("You cannot delete your own account here.");
            }

            var user = await _userManager.FindByIdAsync(id.ToString());
            if (user == null)
            {
                return NotFound();
            }

            if (await _userManager.IsInRoleAsync(user, AdminRole))
            {
                return BadRequest("Admin accounts cannot be removed here.");
            }

            var result = await _userDeletionService.DeleteUserAsync(user);

            if (!result.Succeeded)
            {
                return BadRequest(result.Errors.Select(e => e.Description).ToList());
            }

            return Ok(new { message = "User deleted successfully" });
        }

        
        // 2. Create supervisors
        // Creates the account directly in the Supervisor role. The email is marked as
        // confirmed (the admin vouches for the employee) and a password-reset email lets
        // the supervisor choose their own password, so no password is shared or returned.
        [HttpPost("supervisors")]
        public async Task<IActionResult> CreateSupervisor([FromBody] CreateSupervisorDTO dto)
        {
            if (await _userManager.FindByEmailAsync(dto.Email) != null)
            {
                return Conflict("A user with this email already exists. Promote the existing user instead.");
            }

            var user = new ApplicationUser
            {
                FullName = dto.FullName.Trim(),
                Email = dto.Email,
                UserName = dto.Email,
                EmailConfirmed = true
            };

            var createResult = await _userManager.CreateAsync(user, GenerateTemporaryPassword());

            if (!createResult.Succeeded)
            {
                return BadRequest(createResult.Errors.Select(e => e.Description).ToList());
            }

            var roleResult = await _userManager.AddToRoleAsync(user, SupervisorRole);

            if (!roleResult.Succeeded)
            {
                // Never leave a half-created account behind
                await _userManager.DeleteAsync(user);
                return BadRequest(roleResult.Errors.Select(e => e.Description).ToList());
            }

            var emailSent = true;

            try
            {
                var token = await _userManager.GeneratePasswordResetTokenAsync(user);

                var resetUrl =
                    $"{_config["Email:ResetPasswordUrl"]}" +
                    $"?email={Uri.EscapeDataString(user.Email!)}" +
                    $"&token={Uri.EscapeDataString(token)}";

                await _emailService.SendEmailAsync(
                    user.Email!,
                    "Your Municipal Reporting supervisor account",
                    $"""
                    <h2>Welcome to Municipal Reporting</h2>

                    <p>Hi {user.FullName},</p>

                    <p>A supervisor account has been created for you.</p>

                    <p>Click the link below to choose your password:</p>

                    <p><a href="{resetUrl}">Set my password</a></p>

                    <p>If the link has expired, use "Forgot password" on the login screen.</p>
                    """);
            }
            catch (Exception ex)
            {
                emailSent = false;
                _logger.LogError(ex, "Could not send the welcome email to new supervisor {UserId}", user.Id);
            }

            var created = await ProjectUsers(_userManager.Users.Where(u => u.Id == user.Id)).FirstAsync();

            return CreatedAtAction(nameof(GetUser), new { id = user.Id }, new
            {
                user = created,
                emailSent,
                message = emailSent
                    ? "Supervisor created. A link to set their password was emailed to them."
                    : "Supervisor created, but the email could not be sent. Ask them to use 'Forgot password'."
            });
        }

        // Meets the Identity password rules (digit, lower, upper, length). Nobody ever sees it.
        private static string GenerateTemporaryPassword()
        {
            return "Aa1-" + Convert.ToBase64String(RandomNumberGenerator.GetBytes(24));
        }

        
        // 3. Moderate reports
        // Remove a problematic or invalid report, whoever submitted it and whatever the status.
        // The Issue is the municipal record, so it is only removed when it is still Reported
        // and this was its last report (same rule as residents deleting their own reports).
        [HttpDelete("reports/{id}")]
        public async Task<IActionResult> DeleteReport(int id)
        {
            var report = await _context.Reports
                .Include(r => r.Issue)
                .FirstOrDefaultAsync(r => r.Id == id);

            if (report == null)
            {
                return NotFound();
            }

            var issue = report.Issue!;
            var imageUrl = report.ImageUrl;
            var issueId = report.IssueId;
            var issueRemoved = false;

            _context.Reports.Remove(report);

            if (issue.Status == ReportStatus.Reported)
            {
                var otherReportsExist = await _context.Reports
                    .AnyAsync(r => r.IssueId == issueId && r.Id != report.Id);

                if (!otherReportsExist)
                {
                    _context.Issues.Remove(issue);
                    issueRemoved = true;
                }
            }

            await _context.SaveChangesAsync();

            // Only after the save worked
            if (!string.IsNullOrEmpty(imageUrl))
            {
                var webRootPath = _env.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
                var imagePath = Path.Combine(webRootPath, imageUrl.TrimStart('/'));

                if (System.IO.File.Exists(imagePath))
                {
                    System.IO.File.Delete(imagePath);
                }
            }

            var remainingReports = issueRemoved
                ? 0
                : await _context.Reports.CountAsync(r => r.IssueId == issueId);

            return Ok(new
            {
                message = "Report removed successfully",
                issueId,
                issueRemoved,
                remainingReports
            });
        }

        // 4. Statistics
        // Issues = actual municipal problems.
        // Reports = resident submissions/confirmations.
        [HttpGet("stats")]
        public async Task<IActionResult> GetStats()
        {
            var byStatus = await _context.Issues
                .GroupBy(i => i.Status)
                .Select(g => new { Status = g.Key, Count = g.Count() })
                .ToListAsync();

            int StatusCount(ReportStatus s) => byStatus.FirstOrDefault(x => x.Status == s)?.Count ?? 0;

            var issuesByCategory = await _context.Issues
                .GroupBy(i => i.IssueCategory)
                .Select(g => new { Category = g.Key, Count = g.Count() })
                .ToListAsync();

            var reportsByCategory = await _context.Reports
                .GroupBy(r => r.Issue!.IssueCategory)
                .Select(g => new { Category = g.Key, Count = g.Count() })
                .ToListAsync();

            var roleCounts = await (
                from ur in _context.UserRoles
                join r in _context.Roles on ur.RoleId equals r.Id
                group ur by r.Name into g
                select new { Role = g.Key, Count = g.Count() })
                .ToListAsync();

            int RoleCount(string role) => roleCounts.FirstOrDefault(x => x.Role == role)?.Count ?? 0;

            var stats = new AdminStatsDTO
            {
                TotalIssues = byStatus.Sum(x => x.Count),
                Reported = StatusCount(ReportStatus.Reported),
                InProgress = StatusCount(ReportStatus.InProgress),
                Resolved = StatusCount(ReportStatus.Resolved),
                TotalReports = await _context.Reports.CountAsync(),
                UnassignedActiveIssues = await _context.Issues
                    .CountAsync(i => i.SupervisorId == null && i.Status != ReportStatus.Resolved),
                IssuesWithMultipleReports = await _context.Issues
                    .CountAsync(i => i.Reports.Count() > 1),
                TotalUsers = await _userManager.Users.CountAsync(),
                Users = RoleCount(UserRole),
                Supervisors = RoleCount(SupervisorRole),
                Admins = RoleCount(AdminRole)
            };

            stats.ActiveIssues = stats.Reported + stats.InProgress;

            // Every category is listed, including those with no issues yet
            stats.IssuesByCategory = Enum.GetValues<IssueCategory>()
                .Select(c => new CategoryStatDTO
                {
                    Category = c.ToString(),
                    Issues = issuesByCategory.FirstOrDefault(x => x.Category == c)?.Count ?? 0,
                    Reports = reportsByCategory.FirstOrDefault(x => x.Category == c)?.Count ?? 0
                })
                .ToList();

            return Ok(stats);
        }
    }
}
