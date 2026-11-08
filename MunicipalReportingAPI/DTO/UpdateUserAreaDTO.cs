using System.ComponentModel.DataAnnotations;

namespace MunicipalReportingAPI.DTO
{
    public class UpdateUserAreaDTO
    {
        [Range(1, int.MaxValue)]
        public int AreaId { get; set; }
    }
}
