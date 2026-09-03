using System.ComponentModel.DataAnnotations;

using MunicipalReportingAPI.Models;

namespace MunicipalReportingAPI.DTO
{
    public class CreateReportDTO
    {
        

        [Required]
        public IssueCategory IssueCategory { get; set; }

        [Required]
        public IssueType IssueType { get; set; }

        [Required]
        public string Location { get; set; }

        [Required]
        public double Latitude { get; set; }

        [Required]
        public double Longitude { get; set; }

        public IFormFile? Image { get; set; }
    }
}
