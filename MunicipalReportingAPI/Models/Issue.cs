namespace MunicipalReportingAPI.Models
{
    // The actual municipal problem. Many residents' Reports can point at one Issue.
    public class Issue
    {
        public int Id { get; set; }
        public IssueCategory IssueCategory { get; set; }
        public IssueType IssueType { get; set; }
        public string Location { get; set; } = string.Empty;
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        // Area associated with the Issue (the Area of the report that created it).
        // The Ward is reached via Area.Ward.
        public int AreaId { get; set; }
        public Area? Area { get; set; }

        public ReportStatus Status { get; set; } = ReportStatus.Reported;
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }

        public int? SupervisorId { get; set; }
        // "I added public DateTime? ScheduledAt { get; set; }
        // to show the supervisor
        // run a new EF core migration to update the database."
        public DateTime? ScheduledAt { get; set; }
        public ApplicationUser? Supervisor { get; set; }

        public ICollection<Report> Reports { get; set; } = new List<Report>();
    }
}
