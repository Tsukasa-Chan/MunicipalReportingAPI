using MunicipalReportingAPI.Models;

namespace MunicipalReportingAPI.DTO
{
    public class IssueStatsDTO
    {
        public int TotalIssues { get; set; }
        public int ActiveIssues { get; set; }
        public int ResolvedIssues { get; set; }
        public int TotalReports { get; set; }
        public int Reported { get; set; }
        public int InProgress { get; set; }
        public int Resolved { get; set; }

        // Per-category counts of ISSUES (not reports), for the dashboard.
        // Always contains all four categories, with zeros where there are none.
        public List<CategoryStatsDTO> ByCategory { get; set; } = new();
    }

    public class CategoryStatsDTO
    {
        public IssueCategory Category { get; set; }
        public int Total { get; set; }
        public int Active { get; set; }      // Reported + InProgress
        public int Reported { get; set; }
        public int InProgress { get; set; }
        public int Resolved { get; set; }
        public int TotalReports { get; set; } // residents' reports behind those issues
    }
}
