using System.ComponentModel.DataAnnotations;

namespace MunicipalReportingAPI.DTO
{
    public class ChangeUserRoleDTO
    {
        // "User" or "Supervisor". "Admin" can never be assigned through the API.
        [Required]
        public string Role { get; set; } = string.Empty;
    }
}
