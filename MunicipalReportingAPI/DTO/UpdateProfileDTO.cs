using System.ComponentModel.DataAnnotations;

namespace MunicipalReportingAPI.DTO
{
    public class UpdateProfileDTO
    {
        [Required]
        [MaxLength(100)]
        public string FullName { get; set; } = string.Empty;
    }
}