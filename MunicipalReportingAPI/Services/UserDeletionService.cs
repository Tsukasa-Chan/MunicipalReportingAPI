using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using MunicipalReportingAPI.Data;
using MunicipalReportingAPI.Models;

namespace MunicipalReportingAPI.Services
{
    public class UserDeletionService : IUserDeletionService
    {
        private readonly MunicipalDBContext _context;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IWebHostEnvironment _env;

        public UserDeletionService(
            MunicipalDBContext context,
            UserManager<ApplicationUser> userManager,
            IWebHostEnvironment env)
        {
            _context = context;
            _userManager = userManager;
            _env = env;
        }

        public async Task<IdentityResult> DeleteUserAsync(ApplicationUser user)
        {
            var reports = await _context.Reports
                .Where(r => r.UserId == user.Id)
                .Include(r => r.Issue)
                .ToListAsync();

            // Reports on Issues that are In Progress or Resolved belong to the municipal record,
            // so they are kept (and detached from the user). Reports on Issues that are still
            // Reported are deleted.
            var reportsToDelete = reports.Where(r => r.Issue!.Status == ReportStatus.Reported).ToList();
            var reportsToKeep = reports.Where(r => r.Issue!.Status != ReportStatus.Reported).ToList();

            foreach (var report in reportsToKeep)
            {
                report.UserId = null;
            }

            foreach (var report in reportsToDelete)
            {
                DeleteWebRootFile(report.ImageUrl);
            }

            _context.Reports.RemoveRange(reportsToDelete);

            // A Reported Issue left with no reports at all is removed (nothing has started).
            // In Progress and Resolved Issues are never removed here.
            var deletedIds = reportsToDelete.Select(r => r.Id).ToList();
            var emptiedIssues = await _context.Issues
                .Where(i => i.Status == ReportStatus.Reported &&
                            i.Reports.Any(r => deletedIds.Contains(r.Id)) &&
                            !i.Reports.Any(r => !deletedIds.Contains(r.Id)))
                .ToListAsync();
            _context.Issues.RemoveRange(emptiedIssues);

            // If this user was a supervisor, their issues become unassigned (kept, not deleted)
            var assignedIssues = await _context.Issues
                .Where(i => i.SupervisorId == user.Id)
                .ToListAsync();

            foreach (var issue in assignedIssues)
            {
                issue.SupervisorId = null;
                issue.UpdatedAt = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();

            DeleteWebRootFile(user.ProfilePictureUrl);

            return await _userManager.DeleteAsync(user);
        }

        private void DeleteWebRootFile(string? relativeUrl)
        {
            if (string.IsNullOrEmpty(relativeUrl))
            {
                return;
            }

            var webRootPath = _env.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
            var path = Path.Combine(webRootPath, relativeUrl.TrimStart('/'));

            if (System.IO.File.Exists(path))
            {
                System.IO.File.Delete(path);
            }
        }
    }
}
