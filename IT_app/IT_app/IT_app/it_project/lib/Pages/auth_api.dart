import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_paths.dart';

class AuthApiException implements Exception {
  final String message;
  final int? statusCode;

  // Machine-readable reason sent by the backend, for example
  // 'email_not_verified'. Null when the backend sent plain text.
  final String? code;

  const AuthApiException(
      this.message, {
        this.statusCode,
        this.code,
      });

  bool get isEmailNotVerified => code == 'email_not_verified';

  // Set by the app when the saved login can no longer be used and the
  // user has to log in again.
  bool get isSessionExpired => code == 'session_expired';

  @override
  String toString() => message;
}

class AuthApi {
  AuthApi({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null,
        _baseUrl = _normaliseBaseUrl(baseUrl ?? _configuredBaseUrl());

  // Override with --dart-define=API_BASE_URL=https://... for a real phone
  // or for the hosted API.
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String _configuredBaseUrl() {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;

    // The Android emulator reaches the PC through 10.0.2.2.
    return Platform.isAndroid
        ? 'http://10.0.2.2:5250'
        : 'http://localhost:5250';
  }

  final http.Client _client;
  final bool _ownsClient;
  final String _baseUrl;

  bool _closed = false;

  void close() {
    if (_closed) return;
    _closed = true;

    if (_ownsClient) {
      _client.close();
    }
  }

  // REGISTER
  // Backend: POST /api/Auth/register
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required int areaId,
  }) {
    return _post(
      ApiPaths.registerAccount,
      {
        'fullName': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'areaId': areaId,
      },
      acceptedStatuses: {200, 201},
    );
  }

  // LOGIN
  // Backend: POST /api/Auth/login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) {
    return _post(
      '/api/Auth/login',
      {
        'email': email.trim().toLowerCase(),
        'password': password,
      },
      acceptedStatuses: {200},
    );
  }

  // CONFIRM EMAIL
  // Backend: GET /api/Auth/confirm-email?userId=...&token=...
  Future<String> confirmEmail({
    required String userId,
    required String token,
  }) async {
    final uri = _endpoint('/api/Auth/confirm-email').replace(
      queryParameters: {
        'userId': userId,
        'token': token,
      },
    );

    final response = await _send(
          () => _client.get(
        uri,
        headers: _headers(),
      ),
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw _exceptionFromResponse(response);
    }

    return _responseMessage(response);
  }

  // RESEND EMAIL CONFIRMATION
  // Backend: POST /api/Auth/resend-confirmation
  Future<String> resendEmailConfirmation({
    required String email,
  }) async {
    final response = await _send(
          () => _client.post(
        _endpoint('/api/Auth/resend-confirmation'),
        headers: _headers(),
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
        }),
      ),
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw _exceptionFromResponse(response);
    }

    return _responseMessage(response);
  }

  // Compatibility method for existing pages that call
  // resendEmailVerification(email: email).
  Future<String> resendEmailVerification({
    required String email,
  }) {
    return resendEmailConfirmation(email: email);
  }

  // REFRESH TOKEN
  // Backend: POST /api/Auth/refresh
  Future<Map<String, dynamic>> refreshToken({
    required String refreshToken,
  }) {
    return _post(
      '/api/Auth/refresh',
      {
        'refreshToken': refreshToken,
      },
      acceptedStatuses: {200},
    );
  }

  // LOGOUT
  // Backend: POST /api/Auth/logout
  // Requires the access token in the Authorization header.
  Future<void> logout({
    required String refreshToken,
    required String accessToken,
  }) async {
    await _post(
      '/api/Auth/logout',
      {
        'refreshToken': refreshToken,
      },
      acceptedStatuses: {200, 204},
      accessToken: accessToken,
    );
  }

  // CURRENT USER
  // Backend: GET /api/Auth/me
  Future<Map<String, dynamic>> getCurrentUser({
    required String accessToken,
  }) async {
    final response = await _send(
          () => _client.get(
        _endpoint('/api/Auth/me'),
        headers: _headers(accessToken: accessToken),
      ),
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw _exceptionFromResponse(response);
    }

    return _decodeJsonObject(response);
  }

  // CREATE REPORT
  // Backend: POST /api/Reports
  // Uses multipart form data because the backend accepts an optional image.
  Future<Map<String, dynamic>> createReport({
    required String accessToken,
    required String issueCategory,
    required String issueType,
    required int areaId,
    required String location,
    required double latitude,
    required double longitude,
    String description = '',
    String? imagePath,
  }) async {
    // CHANGE: MultipartRequest allows the report and image to be sent together.
    final request = http.MultipartRequest(
      'POST',
      _endpoint('/api/Reports'),
    );

    // CHANGE: Do not set Content-Type to application/json for multipart data.
    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
    });

    request.fields.addAll({
      'IssueCategory': issueCategory,
      'IssueType': issueType,
      'AreaId': areaId.toString(),
      'Location': location,
      'Latitude': latitude.toString(),
      'Longitude': longitude.toString(),
      'Description': description,
    });

    // CHANGE: Attach the image only when the user selected one.
    if (imagePath != null && imagePath.trim().isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath('Image', imagePath),
      );
    }

    // CHANGE: Reuse the existing HTTP client, timeout and error handling.
    final response = await _send(
          () async => http.Response.fromStream(
        await _client.send(request),
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _exceptionFromResponse(response);
    }

    return _decodeJsonObject(response);
  }



  // UPDATE REPORT
  // Backend: PUT /api/Reports/{id}
  // Uses multipart form data because the backend accepts an optional image.
  Future<Map<String, dynamic>> updateReport({
    required int reportId,
    required String accessToken,
    required String issueCategory,
    required String issueType,
    required int areaId,
    required String location,
    required double latitude,
    required double longitude,
    String description = '',
    String? imagePath,
  }) async {
    final request = http.MultipartRequest(
      'PUT',
      _endpoint('/api/Reports/$reportId'),
    );

    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
    });

    request.fields.addAll({
      'IssueCategory': issueCategory,
      'IssueType': issueType,
      'AreaId': areaId.toString(),
      'Location': location,
      'Latitude': latitude.toString(),
      'Longitude': longitude.toString(),
      'Description': description,
    });

    if (imagePath != null && imagePath.trim().isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath('Image', imagePath),
      );
    }

    final response = await _send(
          () async => http.Response.fromStream(
        await _client.send(request),
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _exceptionFromResponse(response);
    }

    return _decodeJsonObject(response);
  }



  // DELETE REPORT
  // Backend: DELETE /api/Reports/{id}
  Future<void> deleteReport({
    required int reportId,
    required String accessToken,
  }) async {
    final response = await _send(
          () => _client.delete(
        _endpoint('/api/Reports/$reportId'),
        headers: _headers(accessToken: accessToken),
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _exceptionFromResponse(response);
    }
  }



  // UPDATE NAME
  // Backend: PUT /api/Users/profile
  Future<Map<String, dynamic>> updateFullName({
    required String accessToken,
    required String fullName,
  }) {
    return _putJson(
      '/api/Users/profile',
      {
        'fullName': fullName.trim(),
      },
      accessToken: accessToken,
    );
  }

  // CHANGE EMAIL (step 1)
  // Backend: POST /api/Users/change-email
  // Sends a confirmation link to the NEW address. The email only changes
  // after the link is clicked.
  Future<String> requestEmailChange({
    required String accessToken,
    required String newEmail,
    required String currentPassword,
  }) async {
    final response = await _send(
          () => _client.post(
        _endpoint('/api/Users/change-email'),
        headers: _headers(accessToken: accessToken),
        body: jsonEncode({
          'newEmail': newEmail.trim().toLowerCase(),
          'currentPassword': currentPassword,
        }),
      ),
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw _exceptionFromResponse(response);
    }

    return _responseMessage(response);
  }

  // CHANGE PASSWORD
  // Backend: PUT /api/Auth/change-password
  // The backend ends every session when this succeeds.
  Future<String> changePassword({
    required String accessToken,
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _send(
          () => _client.put(
        _endpoint('/api/Auth/change-password'),
        headers: _headers(accessToken: accessToken),
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      ),
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw _exceptionFromResponse(response);
    }

    return _responseMessage(response);
  }

  // FORGOT PASSWORD
  // Backend: POST /api/Auth/forgot-password
  Future<String> forgotPassword({
    required String email,
  }) async {
    final response = await _send(
          () => _client.post(
        _endpoint('/api/Auth/forgot-password'),
        headers: _headers(),
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
        }),
      ),
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw _exceptionFromResponse(response);
    }

    return _responseMessage(response);
  }

  // RESET PASSWORD
  // Backend: POST /api/Auth/reset-password
  Future<String> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    final response = await _send(
          () => _client.post(
        _endpoint('/api/Auth/reset-password'),
        headers: _headers(),
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'token': token,
          'newPassword': newPassword,
        }),
      ),
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw _exceptionFromResponse(response);
    }

    return _responseMessage(response);
  }

  // Shared POST helper for endpoints returning JSON objects.
  Future<Map<String, dynamic>> _post(
      String path,
      Map<String, Object?> body, {
        required Set<int> acceptedStatuses,
        String? accessToken,
      }) async {
    final response = await _send(
          () => _client.post(
        _endpoint(path),
        headers: _headers(accessToken: accessToken),
        body: jsonEncode(body),
      ),
    );

    if (!acceptedStatuses.contains(response.statusCode)) {
      throw _exceptionFromResponse(response);
    }

    if (response.statusCode == 204 ||
        response.body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    return _decodeJsonObject(response);
  }

  // Shared PUT helper for endpoints returning JSON objects.
  Future<Map<String, dynamic>> _putJson(
      String path,
      Map<String, Object?> body, {
        String? accessToken,
      }) async {
    final response = await _send(
          () => _client.put(
        _endpoint(path),
        headers: _headers(accessToken: accessToken),
        body: jsonEncode(body),
      ),
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw _exceptionFromResponse(response);
    }

    return _decodeJsonObject(response);
  }

  Map<String, String> _headers({
    String? accessToken,
  }) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };
  }

  Uri _endpoint(String path) {
    final normalisedPath =
    path.startsWith('/') ? path : '/$path';

    return Uri.parse('$_baseUrl$normalisedPath');
  }

  static String _normaliseBaseUrl(String value) {
    final trimmed = value.trim();
    final uri = Uri.tryParse(trimmed);

    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw ArgumentError(
        'Invalid API base URL. Use a URL such as '
            'http://localhost:5231 or https://your-api.example.com.',
      );
    }

    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  Future<http.Response> _send(
      Future<http.Response> Function() request,
      ) async {
    if (_closed) {
      throw const AuthApiException(
        'The authentication API client has already been closed.',
      );
    }

    try {
      return await request().timeout(
        const Duration(seconds: 20),
      );
    } on SocketException {
      throw const AuthApiException(
        'Could not connect to the server. Check that the backend is '
            'running and that the API URL is correct.',
      );
    } on http.ClientException {
      throw const AuthApiException(
        'A network error occurred while contacting the server.',
      );
    } on TimeoutException {
      throw const AuthApiException(
        'The server took too long to respond. Please try again.',
      );
    }
  }

  Map<String, dynamic> _decodeJsonObject(
      http.Response response,
      ) {
    final body = response.body.trim();

    if (body.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      throw const AuthApiException(
        'The server returned an unexpected response format.',
      );
    } on FormatException {
      throw const AuthApiException(
        'The server returned an unreadable response.',
      );
    }
  }

  String _responseMessage(http.Response response) {
    final body = response.body.trim();

    if (body.isEmpty) {
      return 'Request completed successfully.';
    }

    try {
      final decoded = jsonDecode(body);

      if (decoded is Map) {
        final message =
            decoded['message'] ?? decoded['Message'];

        if (message != null) {
          return message.toString();
        }

        return body;
      }

      return decoded.toString();
    } on FormatException {
      // The backend may return plain text rather than JSON.
      return body;
    }
  }

  AuthApiException _exceptionFromResponse(
      http.Response response,
      ) {
    String message = 'The request failed. Please try again.';
    String? code;
    final body = response.body.trim();

    if (body.isNotEmpty) {
      try {
        final decoded = jsonDecode(body);

        if (decoded is Map) {
          code = decoded['code']?.toString();

          final serverMessage =
              decoded['message'] ?? decoded['Message'];
          final validationMessages =
          _validationMessages(decoded['errors']);

          if (serverMessage != null) {
            message = serverMessage.toString();
          } else if (validationMessages.isNotEmpty) {
            message = validationMessages.join('\n');
          } else if (decoded['detail'] != null) {
            message = decoded['detail'].toString();
          } else if (decoded['title'] != null) {
            message = decoded['title'].toString();
          }
        } else if (decoded is List) {
          // Identity errors come back as a list of strings,
          // for example ["Passwords must have at least one digit."].
          final items = decoded
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList();

          if (items.isNotEmpty) {
            message = items.join('\n');
          }
        } else {
          message = decoded.toString();
        }
      } on FormatException {
        // Plain text body such as "Invalid email or password".
        // An HTML error page is not worth showing to the user.
        final looksLikeHtml = body.startsWith('<') || body.length > 300;
        if (!looksLikeHtml) {
          message = body;
        }
      }
    }

    if (response.statusCode == 401) {
      message = body.isEmpty
          ? 'Your session is invalid or your email has not been confirmed.'
          : message;
    } else if (response.statusCode == 429) {
      message = body.isEmpty
          ? 'Too many attempts. Please wait before trying again.'
          : message;
    } else if (response.statusCode >= 500 && body.isEmpty) {
      message = 'A server error occurred. Please try again later.';
    }

    return AuthApiException(
      message,
      statusCode: response.statusCode,
      code: code,
    );
  }

  List<String> _validationMessages(Object? errors) {
    if (errors is! Map) return const [];

    final messages = <String>[];

    for (final value in errors.values) {
      if (value is List) {
        messages.addAll(value.map((item) => item.toString()));
      } else if (value != null) {
        messages.add(value.toString());
      }
    }

    return messages;
  }
}