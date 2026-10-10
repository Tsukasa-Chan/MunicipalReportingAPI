namespace MunicipalReportingAPI.DTO
{
    // A user as seen by an Admin
    public class AdminUserDTO
    {
        public int Id { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string? Email { get; set; }
        public bool EmailConfirmed { get; set; }
        public string? ProfilePictureUrl { get; set; }

        // "User", "Supervisor" or "Admin"
        public string? Role { get; set; }

        // True while the account is locked out after too many failed logins
        public bool LockedOut { get; set; }

        // Reports this person has submitted
        public int ReportCount { get; set; }

        // Issues currently assigned to this person (only meaningful for Supervisors)
        public int AssignedIssueCount { get; set; }
    }
}
