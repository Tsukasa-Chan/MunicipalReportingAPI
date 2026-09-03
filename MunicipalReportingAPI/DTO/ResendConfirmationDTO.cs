using System.ComponentModel.DataAnnotations;

namespace MunicipalReportingAPI.DTO
{
    public class ResendConfirmationDTO
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;
    }
}
