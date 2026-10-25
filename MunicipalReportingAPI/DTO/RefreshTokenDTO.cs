using System.ComponentModel.DataAnnotations;

namespace MunicipalReportingAPI.DTO
{
    public class RefreshTokenDTO
    {
        [Required]
        public string RefreshToken { get; set; } = string.Empty;
    }
}
