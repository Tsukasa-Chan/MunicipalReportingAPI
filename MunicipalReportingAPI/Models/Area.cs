namespace MunicipalReportingAPI.Models
{
    // A suburb / neighbourhood inside a Ward. A Ward is always reached through the Area
    // (User/Issue/Report -> Area -> Ward); WardId is never stored on those entities.
    public class Area
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;

        public int WardId { get; set; }
        public Ward? Ward { get; set; }

        public ICollection<ApplicationUser> Users { get; set; } = new List<ApplicationUser>();
        public ICollection<Issue> Issues { get; set; } = new List<Issue>();
        public ICollection<Report> Reports { get; set; } = new List<Report>();
    }
}
