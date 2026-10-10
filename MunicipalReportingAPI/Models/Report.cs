namespace MunicipalReportingAPI.Models
{
    // One resident's submission. It keeps everything the resident entered.
    // Status and supervisor live on the Issue.
    public class Report
    {
        public int Id { get; set; }
        public IssueCategory IssueCategory { get; set; }
        public IssueType IssueType { get; set; }
        public string? ImageUrl { get; set; }
        // Where the resident says the report is. Independent of the Issue's Area.
        public int AreaId { get; set; }
        public Area? Area { get; set; }

        public string Location { get; set; } = string.Empty;
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        public string? Description { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }

        // Null when the resident deleted their account but the report was kept
        // because its Issue is In Progress or Resolved.
        public int? UserId { get; set; }
        public ApplicationUser? User { get; set; }

        public int IssueId { get; set; }
        public Issue? Issue { get; set; }
    }
}
