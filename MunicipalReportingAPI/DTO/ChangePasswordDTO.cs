using System.ComponentModel.DataAnnotations;

namespace MunicipalReportingAPI.DTO
{
    public class ChangePasswordDTO
    {
        [Required]
        public string CurrentPassword { get; set; } = string.Empty;

        [Required]
        [MinLength(8)]
        public string NewPassword { get; set; } = string.Empty;
    }
}
