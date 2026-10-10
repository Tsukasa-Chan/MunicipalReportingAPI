using MunicipalReportingAPI.Models;

namespace MunicipalReportingAPI.DTO
{
    // A supporting report as seen from the Issue (no duplicated issue fields)
    public class IssueReportDTO
    {
        public int Id { get; set; }
        public int IssueId { get; set; }
        public string? Description { get; set; }
        public string? ImageUrl { get; set; }
        public string Location { get; set; } = string.Empty;
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        public DateTime CreatedAt { get; set; }
        public int? UserId { get; set; }
        public string? UserFullName { get; set; }
        public string? UserProfilePictureUrl { get; set; }

        public static IssueReportDTO FromReport(Report r) => new IssueReportDTO
        {
            Id = r.Id,
            IssueId = r.IssueId,
            Description = r.Description,
            ImageUrl = r.ImageUrl,
            Location = r.Location,
            Latitude = r.Latitude,
            Longitude = r.Longitude,
            CreatedAt = r.CreatedAt,
            UserId = r.UserId,
            UserFullName = r.User?.FullName,
            UserProfilePictureUrl = r.User?.ProfilePictureUrl
        };
    }
}
