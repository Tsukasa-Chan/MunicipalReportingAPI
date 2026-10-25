using System.ComponentModel.DataAnnotations;

namespace MunicipalReportingAPI.DTO
{
    public class CreateSupervisorDTO
    {
        [Required]
        public string FullName { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;
    }
}
