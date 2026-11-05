using System.ComponentModel.DataAnnotations;

namespace MunicipalReportingAPI.DTO
{
    public class BugReportDTO
    {
        [Required]
        [StringLength(100)]
        public string Name { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        [StringLength(2000)]
        public string Description { get; set; } = string.Empty;
    }
}