using System.ComponentModel.DataAnnotations;

namespace MunicipalReportingAPI.DTO
{
    public class DeleteAccountDTO
    {
        [Required]
        public string CurrentPassword { get; set; } = string.Empty;

        [Required]
        public bool Confirm { get; set; }
    }
}
