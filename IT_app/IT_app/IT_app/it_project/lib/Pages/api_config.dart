
// checks the phones operating system.
import 'dart:io';

// stores the backend server address.
class ApiConfig {
  // prevents creating objects of this class.
  const ApiConfig._();

  // reads a custom server address if provided.
  static const String _envBaseUrl =
  String.fromEnvironment('API_BASE_URL');

  // sets the local development port.
  static const int _devPort = 5250;

  // returns the server address used by the app.
  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) return normalise(_envBaseUrl);

      return 'https://municipalreportingapi.runasp.net';

  }

  // checks and formats the server address.
  static String normalise(String value) {
    final trimmed = value.trim();
    final uri = Uri.tryParse(trimmed);

    // checks that the address is valid.
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw ArgumentError(
        'Invalid API base URL. Use a URL such as '
            'http://localhost:5250 or https://your-api.example.com.',
      );
    }

    // removes the trailing slash if present.
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  // converts uploaded photo paths into full URLs.
  static String? resolveUrl(String? path, {String? baseUrl}) {
    final value = path?.trim() ?? '';
    if (value.isEmpty) return null;

    // returns the address if it is already complete.
    if (value.startsWith('http://') ||
        value.startsWith('https://')) {
      return value;
    }

    // combines the server address with the photo path.
    final base = normalise(baseUrl ?? ApiConfig.baseUrl);
    return value.startsWith('/')
        ? '$base$value'
        : '$base/$value';
  }
}
