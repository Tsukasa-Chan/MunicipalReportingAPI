using System.ComponentModel.DataAnnotations;

namespace MunicipalReportingAPI.DTO
{
    public class SubmitResolutionFeedbackDTO
    {
        [Range(1, 5)]
        public int Rating { get; set; }

        [StringLength(1000)]
        public string? Comment { get; set; }
    }
}
