using Microsoft.AspNetCore.Identity;

namespace MunicipalReportingAPI.Models
{
    public class ApplicationUser:IdentityUser<int>
    {
        public string FullName { get; set; } = string.Empty;
        public string? ProfilePictureUrl { get; set; }
    }
}
