
import 'dart:math' as math;

/// Approximate location validation for Fix My Area.
///
/// 27 areas use rectangles derived from municipal GIS polygons.
/// 4 areas use manually provided geographical rectangles.
/// 4 areas use a 500-metre radius from a reference point.
///
/// These are approximate boundaries, not official suburb limits.
class AreaLocationValidator {
  const AreaLocationValidator._();

  static String? errorFor(
      String area,
      double latitude,
      double longitude,
      ) {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return 'Invalid location coordinates.';
    }

    final regions = _rectangles[area];

    if (regions != null) {
      if (regions.any(
            (r) => r.contains(latitude, longitude),
      )) {
        return null;
      }

      return 'The selected location is outside the approximate '
          'area for $area. '
          'Selected pin: '
          '${latitude.toStringAsFixed(6)}, '
          '${longitude.toStringAsFixed(6)}. '
          'Please choose a point within your selected area.';
    }

    final reference = _referencePoints[area];

    if (reference != null) {
      final distance = _distanceMetres(
        latitude,
        longitude,
        reference.$1,
        reference.$2,
      );

      if (distance <= _referenceRadiusMetres) {
        return null;
      }

      return 'The selected location is more than '
          '${_referenceRadiusMetres.toInt()} m '
          'from the mapped reference point for $area. '
          'Please choose a closer point or check your selected area.';
    }

    return 'No geographical validation data is configured for $area.';
  }

  static const double _referenceRadiusMetres = 500;

  /// Calculates the distance between two GPS coordinates.
  static double _distanceMetres(
      double lat1,
      double lon1,
      double lat2,
      double lon2,
      ) {
    const radius = 6371000.0;

    final latDelta = (lat2 - lat1) * math.pi / 180;
    final lonDelta = (lon2 - lon1) * math.pi / 180;

    final a = math.pow(math.sin(latDelta / 2), 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.pow(math.sin(lonDelta / 2), 2);

    return 2 *
        radius *
        math.asin(math.min(1.0, math.sqrt(a)));
  }

  // ==========================================================
  // AREAS USING MUNICIPAL REFERENCE COORDINATES
  // ==========================================================

  static const Map<String, (double, double)>
  _referencePoints = {
    'Hammonds Farm': (-29.651905, 31.073466),
    'Lungelani': (-29.638775, 31.124541),
    'Pholani': (-29.630229, 31.141056),
    'Thuthukani': (-29.603805, 31.160506),
  };

  // ==========================================================
  // AREA BOUNDING RECTANGLES
  // ==========================================================

  static const Map<String, List<_AreaRectangle>>
  _rectangles = {

    // ========================================================
    // WARD 58
    // ========================================================

    'Brake Village': [
      _AreaRectangle(
        -29.5840000,
        -29.5745000,
        31.1120000,
        31.1255000,
      ),
    ],

    'Canelands': [
      _AreaRectangle(
        -29.6484367,
        -29.6157468,
        31.0423935,
        31.0807363,
      ),
    ],

    'Casuarina': [
      _AreaRectangle(
        -29.6034827,
        -29.5834824,
        31.1628849,
        31.1772242,
      ),
    ],

    'Desainagar': [
      _AreaRectangle(
        -29.6335633,
        -29.6098201,
        31.1376092,
        31.1592530,
      ),
    ],

    'Ghandinagar': [
      _AreaRectangle(
        -29.5817902,
        -29.5704593,
        31.1104852,
        31.1209638,
      ),
    ],

    'King Shaka International Airport zone': [
      _AreaRectangle(
        -29.6421439,
        -29.5849231,
        31.0744305,
        31.1406438,
      ),
    ],

    'La Mercy': [
      _AreaRectangle(
        -29.6522928,
        -29.6321271,
        31.1200414,
        31.1409984,
      ),
    ],

    'Sastri Circle / Belgate': [
      _AreaRectangle(
        -29.5695000,
        -29.5560000,
        31.1025000,
        31.1190000,
      ),
    ],

    'Tongaat Beach / Westbrook': [
      _AreaRectangle(
        -29.7062111,
        -29.5838365,
        31.0607796,
        31.1518749,
      ),
      _AreaRectangle(
        -29.5967630,
        -29.5853081,
        31.1601584,
        31.1731703,
      ),
      _AreaRectangle(
        -29.5846174,
        -29.5765110,
        31.1756304,
        31.1830463,
      ),
      _AreaRectangle(
        -29.6206081,
        -29.6097745,
        31.1473118,
        31.1597260,
      ),
    ],

    // ========================================================
    // WARD 61
    // ========================================================

    'Belvedere (including Belvedere North)': [
      _AreaRectangle(
        -29.5857059,
        -29.5729822,
        31.0738532,
        31.0900361,
      ),
    ],

    'Buffelsdale': [
      _AreaRectangle(
        -29.5878912,
        -29.5784253,
        31.0933246,
        31.1020605,
      ),
    ],

    'Chelmsford Heights': [
      _AreaRectangle(
        -29.5852532,
        -29.5796394,
        31.0978156,
        31.1065266,
      ),
    ],

    'Emona Sunhill': [
      _AreaRectangle(
        -29.5590440,
        -29.5387746,
        31.0899910,
        31.1199970,
      ),
    ],

    'Gwalas Farm': [
      _AreaRectangle(
        -29.5806044,
        -29.5735691,
        31.0723551,
        31.0790273,
      ),
    ],

    'Mithangar': [
      _AreaRectangle(
        -29.5817844,
        -29.5765243,
        31.1005025,
        31.1114007,
      ),
    ],

    'Plain Street': [
      _AreaRectangle(
        -29.5815000,
        -29.5740000,
        31.1180000,
        31.1275000,
      ),
    ],

    // Updated Sandfields boundary
    'Sandfields': [
      _AreaRectangle(
        -29.5430509,
        -29.5211453,
        31.1286652,
        31.1480000,
      ),
    ],

    'Umbhayi': [
      _AreaRectangle(
        -29.5772895,
        -29.5684092,
        31.0816267,
        31.0996213,
      ),
    ],

    'Watsonia': [
      _AreaRectangle(
        -29.5795657,
        -29.5729008,
        31.0941027,
        31.1059407,
      ),
    ],

    // ========================================================
    // WARD 62
    // ========================================================

    'Burbreeze': [
      _AreaRectangle(
        -29.5460267,
        -29.5335051,
        31.1363695,
        31.1480432,
      ),
    ],

    'Fairbreeze': [
      _AreaRectangle(
        -29.5656316,
        -29.5450493,
        31.1225893,
        31.1425658,
      ),
    ],

    'Flamingo Heights': [
      _AreaRectangle(
        -29.5841900,
        -29.5741750,
        31.0829225,
        31.0971778,
      ),
    ],

    'Gandhi’s Hill': [
      _AreaRectangle(
        -29.5673109,
        -29.5567987,
        31.1131660,
        31.1288343,
      ),
    ],

    'Hambanathi': [
      _AreaRectangle(
        -29.5617505,
        -29.5425994,
        31.1151074,
        31.1269546,
      ),
    ],

    'Lauriston': [
      _AreaRectangle(
        -29.5930000,
        -29.5845000,
        31.1215000,
        31.1320000,
      ),
    ],

    'Magwaveni': [
      _AreaRectangle(
        -29.5588071,
        -29.5435088,
        31.1323696,
        31.1467056,
      ),
    ],

    'Maidstone Village': [
      _AreaRectangle(
        -29.5585455,
        -29.5406279,
        31.1229345,
        31.1376784,
      ),
    ],

    'OThongathi CBD / Tongaat Central': [
      _AreaRectangle(
        -29.5737546,
        -29.5655385,
        31.1153799,
        31.1231391,
      ),
    ],

    'Riverside AH': [
      _AreaRectangle(
        -29.5670545,
        -29.5324728,
        31.1443554,
        31.1807448,
      ),
    ],

    'Tongaat Industrial / Trurolands': [
      _AreaRectangle(
        -29.5763603,
        -29.5696248,
        31.0960854,
        31.1090859,
      ),
      _AreaRectangle(
        -29.5634469,
        -29.5545822,
        31.1252430,
        31.1390783,
      ),
    ],

    'Vanrova': [
      _AreaRectangle(
        -29.5648523,
        -29.5563518,
        31.1019404,
        31.1203871,
      ),
    ],
  };
}

/// Represents a rectangular geographical boundary.
class _AreaRectangle {
  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;

  const _AreaRectangle(
      this.minLat,
      this.maxLat,
      this.minLon,
      this.maxLon,
      );

  bool contains(double lat, double lon) {
    return lat >= minLat &&
        lat <= maxLat &&
        lon >= minLon &&
        lon <= maxLon;
  }
}
