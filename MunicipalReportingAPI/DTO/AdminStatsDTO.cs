namespace MunicipalReportingAPI.DTO
{
    // Issues = actual municipal problems. Reports = resident submissions/confirmations.
    public class AdminStatsDTO
    {
        // Issues
        public int TotalIssues { get; set; }
        public int Reported { get; set; }
        public int InProgress { get; set; }
        public int Resolved { get; set; }
        public int ActiveIssues { get; set; }

        // Not resolved and no supervisor assigned yet
        public int UnassignedActiveIssues { get; set; }

        // Issues backed by more than one resident report
        public int IssuesWithMultipleReports { get; set; }

        // Reports
        public int TotalReports { get; set; }

        // Users
        public int TotalUsers { get; set; }
        public int Users { get; set; }
        public int Supervisors { get; set; }
        public int Admins { get; set; }

        public List<CategoryStatDTO> IssuesByCategory { get; set; } = new();
    }

    public class CategoryStatDTO
    {
        public string Category { get; set; } = string.Empty;
        public int Issues { get; set; }
        public int Reports { get; set; }
    }
}
