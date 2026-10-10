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

        // Where the report is located (does not have to be the resident's home Area)
        [Required]
        [Range(1, int.MaxValue)]
        public int AreaId { get; set; }

        [Required]
        public string Location { get; set; }

        [Required]
        [Range(-90, 90)]
        public double Latitude { get; set; }

        [Required]
        [Range(-180, 180)]
        public double Longitude { get; set; }

        [MaxLength(1000)]
        public string? Description { get; set; }

        public IFormFile? Image { get; set; }
    }
}
