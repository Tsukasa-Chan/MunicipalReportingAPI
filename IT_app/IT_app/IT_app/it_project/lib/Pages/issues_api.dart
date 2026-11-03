// Tools for running code in the background (Future, Timer).
import 'dart:async';
// Tools for turning JSON text into Dart objects and back.
import 'dart:convert';
// Gives us SocketException, which is thrown when there is no connection.
import 'dart:io';

// The http package, used to send requests to the server.
import 'package:http/http.dart' as http;

// Knows the server address.
import 'api_config.dart';
// Holds the route paths such as /api/Issues.
import 'api_paths.dart';

import 'package:flutter/foundation.dart';

// "StreetLightNotWorking" -> "Street light not working".
String humanizeEnumName(String value) {
  // Remove spaces around the text.
  final trimmed = value.trim();
  // Nothing to convert if the text is empty.
  if (trimmed.isEmpty) return '';
  // Put a space between a lowercase letter/digit and a capital letter that follows it.
  final spaced = trimmed.replaceAllMapped(
    // Finds "a lowercase/digit" followed by "a capital letter".
    RegExp(r'([a-z0-9])([A-Z])'),
    // Rebuilds the match with a space in the middle.
        (match) => '${match[1]} ${match[2]}',
  );
  // Capital first letter, everything else lowercase.
  return spaced[0].toUpperCase() + spaced.substring(1).toLowerCase();
}

// The four issue categories, as the backend names them.
class IssueCategories {
  // Private constructor: this class is only used for its static members.
  const IssueCategories._();

  // Backend name for water and sanitation issues.
  static const waterAndSanitation = 'WaterAndSanitation';
  // Backend name for roads and stormwater issues.
  static const roadsAndStormwater = 'RoadsAndStormwater';
  // Backend name for electricity issues.
  static const electricity = 'Electricity';
  // Backend name for waste management issues.
  static const wasteManagement = 'WasteManagement';

  // Dashboard order.
  // A list of all four categories, in the order the dashboard shows them.
  static const all = <String>[
    // First in the list.
    waterAndSanitation,
    // Second in the list.
    roadsAndStormwater,
    // Third in the list.
    electricity,
    // Fourth in the list.
    wasteManagement,
  ];

  // Turns a backend category name into text a person can read.
  static String label(String key) => switch (key) {
  // Show this friendly text for water and sanitation.
    'WaterAndSanitation' => 'Water and sanitation',
  // Show this friendly text for roads and stormwater.
    'RoadsAndStormwater' => 'Roads and stormwater',
  // Electricity is already readable.
    'Electricity' => 'Electricity',
  // Show this friendly text for waste management.
    'WasteManagement' => 'Waste management',
  // Any unknown category: just split the name into words.
    _ => humanizeEnumName(key),
  };
}

// The three statuses an issue can have, as the backend names them.
class IssueStatuses {
  // Private constructor: this class is only used for its static members.
  const IssueStatuses._();

  // Nobody has started work yet.
  static const reported = 'Reported';
  // Work has started.
  static const inProgress = 'InProgress';
  // The problem has been fixed.
  static const resolved = 'Resolved';

  // A list of all statuses, used for the filter buttons.
  static const all = <String>[reported, inProgress, resolved];

  // Turns a backend status name into text a person can read.
  static String label(String key) => switch (key) {
  // Show "Reported" as it is.
    'Reported' => 'Reported',
  // Add a space: "In progress".
    'InProgress' => 'In progress',
  // Show "Resolved" as it is.
    'Resolved' => 'Resolved',
  // Any unknown status: just split the name into words.
    _ => humanizeEnumName(key),
  };
}


// Safely reads a whole number from JSON (0 if it is missing or not a number).
int _asInt(Object? value) {
  // If it is already a number, convert it to a whole number.
  if (value is num) return value.toInt();
  // Otherwise try to read it from text; use 0 if that fails.
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

// Safely reads text from JSON (empty text if it is missing).
String _asString(Object? value) => value?.toString().trim() ?? '';

// Safely reads a decimal number from JSON (null if it is missing).
double? _asDouble(Object? value) {
  // If it is already a number, convert it to a decimal.
  if (value is num) return value.toDouble();
  // Otherwise try to read it from text; null if that fails.
  return double.tryParse(value?.toString() ?? '');
}

// The backend stores UTC times but SQL Server hands them back without a
// "Z", so a missing zone is treated as UTC. Returns local time.
DateTime? parseServerTime(Object? value) {
  // Get the value as trimmed text (empty if missing).
  final text = value?.toString().trim() ?? '';
  // No text means no date.
  if (text.isEmpty) return null;
  // Check whether the text already ends with "Z" or a time zone offset like +02:00.
  final hasZone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(text);
  // Add "Z" (UTC) if there was no zone, read the date, then convert it to the phone's local time.
  return DateTime.tryParse(hasZone ? text : '${text}Z')?.toLocal();
}

// Adds an "s" to the unit when the count is not 1, e.g. "2 days".
String _plural(int count, String unit) => '$count $unit${count == 1 ? '' : 's'}';

// "5 min ago", "2 days ago", ...
String timeAgo(DateTime? time, {DateTime? now}) {
  // No time given means nothing to show.
  if (time == null) return '';
  // Work out how long ago it was (using UTC for both so time zones do not matter).
  final difference = (now ?? DateTime.now()).toUtc().difference(time.toUtc());
  // Less than a minute ago (or a clock mismatch that makes it negative).
  if (difference.isNegative || difference.inMinutes < 1) return 'just now';
  // Less than an hour: show minutes.
  if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
  // Less than a day: show hours.
  if (difference.inHours < 24) {
    // Example: "3 hours ago".
    return '${_plural(difference.inHours, 'hour')} ago';
  }
  // Less than about a month: show days.
  if (difference.inDays < 30) {
    // Example: "2 days ago".
    return '${_plural(difference.inDays, 'day')} ago';
  }
  // Less than a year: show months (30 days each).
  if (difference.inDays < 365) {
    // Example: "4 months ago".
    return '${_plural(difference.inDays ~/ 30, 'month')} ago';
  }
  // A year or more: show years.
  return '${_plural(difference.inDays ~/ 365, 'year')} ago';
}

// "3 Oct 2026, 09:05"
String formatDateTime(DateTime? time) {
  // No time given means nothing to show.
  if (time == null) return '';
  // Short month names, so January is months[0].
  const months = [
    // January to June.
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    // July to December.
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  // Show the time in the phone's own time zone.
  final local = time.toLocal();
  // Hour with a leading zero, e.g. "09".
  final hour = local.hour.toString().padLeft(2, '0');
  // Minute with a leading zero, e.g. "05".
  final minute = local.minute.toString().padLeft(2, '0');
  // Put it together: day, month name, year, and time.
  return '${local.day} ${months[local.month - 1]} ${local.year}, $hour:$minute';
}


// One municipal problem. Many residents' reports can point at one issue.
class AreaIssue {
  // Creates an issue; "required" fields must always be given.
  const AreaIssue({
    // The issue's id in the database.
    required this.id,
    // Its category, e.g. "WaterAndSanitation".
    required this.category,
    // Its type, e.g. "BurstPipe".
    required this.issueType,
    // Its status.
    required this.status,
    // How many residents reported it.
    required this.reportCount,
    // The area's id (0 if unknown).
    this.areaId = 0,
    // The area's name (empty if unknown).
    this.areaName = '',
    // The ward's id (0 if unknown).
    this.wardId = 0,
    // The ward's name (empty if unknown).
    this.wardName = '',
    // The address or description of where the problem is.
    this.location = '',
    // GPS latitude (may be missing).
    this.latitude,
    // GPS longitude (may be missing).
    this.longitude,
    // Name of the assigned supervisor (may be missing).
    this.supervisorName,
    // When the issue was first reported.
    this.createdAt,
    // When the issue was last changed.
    this.updatedAt,
    // The first report's description.
    this.description,
    // The first report's photo path.
    this.imageUrl,
  });

  // The issue's id in the database.
  final int id;
  final String category; // e.g. "WaterAndSanitation"
  final String issueType; // e.g. "BurstPipe"
  final String status; // "Reported" | "InProgress" | "Resolved"
  final int reportCount; // residents who reported this issue
  // The area's id.
  final int areaId;
  // The area's name.
  final String areaName;
  // The ward's id.
  final int wardId;
  // The ward's name.
  final String wardName;
  // Where the problem is.
  final String location;
  // GPS latitude (null if unknown).
  final double? latitude;
  // GPS longitude (null if unknown).
  final double? longitude;
  // Assigned supervisor's name (null if nobody is assigned).
  final String? supervisorName;
  // When it was first reported (null if unknown).
  final DateTime? createdAt;
  // When it was last updated (null if never).
  final DateTime? updatedAt;
  final String? description; // the first report's description
  final String? imageUrl; // server-relative path of the first report's photo

  // The category as readable text.
  String get categoryLabel => IssueCategories.label(category);
  // The issue type as readable text, e.g. "Burst pipe".
  String get issueTypeLabel => humanizeEnumName(issueType);
  // The status as readable text.
  String get statusLabel => IssueStatuses.label(status);
  // True when the problem has been fixed.
  bool get isResolved => status == IssueStatuses.resolved;

  // Builds an AreaIssue from one JSON object sent by the server.
  factory AreaIssue.fromJson(Map<String, dynamic> json) {
    // Read the description (empty text if missing).
    final description = _asString(json['originalDescription']);
    // Read the photo path (empty text if missing).
    final imageUrl = _asString(json['originalImageUrl']);
    // Read the supervisor name (empty text if missing).
    final supervisor = _asString(json['supervisorName']);

    // Create the issue from the JSON values.
    return AreaIssue(
      // Read the id.
      id: _asInt(json['id']),
      // Read the category name.
      category: _asString(json['issueCategory']),
      // Read the issue type name.
      issueType: _asString(json['issueType']),
      // Read the status name.
      status: _asString(json['status']),
      // Read how many residents reported it.
      reportCount: _asInt(json['reportCount']),
      // Read the area id.
      areaId: _asInt(json['areaId']),
      // Read the area name.
      areaName: _asString(json['areaName']),
      // Read the ward id.
      wardId: _asInt(json['wardId']),
      // Read the ward name.
      wardName: _asString(json['wardName']),
      // Read the location text.
      location: _asString(json['location']),
      // Read the latitude.
      latitude: _asDouble(json['latitude']),
      // Read the longitude.
      longitude: _asDouble(json['longitude']),
      // Use null instead of empty text when no supervisor is assigned.
      supervisorName: supervisor.isEmpty ? null : supervisor,
      // Read the creation time.
      createdAt: parseServerTime(json['createdAt']),
      // Read the last-updated time.
      updatedAt: parseServerTime(json['updatedAt']),
      // Use null instead of empty text when there is no description.
      description: description.isEmpty ? null : description,
      // Use null instead of empty text when there is no photo.
      imageUrl: imageUrl.isEmpty ? null : imageUrl,
    );
  }
}

// Counts for one category (used by the dashboard rows).
class CategoryStats {
  // Creates the counts; anything not given starts at 0.
  const CategoryStats({
    // Which category these counts are for.
    required this.category,
    // All issues in the category.
    this.total = 0,
    // Issues still open (reported + in progress).
    this.active = 0,
    // Issues not started yet.
    this.reported = 0,
    // Issues being worked on.
    this.inProgress = 0,
    // Issues that are fixed.
    this.resolved = 0,
    // Resident reports behind these issues.
    this.totalReports = 0,
  });

  // Which category these counts are for.
  final String category;
  final int total; // issues
  final int active; // reported + in progress
  // Issues not started yet.
  final int reported;
  // Issues being worked on.
  final int inProgress;
  // Issues that are fixed.
  final int resolved;
  final int totalReports; // residents' reports behind those issues

  // Builds CategoryStats from one JSON object sent by the server.
  factory CategoryStats.fromJson(Map<String, dynamic> json) => CategoryStats(
    // Read the category name.
    category: _asString(json['category']),
    // Read the total.
    total: _asInt(json['total']),
    // Read the active count.
    active: _asInt(json['active']),
    // Read the reported count.
    reported: _asInt(json['reported']),
    // Read the in-progress count.
    inProgress: _asInt(json['inProgress']),
    // Read the resolved count.
    resolved: _asInt(json['resolved']),
    // Read the number of resident reports.
    totalReports: _asInt(json['totalReports']),
  );
}

// Numbers for the dashboard. Counts are of ISSUES (distinct problems);
// [totalReports] is how many resident reports sit behind them.
class AreaStats {
  // Creates the numbers; anything not given starts at 0 (or an empty list).
  const AreaStats({
    // All issues in the area.
    this.totalIssues = 0,
    // Issues still open.
    this.activeIssues = 0,
    // Issues that are fixed.
    this.resolvedIssues = 0,
    // Resident reports behind all the issues.
    this.totalReports = 0,
    // Issues not started yet.
    this.reported = 0,
    // Issues being worked on.
    this.inProgress = 0,
    // Issues that are fixed.
    this.resolved = 0,
    // Counts for each category.
    this.byCategory = const [],
  });

  // All issues in the area.
  final int totalIssues;
  // Issues still open.
  final int activeIssues;
  // Issues that are fixed.
  final int resolvedIssues;
  // Resident reports behind all the issues.
  final int totalReports;
  // Issues not started yet.
  final int reported;
  // Issues being worked on.
  final int inProgress;
  // Issues that are fixed.
  final int resolved;
  // Counts for each category.
  final List<CategoryStats> byCategory;

  // Always returns something, so the dashboard can list all four categories
  // even if the server leaves one out.
  CategoryStats forCategory(String category) {
    // Look through each category the server sent.
    for (final stats in byCategory) {
      // Found the one we want, so return it.
      if (stats.category == category) return stats;
    }
    // The server did not send it, so return an all-zero version.
    return CategoryStats(category: category);
  }

  // Share of issues that are resolved, 0-100.
  int get resolvedPercent =>
      // Avoid dividing by zero when there are no issues.
  totalIssues <= 0 ? 0 : (resolvedIssues * 100 / totalIssues).round();

  // Builds AreaStats from the JSON object sent by the server.
  factory AreaStats.fromJson(Map<String, dynamic> json) {
    // The raw list of per-category counts (could be missing).
    final rawCategories = json['byCategory'];
    // Turn the raw list into CategoryStats objects.
    final categories = rawCategories is List
    // Keep only the items that are JSON objects.
        ? rawCategories
        .whereType<Map>()
    // Convert each one into a CategoryStats.
        .map((item) => CategoryStats.fromJson(
      // Make sure the keys are text.
      Map<String, dynamic>.from(item),
    ))
    // Put the results in a fixed list.
        .toList(growable: false)
    // If the server sent no list, use an empty one.
        : const <CategoryStats>[];

    // Create the stats from the JSON values.
    return AreaStats(
      // Read the total issues.
      totalIssues: _asInt(json['totalIssues']),
      // Read the active issues.
      activeIssues: _asInt(json['activeIssues']),
      // Read the resolved issues.
      resolvedIssues: _asInt(json['resolvedIssues']),
      // Read the resident reports total.
      totalReports: _asInt(json['totalReports']),
      // Read the reported count.
      reported: _asInt(json['reported']),
      // Read the in-progress count.
      inProgress: _asInt(json['inProgress']),
      // Read the resolved count.
      resolved: _asInt(json['resolved']),
      // Use the category list we built above.
      byCategory: categories,
    );
  }
}


// The error thrown when loading issues or stats fails.
class IssuesApiException implements Exception {
  // Creates the error with a message and an optional HTTP status code.
  const IssuesApiException(this.message, {this.statusCode});

  // A message that is safe to show to the user.
  final String message;
  // The HTTP status code (like 404), if the server answered.
  final int? statusCode;

  // Make the error print as just its message.
  @override
  String toString() => message;
}


class IssuesApi {
  // Creates the client; a fake client or address can be given (used in tests).
  IssuesApi({http.Client? client, String? baseUrl})
  // Use the given client, or make a new one.
      : _client = client ?? http.Client(),
  // Remember whether we made the client, so we know if we must close it.
        _ownsClient = client == null,
  // Check and store the server address.
        _baseUrl = ApiConfig.normalise(baseUrl ?? ApiConfig.baseUrl);

  // The object that sends the web requests.
  final http.Client _client;
  // True when this class created the client (so it should close it).
  final bool _ownsClient;
  // The server address, for example http://localhost:5250.
  final String _baseUrl;
  // Becomes true after close() so we stop sending requests.
  bool _closed = false;

  // Shuts the client down when we are finished with it.
  void close() {
    // Do nothing if it is already closed.
    if (_closed) return;
    // Remember that it is closed.
    _closed = true;
    // Only close the web client if we created it ourselves.
    if (_ownsClient) _client.close();
  }

  // Loads the list of issues, optionally only for one area, ward, category or status.
  Future<List<AreaIssue>> fetchIssues({
    // Only issues in this area.
    int? areaId,
    // Only issues in this ward.
    int? wardId,
    // Only issues in this category.
    String? category,
    // Only issues with this status.
    String? status,
  }) async {
    // Ask the server, adding to the address only the filters that were given.
    final decoded = await _getJson(ApiPaths.issues, {
      // Add ?areaId=... when an area was given.
      if (areaId != null) 'areaId': '$areaId',
      // Add wardId=... when a ward was given.
      if (wardId != null) 'wardId': '$wardId',
      // Add category=... when a category was given.
      if (category != null) 'category': category,
      // Add status=... when a status was given.
      if (status != null) 'status': status,
    });

    // The server should send a list; anything else is wrong.
    if (decoded is! List) {
      // Tell the caller the response was not what we expected.
      throw const IssuesApiException(
        // The message shown to the user.
        'The server returned an unexpected response.',
      );
    }

    // Convert the list of JSON items into AreaIssue objects.
    return decoded
    // Keep only the items that are JSON objects.
        .whereType<Map>()
    // Convert each one into an AreaIssue.
        .map((item) => AreaIssue.fromJson(Map<String, dynamic>.from(item)))
    // Put the results in a fixed list.
        .toList(growable: false);
  }

  // Loads the dashboard numbers, optionally only for one area or ward.
  Future<AreaStats> fetchStats({int? areaId, int? wardId}) async {
    // Ask the server, adding to the address only the filters that were given.
    final decoded = await _getJson(ApiPaths.issueStats, {
      // Add ?areaId=... when an area was given.
      if (areaId != null) 'areaId': '$areaId',
      // Add wardId=... when a ward was given.
      if (wardId != null) 'wardId': '$wardId',
    });

    // The server should send one JSON object; anything else is wrong.
    if (decoded is! Map) {
      // Tell the caller the response was not what we expected.
      throw const IssuesApiException(
        // The message shown to the user.
        'The server returned an unexpected response.',
      );
    }

    // Convert the JSON object into an AreaStats.
    return AreaStats.fromJson(Map<String, dynamic>.from(decoded));
  }

  // Sends a GET request and returns the decoded JSON from the answer.
  Future<Object?> _getJson(String path, Map<String, String> query) async {
    // Build the full web address.
    final uri = Uri.parse(
      // Server address plus the route, e.g. http://localhost:5250/api/Issues.
      '$_baseUrl$path',
      // Add the filters as ?key=value pairs (none if there are no filters).
    ).replace(queryParameters: query.isEmpty ? null : query);

    // Send the request and wait for the answer.
   // final response = await _send(uri);

    debugPrint('REQUEST: GET $uri');

    final response = await _send(uri);

    debugPrint('STATUS CODE: ${response.statusCode}');
    debugPrint('RESPONSE BODY: ${response.body}');

    // Any status outside 200-299 means the request failed.
    if (response.statusCode < 200 || response.statusCode >= 300) {
      // Turn the failure into a readable error.
      throw _exceptionFromResponse(response);
    }

    // Try to read the answer as JSON.
    try {
      // Convert the JSON text into Dart lists and maps.
      return jsonDecode(response.body);
      // If the text is not valid JSON...
    } on FormatException {
      // ...tell the caller the response could not be read.
      throw const IssuesApiException('The server returned an unreadable response.');
    }
  }

  // Sends the actual GET request and turns connection problems into readable errors.
  Future<http.Response> _send(Uri uri) async {
    // Do not send anything if the client was closed.
    if (_closed) {
      // Tell the caller why nothing was sent.
      throw const IssuesApiException('The issues client has been closed.');
    }

    // Try to send the request.
    try {
      // Return the server's answer.
      return await _client
      // Send a GET asking for JSON back.
          .get(uri, headers: const {'Accept': 'application/json'})
      // Give up if there is no answer within 20 seconds.
          .timeout(const Duration(seconds: 20));
      // No internet or the server cannot be reached.
    } on SocketException {
      // Throw an error with a friendly message.
      throw const IssuesApiException(
        // The message shown to the user.
        'Could not connect to the server. Check your internet connection.',
      );
      // Some other network problem happened.
    } on http.ClientException {
      // Throw an error with a friendly message.
      throw const IssuesApiException(
        // The message shown to the user.
        'A network error occurred while contacting the server.',
      );
      // The server took too long to answer.
    } on TimeoutException {
      // Throw an error with a friendly message.
      throw const IssuesApiException(
        // The message shown to the user.
        'The server took too long to respond. Please try again.',
      );
    }
  }

  // Turns a failed server answer into an IssuesApiException with a useful message.
  IssuesApiException _exceptionFromResponse(http.Response response) {
    // Start with a general message (a different one for server faults, 500 and above).
    var message = response.statusCode >= 500
    // Message for server problems.
        ? 'The server had a problem. Please try again later.'
    // Message for other failures.
        : 'The request failed. Please try again.';

    // The text the server sent back, without extra spaces.
    final body = response.body.trim();
    // Look for a better message in the body, except for server faults.
    if (body.isNotEmpty && response.statusCode < 500) {
      // Try to read the body as JSON.
      try {
        // Convert the JSON text into Dart lists and maps.
        final decoded = jsonDecode(body);
        // The body is a JSON object.
        if (decoded is Map) {
          // Pick the first of message, detail or title that exists.
          final text = decoded['message'] ?? decoded['detail'] ?? decoded['title'];
          // Use it as our message.
          if (text != null) message = text.toString();
          // The body is a JSON string such as "Area not found".
        } else if (decoded is String && decoded.isNotEmpty) {
          // Use that text as our message.
          message = decoded;
        }
        // If the body is not JSON at all...
      } on FormatException {
        // Plain-text body such as "Area not found". Ignore HTML error pages.
        // ...use it as the message if it is short and not an HTML page.
        if (!body.startsWith('<') && body.length <= 200) message = body;
      }
    }

    // Return the error with our message and the status code.
    return IssuesApiException(message, statusCode: response.statusCode);
  }
}
