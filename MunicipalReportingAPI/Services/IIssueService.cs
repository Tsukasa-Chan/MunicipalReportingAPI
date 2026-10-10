using MunicipalReportingAPI.Models;
using MunicipalReportingAPI.Options;

namespace MunicipalReportingAPI.Services
{
    // All Issue-matching rules live here, so they can be changed in one place.
    // The strategy (Gps or Area) is chosen from the IssueType via IssueGroupingOptions.
    // Matching never looks at the Location text.
    public interface IIssueService
    {
        // Default radius for /api/issues/nearby and for IssueTypes with no explicit radius
        double MatchRadiusMeters { get; }

        // The effective strategy and radius for an IssueType (radius is 0 for Area strategy)
        (MatchStrategy Strategy, double RadiusMeters) GetRule(IssueType issueType);

        // Does this report belong to this Issue? Resolved Issues never match.
        bool IsMatch(Issue issue, IssueCategory category, IssueType issueType, int areaId, double latitude, double longitude);

        // The open (not Resolved) Issue this report belongs to, or null.
        //  Area: same category + type + AreaId.
        //  Gps : same category + type + nearest within the configured radius (AreaId ignored).
        Task<Issue?> FindMatchingIssueAsync(IssueCategory category, IssueType issueType, int areaId, double latitude, double longitude);

        // Open Issues near a point, nearest first, with their distance in metres.
        Task<List<(Issue Issue, double DistanceMeters)>> FindNearbyAsync(double latitude, double longitude, double radiusMeters, IssueType? issueType = null);
    }
}
