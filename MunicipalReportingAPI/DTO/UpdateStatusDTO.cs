using System.ComponentModel.DataAnnotations;
using MunicipalReportingAPI.Models;

namespace MunicipalReportingAPI.DTO
{
    public class UpdateStatusDTO
    {
        [Required]
        public ReportStatus Status { get; set; }
    }
}
