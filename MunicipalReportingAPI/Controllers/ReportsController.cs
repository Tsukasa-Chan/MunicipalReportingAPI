using Microsoft.AspNetCore.Mvc;
using MunicipalReportingAPI.Data;
using MunicipalReportingAPI.DTO;
using MunicipalReportingAPI.Models;
using MunicipalReportingAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace MunicipalReportingAPI.Controllers
{
    [Route("api/[Controller]")]
    [ApiController]
    public class ReportsController : ControllerBase
    {
        private readonly MunicipalDBContext _context;
        private readonly IWebHostEnvironment _env;
        private readonly IIssueService _issueService;

        public ReportsController(MunicipalDBContext context, IWebHostEnvironment env, IIssueService issueService)
        {
            _context = context;
            _env = env;
            _issueService = issueService;
        }

        private int GetCurrentUserId()
        {
            var idClaim = User.FindFirst(ClaimTypes.NameIdentifier)!.Value;
            return int.Parse(idClaim);
        }

        // Number of reports per issue, calculated from the Reports table
        private async Task<Dictionary<int, int>> GetReportCountsAsync(IEnumerable<int> issueIds)
        {
            var ids = issueIds.Distinct().ToList();

            return await _context.Reports
                .Where(r => ids.Contains(r.IssueId))
                .GroupBy(r => r.IssueId)
                .Select(g => new { IssueId = g.Key, Count = g.Count() })
                .ToDictionaryAsync(x => x.IssueId, x => x.Count);
        }

        // Reports with everything ReportResponseDTO needs: user, issue, and both Area -> Ward chains
        private IQueryable<Report> ReportsWithDetails() =>
            _context.Reports
                .Include(r => r.User)
                .Include(r => r.Area).ThenInclude(a => a!.Ward)
                .Include(r => r.Issue).ThenInclude(i => i!.Area).ThenInclude(a => a!.Ward);

        private async Task<List<ReportResponseDTO>> ToDtosAsync(List<Report> reports)
        {
            var counts = await GetReportCountsAsync(reports.Select(r => r.IssueId));
            return reports
                .Select(r => ReportResponseDTO.FromReport(r, counts.GetValueOrDefault(r.IssueId)))
                .ToList();
        }

        // Internal/admin list of individual submissions. The public app should use /api/issues.
        [Authorize(Roles = "Admin,Supervisor")]
        [HttpGet]
        public async Task<IActionResult> GetAll(
            [FromQuery] ReportStatus? status,
            [FromQuery] IssueCategory? category,
            [FromQuery] IssueType? issueType)
        {
            var query = ReportsWithDetails();

            if (status.HasValue)
            {
                query = query.Where(r => r.Issue!.Status == status.Value);
            }

            if (category.HasValue)
            {
                query = query.Where(r => r.IssueCategory == category.Value);
            }

            if (issueType.HasValue)
            {
                query = query.Where(r => r.IssueType == issueType.Value);
            }

            var reports = await query.OrderByDescending(r => r.CreatedAt).ToListAsync();

            return Ok(await ToDtosAsync(reports));
        }

        // A report shows the resident's name, photo and exact location, so it is only
        // visible to the resident who submitted it and to staff.
        // (The public view of a problem is GET /api/issues/{id}.)
        [Authorize]
        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var report = await ReportsWithDetails()
                .FirstOrDefaultAsync(r => r.Id == id);

            if (report == null)
            {
                return NotFound();
            }

            var isStaff = User.IsInRole("Admin") || User.IsInRole("Supervisor");

            if (!isStaff && report.UserId != GetCurrentUserId())
            {
                return Forbid();
            }

            return Ok((await ToDtosAsync(new List<Report> { report })).First());
        }


        [Authorize]
        [HttpGet("mine")]
        public async Task<IActionResult> GetMyReports()
        {
            var userId = GetCurrentUserId();

            var reports = await ReportsWithDetails()
                .Where(r => r.UserId == userId)
                .OrderByDescending(r => r.CreatedAt)
                .ToListAsync();

            return Ok(await ToDtosAsync(reports));
        }

        [Authorize]
        [HttpPut("{id}/feedback")]
        public async Task<IActionResult> SubmitResolutionFeedback(
            int id,
            [FromBody] SubmitResolutionFeedbackDTO dto)
        {
            var report = await ReportsWithDetails()
                .FirstOrDefaultAsync(r => r.Id == id);

            if (report == null)
            {
                return NotFound();
            }

            if (report.UserId != GetCurrentUserId())
            {
                return Forbid();
            }

            if (report.Issue?.Status != ReportStatus.Resolved)
            {
                return Conflict("Feedback can only be submitted after the issue is resolved.");
            }

            report.FeedbackRating = dto.Rating;
            report.FeedbackComment = string.IsNullOrWhiteSpace(dto.Comment)
                ? null
                : dto.Comment.Trim();
            report.FeedbackUpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return Ok(new
            {
                rating = report.FeedbackRating,
                comment = report.FeedbackComment,
                updatedAt = report.FeedbackUpdatedAt
            });
        }

        // endpoint looks at logged-in user, checks if they are a supervisor
        // retuns reports linked to the Issue assigned to them
        [Authorize(Roles = "Supervisor")]
        [HttpGet("/api/supervisors/{supervisorUsername}/reports")]
        public async Task<IActionResult> GetAssignedReports(String supervisorUsername)
        {
            var userId = GetCurrentUserId();

            // Finds reports where issue is assigned to the supervisor
            var reports = await ReportsWithDetails()
                .Where(r => r.Issue != null && r.Issue.SupervisorId == userId)
                .OrderByDescending(r => r.CreatedAt)
                .ToListAsync();
            // formatting response to json for Flutter
            var response = reports.Select(r => new
            {
                id = r.Id,
                issueId = r.IssueId,
                senderName = r.User != null ? r.User.FullName : "Unknown Sender", 
                senderUsername = r.User != null ? r.User.UserName : "No username",
                issueType = r.IssueType.ToString(),
                issue = r.Description ?? "No description", 
                area = r.Area != null ? r.Area.Name : "Unknown Area",
                createdAt = r.CreatedAt,
                status = r.Issue != null ? r.Issue.Status.ToString() : "Pending",
                assignedSupervisorUsername = supervisorUsername,
                scheduledAt = r.Issue != null ? r.Issue.ScheduledAt : (DateTime?)null
                // "I added public DateTime? ScheduledAt { get; set; } to the Issue.cs model
                // to show the supervisor
                // run a new EF core migration to update the database."
            }).ToList();

            return Ok(response);
        }


        [Authorize]
        [HttpPost]
        public async Task<IActionResult> CreateReport([FromForm] CreateReportDTO dto)
        {
            var userId = GetCurrentUserId();

            // 1. Validate the image before doing anything else
            string? extension = null;

            if (dto.Image != null)
            {
                var allowedExtensions = new[] { ".jpg", ".jpeg", ".png" };
                extension = Path.GetExtension(dto.Image.FileName).ToLower();

                if (!allowedExtensions.Contains(extension))
                {
                    return BadRequest("Only JPG and PNG images are allowed");
                }

                if (dto.Image.Length > 5 * 1024 * 1024)
                {
                    return BadRequest("Image must be smaller than 5MB");
                }
            }

            // The Area must exist (the Ward comes from it)
            if (!await _context.Areas.AnyAsync(a => a.Id == dto.AreaId))
            {
                return BadRequest("The selected area does not exist");
            }

            // 2. Is this an existing, unresolved issue? The strategy depends on the IssueType:
            //    GPS  - same category + type, within that type's radius (AreaId ignored)
            //    Area - same category + type + same AreaId (coordinates ignored)
            var issue = await _issueService.FindMatchingIssueAsync(
                dto.IssueCategory, dto.IssueType, dto.AreaId, dto.Latitude, dto.Longitude);

            // 3. Has this user already reported that issue?
            if (issue != null)
            {
                var alreadyReported = await _context.Reports
                    .AnyAsync(r => r.IssueId == issue.Id && r.UserId == userId);

                if (alreadyReported)
                {
                    return Conflict(new
                    {
                        message = "You have already reported this issue.",
                        issueId = issue.Id
                    });
                }
            }

            // 4. Save the image (only now, so a rejected report leaves no orphaned file)
            string? imageUrl = null;
            string? savedFilePath = null;

            if (dto.Image != null)
            {
                var webRootPath = _env.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
                var uploadsFolder = Path.Combine(webRootPath, "uploads");
                Directory.CreateDirectory(uploadsFolder);

                var fileName = Guid.NewGuid() + extension;
                savedFilePath = Path.Combine(uploadsFolder, fileName);

                using (var stream = new FileStream(savedFilePath, FileMode.Create))
                {
                    await dto.Image.CopyToAsync(stream);
                }

                imageUrl = $"/uploads/{fileName}";
            }

            var now = DateTime.UtcNow;
            var joinedExisting = issue != null;

            // 5. No match: create a new Issue (saved together with the report)
            if (issue == null)
            {
                issue = new Issue
                {
                    IssueCategory = dto.IssueCategory,
                    IssueType = dto.IssueType,
                    AreaId = dto.AreaId,
                    Location = dto.Location,
                    Latitude = dto.Latitude,
                    Longitude = dto.Longitude,
                    Status = ReportStatus.Reported,
                    CreatedAt = now
                };
                _context.Issues.Add(issue);
            }

            var report = new Report
            {
                Issue = issue,
                IssueCategory = dto.IssueCategory,
                IssueType = dto.IssueType,
                AreaId = dto.AreaId,
                Location = dto.Location,
                Latitude = dto.Latitude,
                Longitude = dto.Longitude,
                Description = dto.Description,
                ImageUrl = imageUrl,
                CreatedAt = now,
                UserId = userId
            };

            _context.Reports.Add(report);

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateException)
            {
                // Most likely two identical requests from the same user at the same moment
                // (unique index on IssueId + UserId). Remove the uploaded file again.
                if (savedFilePath != null && System.IO.File.Exists(savedFilePath))
                {
                    System.IO.File.Delete(savedFilePath);
                }

                return Conflict(new { message = "You have already reported this issue." });
            }

            // Load user + both Area -> Ward chains for the response
            report = await ReportsWithDetails().FirstAsync(r => r.Id == report.Id);

            var reportCount = await _context.Reports.CountAsync(r => r.IssueId == report.IssueId);

            var response = ReportResponseDTO.FromReport(report, reportCount);
            response.JoinedExistingIssue = joinedExisting;

            return Ok(response);
        }

        // A resident can edit their report only while its Issue is still Reported.
        // The Issue is then re-evaluated with the same matching rules as report creation.
        [Authorize]
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateReport(int id, [FromForm] UpdateReportDTO dto)
        {
            var report = await ReportsWithDetails()
                .FirstOrDefaultAsync(r => r.Id == id);

            if (report == null)
            {
                return NotFound();
            }

            if (report.UserId != GetCurrentUserId())
            {
                return Forbid();
            }

            var oldIssue = report.Issue!;

            // Locked once municipal work has started (In Progress, Resolved)
            if (oldIssue.Status != ReportStatus.Reported)
            {
                return Conflict(new
                {
                    message = "This report can no longer be edited because work on the issue has started.",
                    issueId = oldIssue.Id,
                    status = oldIssue.Status
                });
            }

            // 1. Validate the image first
            string? extension = null;

            if (dto.Image != null)
            {
                var allowedExtensions = new[] { ".jpg", ".jpeg", ".png" };
                extension = Path.GetExtension(dto.Image.FileName).ToLower();

                if (!allowedExtensions.Contains(extension))
                {
                    return BadRequest("Only JPG and PNG images are allowed");
                }

                if (dto.Image.Length > 5 * 1024 * 1024)
                {
                    return BadRequest("Image must be smaller than 5MB");
                }
            }

            // The Area must exist (the Ward comes from it)
            if (!await _context.Areas.AnyAsync(a => a.Id == dto.AreaId))
            {
                return BadRequest("The selected area does not exist");
            }

            var now = DateTime.UtcNow;

            // 2. Re-evaluate the Issue only if something that affects matching changed
            var matchingChanged =
                report.IssueCategory != dto.IssueCategory ||
                report.IssueType != dto.IssueType ||
                report.AreaId != dto.AreaId ||
                report.Latitude != dto.Latitude ||
                report.Longitude != dto.Longitude;

            Issue? targetIssue = null;   // existing Issue to move to
            Issue? newIssue = null;      // new Issue to create and move to

            if (matchingChanged)
            {
                var stillMatchesCurrent = _issueService.IsMatch(
                    oldIssue, dto.IssueCategory, dto.IssueType, dto.AreaId, dto.Latitude, dto.Longitude);

                if (!stillMatchesCurrent)
                {
                    var match = await _issueService.FindMatchingIssueAsync(
                        dto.IssueCategory, dto.IssueType, dto.AreaId, dto.Latitude, dto.Longitude);

                    if (match != null)
                    {
                        var alreadyReported = await _context.Reports
                            .AnyAsync(r => r.IssueId == match.Id && r.UserId == report.UserId);

                        if (alreadyReported)
                        {
                            return Conflict(new
                            {
                                message = "You have already reported this issue.",
                                issueId = match.Id
                            });
                        }

                        targetIssue = match;
                    }
                    else
                    {
                        newIssue = new Issue
                        {
                            IssueCategory = dto.IssueCategory,
                            IssueType = dto.IssueType,
                            AreaId = dto.AreaId,
                            Location = dto.Location,
                            Latitude = dto.Latitude,
                            Longitude = dto.Longitude,
                            Status = ReportStatus.Reported,
                            CreatedAt = now
                        };
                    }
                }
            }

            // 3. Save the new image only now that nothing can reject the update
            string? newFilePath = null;
            string? oldImageUrl = null;
            var webRootPath = _env.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");

            if (dto.Image != null)
            {
                var uploadsFolder = Path.Combine(webRootPath, "uploads");
                Directory.CreateDirectory(uploadsFolder);

                var fileName = Guid.NewGuid() + extension;
                newFilePath = Path.Combine(uploadsFolder, fileName);

                using (var stream = new FileStream(newFilePath, FileMode.Create))
                {
                    await dto.Image.CopyToAsync(stream);
                }

                oldImageUrl = report.ImageUrl;
                report.ImageUrl = $"/uploads/{fileName}";
            }

            // 4. Apply the changes to the report. The existing Issue's own details are left alone.
            report.IssueCategory = dto.IssueCategory;
            report.IssueType = dto.IssueType;
            report.AreaId = dto.AreaId;
            report.Location = dto.Location;
            report.Latitude = dto.Latitude;
            report.Longitude = dto.Longitude;
            report.Description = dto.Description;
            report.UpdatedAt = now;

            var moved = false;

            if (newIssue != null)
            {
                _context.Issues.Add(newIssue);
                report.Issue = newIssue;
                moved = true;
            }
            else if (targetIssue != null)
            {
                report.Issue = targetIssue;
                moved = true;
            }

            // An Issue left with no reports is removed
            if (moved)
            {
                var oldIssueStillUsed = await _context.Reports
                    .AnyAsync(r => r.IssueId == oldIssue.Id && r.Id != report.Id);

                if (!oldIssueStillUsed)
                {
                    _context.Issues.Remove(oldIssue);
                }
            }

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateException)
            {
                if (newFilePath != null && System.IO.File.Exists(newFilePath))
                {
                    System.IO.File.Delete(newFilePath);
                }

                return Conflict(new { message = "You have already reported this issue." });
            }

            // 5. Remove the replaced image only after the save worked
            if (!string.IsNullOrEmpty(oldImageUrl))
            {
                var oldImagePath = Path.Combine(webRootPath, oldImageUrl.TrimStart('/'));

                if (System.IO.File.Exists(oldImagePath))
                {
                    System.IO.File.Delete(oldImagePath);
                }
            }

            // Reload so Area/Ward (report and issue) reflect what was just saved
            report = await ReportsWithDetails().FirstAsync(r => r.Id == report.Id);

            var reportCount = await _context.Reports.CountAsync(r => r.IssueId == report.IssueId);

            var response = ReportResponseDTO.FromReport(report, reportCount);
            response.MovedToAnotherIssue = moved;

            return Ok(response);
        }

        [Authorize]
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteReport(int id)
        {
            var report = await _context.Reports
                .Include(r => r.Issue)
                .FirstOrDefaultAsync(r => r.Id == id);

            if (report == null)
            {
                return NotFound();
            }

            if (report.UserId != GetCurrentUserId())
            {
                return Forbid();
            }

            var issue = report.Issue!;

            // Not while the municipality is working on it. Allowed when Reported or Resolved.
            if (issue.Status == ReportStatus.InProgress)
            {
                return Conflict(new
                {
                    message = "This report cannot be deleted while work on the issue is in progress.",
                    issueId = report.IssueId,
                    status = issue.Status
                });
            }

            var imageUrl = report.ImageUrl;
            var issueId = report.IssueId;

            _context.Reports.Remove(report);

            // An Issue is the municipal record: it is never deleted just because its reports are.
            // The only exception is an Issue still in Reported that has no reports left, because
            // nothing has started and no resident is backing it any more.
            // A Resolved Issue is kept even with 0 reports.
            if (issue.Status == ReportStatus.Reported)
            {
                var otherReportsExist = await _context.Reports
                    .AnyAsync(r => r.IssueId == issueId && r.Id != report.Id);

                if (!otherReportsExist)
                {
                    _context.Issues.Remove(issue);
                }
            }

            await _context.SaveChangesAsync();

            // Only after the save worked, so a failed delete never leaves a broken image link
            if (!string.IsNullOrEmpty(imageUrl))
            {
                var webRootPath = _env.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
                var imagePath = Path.Combine(webRootPath, imageUrl.TrimStart('/'));

                if (System.IO.File.Exists(imagePath))
                {
                    System.IO.File.Delete(imagePath);
                }
            }

            return Ok("Report deleted successfully");
        }
    }
}
