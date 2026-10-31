
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using MunicipalReportingAPI.Data;
using MunicipalReportingAPI.DTO;
using MunicipalReportingAPI.Models;
using MunicipalReportingAPI.Services;

namespace MunicipalReportingAPI.Controllers
{
    [Route("api/[Controller]")]
    [ApiController]
    public class IssuesController : ControllerBase
    {
        private readonly MunicipalDBContext _context;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IIssueService _issueService;

        public IssuesController(
            MunicipalDBContext context,
            UserManager<ApplicationUser> userManager,
            IIssueService issueService)
        {
            _context = context;
            _userManager = userManager;
            _issueService = issueService;
        }

        // Shared projection: Issue + report count + original (first) report.
        // The count is calculated from the Reports, never stored.
        private IQueryable<IssueResponseDTO> ProjectIssues(IQueryable<Issue> query) =>
            query.Select(i => new IssueResponseDTO
            {
                Id = i.Id,
                IssueCategory = i.IssueCategory,
                IssueType = i.IssueType,

                AreaId = i.AreaId,
                AreaName = i.Area!.Name,

                WardId = i.Area!.WardId,
                WardName = i.Area!.Ward!.Name,

                Location = i.Location,
                Latitude = i.Latitude,
                Longitude = i.Longitude,

                Status = i.Status,

                SupervisorId = i.SupervisorId,
                SupervisorName = i.Supervisor != null
                    ? i.Supervisor.FullName
                    : null,

                CreatedAt = i.CreatedAt,
                UpdatedAt = i.UpdatedAt,
                ScheduledAt = i.ScheduledAt,

                ReportCount = i.Reports.Count(),

                OriginalDescription = i.Reports
                    .OrderBy(r => r.CreatedAt)
                    .ThenBy(r => r.Id)
                    .Select(r => r.Description)
                    .FirstOrDefault(),

                OriginalImageUrl = i.Reports
                    .OrderBy(r => r.CreatedAt)
                    .ThenBy(r => r.Id)
                    .Select(r => r.ImageUrl)
                    .FirstOrDefault()
            });

        // Public list / map data: one entry per municipal problem.
        [HttpGet]
        public async Task<IActionResult> GetAll(
            [FromQuery] ReportStatus? status,
            [FromQuery] IssueCategory? category,
            [FromQuery] IssueType? issueType,
            [FromQuery] int? supervisorId,
            [FromQuery] int? wardId,
            [FromQuery] int? areaId,
            [FromQuery] bool? unassigned,
            [FromQuery] int? minReports,
            [FromQuery] string? sortBy)
        {
            var query = _context.Issues.AsQueryable();

            if (status.HasValue)
                query = query.Where(i => i.Status == status.Value);

            if (category.HasValue)
                query = query.Where(i => i.IssueCategory == category.Value);

            if (issueType.HasValue)
                query = query.Where(i => i.IssueType == issueType.Value);

            if (supervisorId.HasValue)
                query = query.Where(i => i.SupervisorId == supervisorId.Value);

            if (wardId.HasValue)
                query = query.Where(i => i.Area!.WardId == wardId.Value);

            if (areaId.HasValue)
                query = query.Where(i => i.AreaId == areaId.Value);

            // ?unassigned=true -> issues nobody is responsible for yet.
            if (unassigned == true)
                query = query.Where(i => i.SupervisorId == null);

            // ?minReports=2 -> issues confirmed by several residents.
            if (minReports.HasValue)
                query = query.Where(i => i.Reports.Count() >= minReports.Value);

            // ?sortBy=reports -> most-reported first (default: newest first).
            var ordered = string.Equals(
                sortBy,
                "reports",
                StringComparison.OrdinalIgnoreCase)
                ? query.OrderByDescending(i => i.Reports.Count())
                    .ThenByDescending(i => i.CreatedAt)
                : query.OrderByDescending(i => i.CreatedAt);

            var issues = await ProjectIssues(ordered).ToListAsync();

            return Ok(issues);
        }

        // Open issues near a point (nearest first).
        // Radius defaults to the configured match radius.
        // Registered before {id} so "nearby" is never treated as an id.
        [HttpGet("nearby")]
        public async Task<IActionResult> GetNearby(
            [FromQuery] double latitude,
            [FromQuery] double longitude,
            [FromQuery] double? radiusMeters,
            [FromQuery] IssueType? issueType)
        {
            var radius = radiusMeters ?? _issueService.MatchRadiusMeters;

            if (radius <= 0 || radius > 50000)
            {
                return BadRequest(
                    "radiusMeters must be between 0 and 50000");
            }

            var nearby = await _issueService.FindNearbyAsync(
                latitude,
                longitude,
                radius,
                issueType);

            var ids = nearby.Select(n => n.Issue.Id).ToList();

            var dtos = await ProjectIssues(
                _context.Issues.Where(i => ids.Contains(i.Id)))
                .ToListAsync();

            foreach (var dto in dtos)
            {
                dto.DistanceMeters = Math.Round(
                    nearby.First(n => n.Issue.Id == dto.Id).DistanceMeters,
                    1);
            }

            return Ok(dtos.OrderBy(d => d.DistanceMeters));
        }

        // Issues vs reports: "35 issues, 142 reports".
        // Optional filters: ?wardId=58 or ?areaId=3 (or both).
        // No filter = whole system.
        // Counts are of ISSUES, not individual resident reports.
        [HttpGet("stats")]
        public async Task<IActionResult> GetStats(
            [FromQuery] int? wardId,
            [FromQuery] int? areaId)
        {
            if (wardId.HasValue &&
                !await _context.Wards.AnyAsync(w => w.Id == wardId.Value))
            {
                return NotFound("Ward not found");
            }

            if (areaId.HasValue &&
                !await _context.Areas.AnyAsync(a => a.Id == areaId.Value))
            {
                return NotFound("Area not found");
            }

            var issues = _context.Issues.AsQueryable();

            if (wardId.HasValue)
                issues = issues.Where(i => i.Area!.WardId == wardId.Value);

            if (areaId.HasValue)
                issues = issues.Where(i => i.AreaId == areaId.Value);

            var grouped = await issues
                .GroupBy(i => new { i.IssueCategory, i.Status })
                .Select(g => new
                {
                    g.Key.IssueCategory,
                    g.Key.Status,
                    Count = g.Count(),
                    Reports = g.Sum(i => i.Reports.Count())
                })
                .ToListAsync();

            int Count(ReportStatus s) =>
                grouped.Where(x => x.Status == s).Sum(x => x.Count);

            var stats = new IssueStatsDTO
            {
                TotalIssues = grouped.Sum(x => x.Count),
                Reported = Count(ReportStatus.Reported),
                InProgress = Count(ReportStatus.InProgress),
                Resolved = Count(ReportStatus.Resolved),
                TotalReports = grouped.Sum(x => x.Reports)
            };

            stats.ActiveIssues = stats.Reported + stats.InProgress;
            stats.ResolvedIssues = stats.Resolved;

            stats.ByCategory = Enum.GetValues<IssueCategory>()
                .Select(c =>
                {
                    var rows = grouped
                        .Where(x => x.IssueCategory == c)
                        .ToList();

                    int Of(ReportStatus s) =>
                        rows.Where(x => x.Status == s).Sum(x => x.Count);

                    return new CategoryStatsDTO
                    {
                        Category = c,
                        Total = rows.Sum(x => x.Count),
                        Reported = Of(ReportStatus.Reported),
                        InProgress = Of(ReportStatus.InProgress),
                        Resolved = Of(ReportStatus.Resolved),
                        Active = Of(ReportStatus.Reported) +
                                 Of(ReportStatus.InProgress),
                        TotalReports = rows.Sum(x => x.Reports)
                    };
                })
                .ToList();

            return Ok(stats);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var issue = await ProjectIssues(
                _context.Issues.Where(i => i.Id == id))
                .FirstOrDefaultAsync();

            if (issue == null)
            {
                return NotFound();
            }

            return Ok(issue);
        }

        // Supporting reports. Includes resident names, so staff only.
        [Authorize(Roles = "Admin,Supervisor")]
        [HttpGet("{id}/reports")]
        public async Task<IActionResult> GetReports(int id)
        {
            if (!await _context.Issues.AnyAsync(i => i.Id == id))
            {
                return NotFound();
            }

            var reports = await _context.Reports
                .Where(r => r.IssueId == id)
                .Include(r => r.User)
                .OrderBy(r => r.CreatedAt)
                .ThenBy(r => r.Id)
                .ToListAsync();

            return Ok(reports.Select(IssueReportDTO.FromReport));
        }

        [Authorize(Roles = "Admin,Supervisor")]
        [HttpPut("{id}/status")]
        public async Task<IActionResult> UpdateStatus(
            int id,
            [FromBody] UpdateStatusDTO dto)
        {
            var issue = await _context.Issues.FindAsync(id);

            if (issue == null)
            {
                return NotFound();
            }

            // Admins can change any issue.
            // Supervisors can only change issues assigned to them.
            if (!User.IsInRole("Admin"))
            {
                var currentUserId = int.Parse(
                    User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

                if (issue.SupervisorId != currentUserId)
                {
                    return Forbid();
                }
            }

            issue.Status = dto.Status;
            issue.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            var result = await ProjectIssues(
                _context.Issues.Where(i => i.Id == id))
                .FirstAsync();

            return Ok(result);
        }

        // Assign or remove a supervisor from an issue.
        [Authorize(Roles = "Admin")]
        [HttpPut("{id}/supervisor")]
        public async Task<IActionResult> AssignSupervisor(
            int id,
            [FromBody] AssignSupervisorDTO dto)
        {
            var issue = await _context.Issues.FindAsync(id);

            if (issue == null)
            {
                return NotFound();
            }

            // Check that the selected user has the Supervisor role.
            if (dto.SupervisorId.HasValue)
            {
                var supervisor = await _userManager.FindByIdAsync(
                    dto.SupervisorId.Value.ToString());

                if (supervisor == null ||
                    !await _userManager.IsInRoleAsync(
                        supervisor,
                        "Supervisor"))
                {
                    return BadRequest(
                        "The selected user is not a supervisor");
                }
            }

            // Record when the issue is assigned.
            var now = DateTime.UtcNow;

            issue.SupervisorId = dto.SupervisorId;
            issue.ScheduledAt = dto.SupervisorId.HasValue
                ? now
                : null;

            issue.UpdatedAt = now;

            await _context.SaveChangesAsync();

            var result = await ProjectIssues(
                _context.Issues.Where(i => i.Id == id))
                .FirstAsync();

            return Ok(result);
        }
    }
}
