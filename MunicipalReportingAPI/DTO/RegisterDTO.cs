using System.ComponentModel.DataAnnotations;

namespace MunicipalReportingAPI.DTO
{
    public class RegisterDTO
    {
        [Required]
        public string FullName { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        [MinLength(8)]
        public string Password { get; set; } = string.Empty;

        // The resident's home Area. The Ward is derived from it.
        [Required]
        [Range(1, int.MaxValue)]
        public int AreaId { get; set; }
    }
}
