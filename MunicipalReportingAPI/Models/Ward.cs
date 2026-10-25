namespace MunicipalReportingAPI.Models
{
    // Top of the location hierarchy: Ward -> Area. Seeded with stable IDs (58, 61, 62).
    public class Ward
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;

        public ICollection<Area> Areas { get; set; } = new List<Area>();
    }
}
