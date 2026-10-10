namespace MunicipalReportingAPI.Helpers
{
    public static class GeoHelper
    {
        private const double EarthRadiusMeters = 6371000;

        public static double DistanceMeters(double lat1, double lon1, double lat2, double lon2)
        {
            static double Rad(double d) => d * Math.PI / 180.0;

            var dLat = Rad(lat2 - lat1);
            var dLon = Rad(lon2 - lon1);
            var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                    Math.Cos(Rad(lat1)) * Math.Cos(Rad(lat2)) *
                    Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
            return EarthRadiusMeters * 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
        }

        // Cheap box used to narrow the SQL query before the exact distance check.
        public static (double minLat, double maxLat, double minLon, double maxLon) BoundingBox(
            double lat, double lon, double radiusMeters)
        {
            var dLat = radiusMeters / 111320.0;
            var cos = Math.Max(Math.Cos(lat * Math.PI / 180.0), 0.01);
            var dLon = radiusMeters / (111320.0 * cos);
            return (lat - dLat, lat + dLat, lon - dLon, lon + dLon);
        }
    }
}
