namespace MunicipalReportingAPI.Models
{
    public class RefreshToken
    {
        public int Id { get; set; }
        public string Token { get; set; } = string.Empty;
        public DateTime ExpiresAt { get; set; }
        public bool IsRevoked { get; set; } = false;

        // Set when this token was exchanged for a new one (rotation). A rotated token that
        // shows up again later means it was copied. Tokens revoked by logout or a password
        // change leave this null.
        public DateTime? RotatedAt { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public int UserId { get; set; }
        public ApplicationUser? User { get; set; }
    }
}
