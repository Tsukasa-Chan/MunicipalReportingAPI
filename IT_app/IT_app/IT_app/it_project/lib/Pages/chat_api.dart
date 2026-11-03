import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'api_paths.dart';
import 'auth_api.dart';
import 'issues_api.dart';

class ChatMessage {
  const ChatMessage({required this.role, required this.content});
  final String role;
  final String content;

  Map<String, String> toJson() => {'role': role, 'content': content};
}

class ReportDraft {

  // create a draft.
  const ReportDraft({
    required this.category,
    required this.issueType,
    required this.location,
    this.description = '',
  });

  final String category;
  final String issueType;

  // location as to where the problem is.
  final String location;
  final String description;

  String get categoryLabel => IssueCategories.label(category);
  String get issueTypeLabel => humanizeEnumName(issueType);

  // reads the server's reportDraft object.
  factory ReportDraft.fromJson(Map<String, dynamic> json) => ReportDraft(

    category: (json['issueCategory'] ?? '').toString(),
    issueType: (json['issueType'] ?? '').toString(),
    location: (json['location'] ?? '').toString(),
    description: (json['description'] ?? '').toString(),
  );
}

// the assistant's answer.
class ChatReply {

  // creates a reply.
  const ChatReply({required this.reply, this.draft});
  final String reply;

  // prepared report.
  final ReportDraft? draft;
}

// error to appear for the chat screen.
class ChatApiException implements Exception {

  // create the error.
  const ChatApiException(this.message, {this.statusCode});

  // message the user should read.
  final String message;

  // HTTP status code.
  final int? statusCode;

  // print message.
  @override
  String toString() => message;
}

// class for chat API.
class ChatApi {

  // pass a client and baseUrl in tests; the app uses the defaults.
  ChatApi({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _ownsClient = client == null,

  // use given address or the apps default.
        _baseUrl = ApiConfig.normalise(baseUrl ?? ApiConfig.baseUrl);

  final http.Client _client;
  final bool _ownsClient;
  final String _baseUrl;

  // frees client when we are finished.
  void close() {

    // only close a client we created.
    if (_ownsClient) _client.close();
  }

  // sends conversation and returns the assistants answer.
  Future<ChatReply> send(String accessToken, List<ChatMessage> messages) async {

    // post messages as JSON, with the login token.
    final response = await _send(
          () => _client.post(

        // chat address.
        Uri.parse('$_baseUrl${ApiPaths.chat}'),
        headers: _headers(accessToken),
        body: jsonEncode({'messages': messages.map((m) => m.toJson()).toList()}),
      ),
    );

    // turn failures into exceptions.
    _throwIfFailed(response);

    // read JSON answer.
    final json = _decodeObject(response);
    final rawDraft = json['reportDraft'];

    // build reply.
    return ChatReply(
      reply: (json['reply'] ?? '').toString(),

      // draft, when the server sent an object.
      draft: rawDraft is Map
          ? ReportDraft.fromJson(Map<String, dynamic>.from(rawDraft))
          : null,
    );
  }

  // submit a confirmed draft as a real report.
  Future<bool> submitReport({
    required String accessToken,
    required int areaId,
    required ReportDraft draft,
    required double latitude,
    required double longitude,
  }) async {

    // reports endpoint takes a multipart form, it also accepts a photo.
    final request = http.MultipartRequest(
      'POST',

      // reports address.
      Uri.parse('$_baseUrl${ApiPaths.reports}'),
    )
    // login token.
      ..headers['Authorization'] = 'Bearer $accessToken'
      ..headers['Accept'] = 'application/json'

    // form field for backend.
      ..fields.addAll({
        'IssueCategory': draft.category,
        'IssueType': draft.issueType,
        'AreaId': '$areaId',
        'Location': draft.location,
        'Latitude': '$latitude',
        'Longitude': '$longitude',
        'Description': draft.description,
      });

    // send it, then read the whole response.
    final response = await _send(
          () async => http.Response.fromStream(await _client.send(request)),
    );

    // turn failures into exceptions.
    _throwIfFailed(response);

    // backend says whether the report joined an existing issue.
    return _decodeObject(response)['joinedExistingIssue'] == true;
  }

  // headers for a JSON request from a signed-in user.
  Map<String, String> _headers(String accessToken) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $accessToken',
  };

  // runs a request and turns network problems into readable errors.
  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(const Duration(seconds: 60));
    } on SocketException {
      throw const ChatApiException(
        'We cannot connect to the server. Please check your internet.',
      );
    } on http.ClientException {

      // network failure.
      throw const ChatApiException(
        'A network error has occurred while connecting to the server.',
      );
    } on TimeoutException {

      // too slow.
      throw const ChatApiException(
        'The assistant is taking too long to respond. Please try again.',
      );
    }
  }

  // if no response.
  void _throwIfFailed(http.Response response) {

    if (response.statusCode >= 200 && response.statusCode < 300) return;

    // 401 means the login token has expired.
    if (response.statusCode == 401) {
      throw const AuthApiException('Your session has expired.', statusCode: 401);
    }

    // default message for failures.
    var message = response.statusCode >= 500 && response.statusCode != 503
        ? 'The server had experienced a problem. Please try again later.'
        : 'The request has failed. Please try again.';

    final body = response.body.trim();

    if (body.isNotEmpty) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map && decoded['message'] != null) {
          message = decoded['message'].toString();

        } else if (decoded is String && decoded.isNotEmpty) {
          message = decoded;
        }

      } on FormatException {

        // not JSON: use short plain text.
        if (!body.startsWith('<') && body.length <= 200) message = body;
      }
    }

    // report the problem with its status code.
    throw ChatApiException(message, statusCode: response.statusCode);
  }

  // reads a JSON object from the response.
  Map<String, dynamic> _decodeObject(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } on FormatException {
    }

    // server sent something unexpected.
    throw const ChatApiException('The server returned an unexpected response.');
  }
}
