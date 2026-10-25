using MunicipalReportingAPI.Models;

namespace MunicipalReportingAPI.Options
{
    public enum MatchStrategy
    {
        // Same category + type + unresolved + within RadiusMeters of the Issue's coordinates.
        // The AreaId is ignored (an issue can sit on an Area boundary).
        Gps,

        // Same category + type + unresolved + same AreaId. Coordinates are ignored.
        Area
    }

    public class IssueMatchRule
    {
        public MatchStrategy Strategy { get; set; } = MatchStrategy.Gps;

        // Only used by the Gps strategy. Null = use IssueGroupingOptions.DefaultRadiusMeters.
        public double? RadiusMeters { get; set; }
    }

    public class IssueGroupingOptions
    {
        public const string SectionName = "IssueGrouping";

        // Radius used for GPS matching when an IssueType has no explicit radius,
        // and the default radius of GET /api/issues/nearby.
        public double DefaultRadiusMeters { get; set; } = 50;

        // Per-IssueType rules, keyed by IssueType name (see appsettings.json).
        // An IssueType with no entry uses the Gps strategy with DefaultRadiusMeters.
        public Dictionary<IssueType, IssueMatchRule> Rules { get; set; } = new();
    }
}
