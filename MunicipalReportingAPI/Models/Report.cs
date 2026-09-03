namespace MunicipalReportingAPI.Models
{
    public class Report
    {
        public int Id { get; set; }
        public IssueCategory IssueCategory { get; set; }
        public IssueType IssueType { get; set; }
        public string? ImageUrl { get; set; }
        public string Location { get; set; }
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        public ReportStatus Status { get; set; } = ReportStatus.Reported;
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }

        public int UserId { get; set; }
        public ApplicationUser? User { get; set; }
    }
}
