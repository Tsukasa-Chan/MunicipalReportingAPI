using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using MunicipalReportingAPI.Data;
using MunicipalReportingAPI.Helpers;
using MunicipalReportingAPI.Models;
using MunicipalReportingAPI.Options;

namespace MunicipalReportingAPI.Services
{
    public class IssueService : IIssueService
    {
        private readonly MunicipalDBContext _context;
        private readonly IssueGroupingOptions _options;

        public IssueService(MunicipalDBContext context, IOptions<IssueGroupingOptions> options)
        {
            _context = context;
            _options = options.Value;
        }

        public double MatchRadiusMeters => _options.DefaultRadiusMeters;

        public (MatchStrategy Strategy, double RadiusMeters) GetRule(IssueType issueType)
        {
            if (_options.Rules.TryGetValue(issueType, out var rule))
            {
                return rule.Strategy == MatchStrategy.Area
                    ? (MatchStrategy.Area, 0)
                    : (MatchStrategy.Gps, rule.RadiusMeters ?? _options.DefaultRadiusMeters);
            }

            return (MatchStrategy.Gps, _options.DefaultRadiusMeters);
        }

        public bool IsMatch(Issue issue, IssueCategory category, IssueType issueType, int areaId, double latitude, double longitude)
        {
            if (issue.Status == ReportStatus.Resolved
                || issue.IssueCategory != category
                || issue.IssueType != issueType)
            {
                return false;
            }

            var (strategy, radius) = GetRule(issueType);

            return strategy == MatchStrategy.Area
                ? issue.AreaId == areaId
                : GeoHelper.DistanceMeters(latitude, longitude, issue.Latitude, issue.Longitude) <= radius;
        }

        public async Task<Issue?> FindMatchingIssueAsync(
            IssueCategory category, IssueType issueType, int areaId, double latitude, double longitude)
        {
            var (strategy, radius) = GetRule(issueType);

            if (strategy == MatchStrategy.Area)
            {
                // Oldest open Issue wins if (unexpectedly) there is more than one
                return await _context.Issues
                    .Where(i => i.Status != ReportStatus.Resolved
                             && i.IssueCategory == category
                             && i.IssueType == issueType
                             && i.AreaId == areaId)
                    .OrderBy(i => i.CreatedAt).ThenBy(i => i.Id)
                    .FirstOrDefaultAsync();
            }

            // FindNearbyAsync applies the bounding box and then the exact Haversine distance,
            // nearest first. The AreaId is deliberately not used.
            var nearby = await FindNearbyAsync(latitude, longitude, radius, issueType);

            return nearby
                .Select(n => n.Issue)
                .FirstOrDefault(i => i.IssueCategory == category);
        }

        public async Task<List<(Issue Issue, double DistanceMeters)>> FindNearbyAsync(
            double latitude, double longitude, double radiusMeters, IssueType? issueType = null)
        {
            var box = GeoHelper.BoundingBox(latitude, longitude, radiusMeters);

            var query = _context.Issues
                .Where(i => i.Status != ReportStatus.Resolved
                         && i.Latitude >= box.minLat && i.Latitude <= box.maxLat
                         && i.Longitude >= box.minLon && i.Longitude <= box.maxLon);

            if (issueType.HasValue)
            {
                query = query.Where(i => i.IssueType == issueType.Value);
            }

            var candidates = await query.ToListAsync();

            return candidates
                .Select(i => (Issue: i, Distance: GeoHelper.DistanceMeters(latitude, longitude, i.Latitude, i.Longitude)))
                .Where(x => x.Distance <= radiusMeters)
                .OrderBy(x => x.Distance)
                .Select(x => (x.Issue, x.Distance))
                .ToList();
        }
    }
}
