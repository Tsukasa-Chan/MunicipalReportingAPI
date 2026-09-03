namespace MunicipalReportingAPI.Models
{
    public class RevokedToken
    {
        public int Id { get; set; }
        public string Jti { get; set; }
        public DateTime ExpiresAt { get; set; }
    }
}
