using MunicipalReportingAPI.Models;

namespace MunicipalReportingAPI.DTO
{
    public class ReportResponseDTO
    {
        public int Id { get; set; }
        public int IssueId { get; set; }

        // Status, supervisor and the shared issue location/count come from the Issue
        public IssueCategory IssueCategory { get; set; }
        public IssueType IssueType { get; set; }
        public ReportStatus Status { get; set; }
        public int IssueAreaId { get; set; }
        public string IssueAreaName { get; set; } = string.Empty;
        public int IssueWardId { get; set; }
        public string IssueWardName { get; set; } = string.Empty;
        public string IssueLocation { get; set; } = string.Empty;
        public double IssueLatitude { get; set; }
        public double IssueLongitude { get; set; }
        public int ReportCount { get; set; }
        public int? SupervisorId { get; set; }

        // This resident's own submission
        public string? ImageUrl { get; set; }
        public int AreaId { get; set; }
        public string AreaName { get; set; } = string.Empty;
        public int WardId { get; set; }
        public string WardName { get; set; } = string.Empty;
        public string Location { get; set; } = string.Empty;
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        public string? Description { get; set; }
        public int? FeedbackRating { get; set; }
        public string? FeedbackComment { get; set; }
        public DateTime? FeedbackUpdatedAt { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }

        // Null/empty user fields mean the resident deleted their account
        public int? UserId { get; set; }
        public string? UserFullName { get; set; }
        public string? UserProfilePictureUrl { get; set; }

        // Only set when a report is created
        public bool? JoinedExistingIssue { get; set; }

        // Only set when a report is updated: true if the edit moved it to a different Issue
        public bool? MovedToAnotherIssue { get; set; }

        // r.Issue, r.Area.Ward and r.Issue.Area.Ward must be loaded
        public static ReportResponseDTO FromReport(Report r, int reportCount) => new ReportResponseDTO
        {
            Id = r.Id,
            IssueId = r.IssueId,
            IssueCategory = r.IssueCategory,
            IssueType = r.IssueType,
            Status = r.Issue!.Status,
            IssueAreaId = r.Issue.AreaId,
            IssueAreaName = r.Issue.Area?.Name ?? string.Empty,
            IssueWardId = r.Issue.Area?.WardId ?? 0,
            IssueWardName = r.Issue.Area?.Ward?.Name ?? string.Empty,
            IssueLocation = r.Issue.Location,
            IssueLatitude = r.Issue.Latitude,
            IssueLongitude = r.Issue.Longitude,
            ReportCount = reportCount,
            SupervisorId = r.Issue.SupervisorId,
            ImageUrl = r.ImageUrl,
            AreaId = r.AreaId,
            AreaName = r.Area?.Name ?? string.Empty,
            WardId = r.Area?.WardId ?? 0,
            WardName = r.Area?.Ward?.Name ?? string.Empty,
            Location = r.Location,
            Latitude = r.Latitude,
            Longitude = r.Longitude,
            Description = r.Description,
            FeedbackRating = r.FeedbackRating,
            FeedbackComment = r.FeedbackComment,
            FeedbackUpdatedAt = r.FeedbackUpdatedAt,
            CreatedAt = r.CreatedAt,
            UpdatedAt = r.UpdatedAt,
            UserId = r.UserId,
            UserFullName = r.User?.FullName,
            UserProfilePictureUrl = r.User?.ProfilePictureUrl
        };
    }
}
