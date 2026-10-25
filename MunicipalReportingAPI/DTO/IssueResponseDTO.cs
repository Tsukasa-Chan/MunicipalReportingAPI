using MunicipalReportingAPI.Models;

namespace MunicipalReportingAPI.DTO
{
    public class IssueResponseDTO
    {
        public int Id { get; set; }
        public IssueCategory IssueCategory { get; set; }
        public IssueType IssueType { get; set; }
        public int AreaId { get; set; }
        public string AreaName { get; set; } = string.Empty;
        public int WardId { get; set; }
        public string WardName { get; set; } = string.Empty;

        public string Location { get; set; } = string.Empty;
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        public ReportStatus Status { get; set; }
        public int? SupervisorId { get; set; }
        public string? SupervisorName { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }

        // "20 residents have reported this issue"
        public int ReportCount { get; set; }

        // The first report is shown as the primary information
        public string? OriginalDescription { get; set; }
        public string? OriginalImageUrl { get; set; }

        // Only filled by /api/issues/nearby
        public double? DistanceMeters { get; set; }
    }
}
