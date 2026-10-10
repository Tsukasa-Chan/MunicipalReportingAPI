using System.ComponentModel.DataAnnotations;

namespace MunicipalReportingAPI.DTO
{
    public class ChangeEmailDTO
    {
        [Required]
        [EmailAddress]
        public string NewEmail { get; set; } = string.Empty;

        [Required]
        public string CurrentPassword { get; set; } = string.Empty;
    }
}