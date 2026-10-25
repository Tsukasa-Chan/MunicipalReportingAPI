import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Keeps the refresh token in the phone's secure storage so the user stays
// logged in after the app is closed. Nothing else is saved here.
class SessionStorage {
  static const _refreshTokenKey = 'refresh_token';
  static final _storage = FlutterSecureStorage();

  static Future<String?> readRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (_) {
      // Storage not available (for example in a unit test).
      return null;
    }
  }

  static Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: token);
    } catch (_) {
      // If saving fails, the user just has to log in next time.
    }
  }

  static Future<void> clear() async {
    try {
      await _storage.delete(key: _refreshTokenKey);
    } catch (_) {
      // The token is revoked on the server at logout, so a leftover copy
      // cannot be used again.
    }
  }
}