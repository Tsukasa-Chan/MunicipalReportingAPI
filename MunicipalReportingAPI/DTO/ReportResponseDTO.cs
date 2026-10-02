using MunicipalReportingAPI.Models;

namespace MunicipalReportingAPI.DTO
{
    public class ReportResponseDTO
    {
        public int Id { get; set; }
        public IssueCategory IssueCategory { get; set; }
        public IssueType IssueType { get; set; }
        public string? ImageUrl { get; set; }
        public string Location { get; set; } = string.Empty;
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        public string? Description { get; set; }
        public ReportStatus Status { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }

        public int UserId { get; set; }
        public string? UserFullName { get; set; }
        public string? UserProfilePictureUrl { get; set; }

        public static ReportResponseDTO FromReport(Report r) => new ReportResponseDTO
        {
            Id = r.Id,
            IssueCategory = r.IssueCategory,
            IssueType = r.IssueType,
            ImageUrl = r.ImageUrl,
            Location = r.Location,
            Latitude = r.Latitude,
            Longitude = r.Longitude,
            Description = r.Description,
            Status = r.Status,
            CreatedAt = r.CreatedAt,
            UpdatedAt = r.UpdatedAt,
            UserId = r.UserId,
            UserFullName = r.User?.FullName,
            UserProfilePictureUrl = r.User?.ProfilePictureUrl
        };
    }
}
