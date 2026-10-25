using System.ComponentModel.DataAnnotations;

namespace MunicipalReportingAPI.DTO
{
    public class ForgotPasswordDTO
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;
    }
}
