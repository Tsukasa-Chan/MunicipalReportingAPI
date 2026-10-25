using Microsoft.AspNetCore.Identity;

namespace MunicipalReportingAPI.Models
{
    public class ApplicationUser:IdentityUser<int>
    {
        public string FullName { get; set; } = string.Empty;
        public string? ProfilePictureUrl { get; set; }

        // Home/default Area. Nullable so Admin/Supervisor accounts need no residential Area;
        // normal registration requires it. The Ward is reached via Area.Ward.
        public int? AreaId { get; set; }
        public Area? Area { get; set; }
    }
}
