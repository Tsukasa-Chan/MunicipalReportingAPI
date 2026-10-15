import 'dart:async';

import 'auth_api.dart';
import 'session_storage.dart';

class UserAccount {
  const UserAccount({
    required this.name,
    required this.surname,
    required this.username,
    required this.email,
    required this.password,
    this.communityArea = '',
    this.supervisorIssueType,
    this.isAdmin = false,
    this.isWorker = false,
    this.isSupervisor = false,
    this.isVerified = false,
  });

  final String name;
  final String surname;
  final String username;
  final String email;
  final String password;
  final String communityArea;
  final String? supervisorIssueType;
  final bool isAdmin;
  final bool isWorker;
  final bool isSupervisor;
  final bool isVerified;

  bool get isStaff => isWorker || isSupervisor;
  String get fullName => '$name $surname'.trim();
  String get ward => communityArea.isEmpty ? 'Not set' : communityArea;

  UserAccount copyWith({
    String? name,
    String? surname,
    String? username,
    String? email,
    String? password,
    String? communityArea,
    String? supervisorIssueType,
    bool? isAdmin,
    bool? isWorker,
    bool? isSupervisor,
    bool? isVerified,
  }) {
    return UserAccount(
      name: name ?? this.name,
      surname: surname ?? this.surname,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      communityArea: communityArea ?? this.communityArea,
      supervisorIssueType: supervisorIssueType ?? this.supervisorIssueType,
      isAdmin: isAdmin ?? this.isAdmin,
      isWorker: isWorker ?? this.isWorker,
      isSupervisor: isSupervisor ?? this.isSupervisor,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}

enum _RefreshResult { refreshed, sessionEnded, unavailable }

class AuthStore {
  // Wards and areas for the register dropdowns. The area ids used when
  // registering match the areas seeded in the backend.
  static const wardAreas = <int, List<String>>{
    58: [
      'Brake Village',
      'Canelands',
      'Casuarina',
      'Desainagar',
      'Ghandinagar',
      'Hammonds Farm',
      'King Shaka International Airport zone',
      'La Mercy',
      'Lungelani',
      'Pholani',
      'Sastri Circle / Belgate',
      'Thuthukani',
      'Tongaat Beach / Westbrook',
    ],
    61: [
      'Belvedere (including Belvedere North)',
      'Buffelsdale',
      'Chelmsford Heights',
      'Emona Sunhill',
      'Gwalas Farm',
      'Mithangar',
      'Plain Street',
      'Sandfields',
      'Umbhayi',
      'Watsonia',
    ],
    62: [
      'Burbreeze',
      'Fairbreeze',
      'Flamingo Heights',
      'Gandhi’s Hill',
      'Hambanathi',
      'Lauriston',
      'Magwaveni',
      'Maidstone Village',
      'OThongathi CBD / Tongaat Central',
      'Riverside AH',
      'Tongaat Industrial / Trurolands',
      'Vanrova',
    ],
  };

  // Empty on start. A user only exists here after signIn() succeeds with
  // the backend's response (workers added by a supervisor are local for now).
  static final Map<String, UserAccount> _users = {};
  static final Map<String, List<String>> _savedAreas = {};
  static String? _currentUsername;

  // Session tokens from the backend. The access token stays in memory only.
  // The refresh token is also saved in secure storage (SessionStorage) so
  // the user stays logged in after the app is closed.
  static String? _accessToken;
  static String? _refreshToken;

  // Set while a logout is still deleting the saved token, so the startup
  // check never reads a token that is about to be removed.
  static Future<void>? _pendingClear;

  // Set while a token refresh is running, so two requests never refresh at
  // the same time (the backend swaps the refresh token on every use).
  static Future<_RefreshResult>? _refreshInFlight;

  static String? get accessToken => _accessToken;
  static String? get refreshToken => _refreshToken;
  static bool get isSignedIn =>
      _currentUsername != null && _accessToken != null;

  static UserAccount? get currentUser {
    final username = _currentUsername;
    return username == null ? null : _users[username];
  }

  static (String, String) _splitName(String fullName, String fallbackEmail) {
    final trimmed = fullName.trim();
    final parts = trimmed.isEmpty ? <String>[] : trimmed.split(RegExp(r'\s+'));

    final first = parts.isEmpty ? fallbackEmail.split('@').first : parts.first;
    final last = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    return (first, last);
  }

  // Turns the backend's GET /api/Auth/me response into a user.
  // The password is never kept on the device.
  static UserAccount _accountFromProfile(Map<String, dynamic> profile) {
    final email = (profile['email'] ?? '').toString().trim().toLowerCase();
    final fullName = (profile['fullName'] ?? '').toString();
    final role = (profile['role'] ?? 'User').toString();
    final areaName = (profile['areaName'] ?? '').toString().trim();

    final (name, surname) = _splitName(fullName, email);

    // Roles in the backend: User, Admin, Supervisor.
    // An admin also uses the supervisor screens.
    final isAdmin = role == 'Admin';
    final isSupervisor = role == 'Supervisor' || isAdmin;

    // The backend uses the email as the username.
    return UserAccount(
      name: name,
      surname: surname,
      username: email,
      email: email,
      password: '',
      communityArea: areaName,
      isAdmin: isAdmin,
      isSupervisor: isSupervisor,
      isVerified: profile['emailConfirmed'] == true,
    );
  }

  static void signIn({
    required Map<String, dynamic> profile,
    required String accessToken,
    required String refreshToken,
  }) {
    final account = _accountFromProfile(profile);

    _users[account.username] = account;
    _currentUsername = account.username;
    _accessToken = accessToken;
    _refreshToken = refreshToken;

    // Remember the login for next time the app opens.
    unawaited(SessionStorage.saveRefreshToken(refreshToken));
  }

  // Called when the app starts. If a refresh token was saved, trade it for
  // a new session with the backend. Returns true when the user is signed in
  // and the dashboard can open straight away.
  static Future<bool> restoreSession() async {
    final pending = _pendingClear;
    if (pending != null) {
      await pending;
    }

    if (isSignedIn) return true;

    final savedRefreshToken = await SessionStorage.readRefreshToken();
    if (savedRefreshToken == null || savedRefreshToken.isEmpty) {
      return false;
    }

    final api = AuthApi();
    try {
      final tokens = await api.refreshToken(refreshToken: savedRefreshToken);

      final newAccessToken = tokens['token']?.toString() ?? '';
      final newRefreshToken = tokens['refreshToken']?.toString() ?? '';

      if (newAccessToken.isEmpty || newRefreshToken.isEmpty) {
        return false;
      }

      // The backend swaps the refresh token every time it is used, so the
      // new one must be saved straight away.
      await SessionStorage.saveRefreshToken(newRefreshToken);

      final profile = await api.getCurrentUser(accessToken: newAccessToken);

      signIn(
        profile: profile,
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );

      return true;
    } on AuthApiException catch (error) {
      // 401 means the saved login is no longer valid (expired or logged out).
      // Any other error, like no internet, keeps the token for next time.
      if (error.statusCode == 401) {
        await SessionStorage.clear();
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      api.close();
    }
  }

  // Swaps the refresh token for a new access token while the app is open.
  static Future<_RefreshResult> _refreshAccessToken() {
    final running = _refreshInFlight;
    if (running != null) return running;

    final future = _doRefresh();
    _refreshInFlight = future;

    return future.whenComplete(() {
      _refreshInFlight = null;
    });
  }

  static Future<_RefreshResult> _doRefresh() async {
    final refresh = _refreshToken;
    if (refresh == null) return _RefreshResult.sessionEnded;

    final api = AuthApi();
    try {
      final tokens = await api.refreshToken(refreshToken: refresh);

      final newAccessToken = tokens['token']?.toString() ?? '';
      final newRefreshToken = tokens['refreshToken']?.toString() ?? '';

      if (newAccessToken.isEmpty || newRefreshToken.isEmpty) {
        return _RefreshResult.unavailable;
      }

      _accessToken = newAccessToken;
      _refreshToken = newRefreshToken;
      await SessionStorage.saveRefreshToken(newRefreshToken);

      return _RefreshResult.refreshed;
    } on AuthApiException catch (error) {
      return error.statusCode == 401
          ? _RefreshResult.sessionEnded
          : _RefreshResult.unavailable;
    } catch (_) {
      return _RefreshResult.unavailable;
    } finally {
      api.close();
    }
  }

  // Runs an API call that needs the access token. If the server says the
  // token has expired (401), the session is refreshed and the call is tried
  // once more. If the session cannot be refreshed, the user is logged out
  // and an exception with isSessionExpired = true is thrown.
  static Future<T> withAccessToken<T>(
      Future<T> Function(AuthApi api, String accessToken) call,
      ) async {
    const expired = AuthApiException(
      'Your session has expired. Please log in again.',
      statusCode: 401,
      code: 'session_expired',
    );

    final token = _accessToken;
    if (token == null) throw expired;

    final api = AuthApi();
    try {
      try {
        return await call(api, token);
      } on AuthApiException catch (error) {
        if (error.statusCode != 401) rethrow;
      }

      final result = await _refreshAccessToken();

      if (result == _RefreshResult.sessionEnded) {
        logout();
        throw expired;
      }

      if (result == _RefreshResult.unavailable) {
        throw const AuthApiException(
          'Could not refresh your session. Check your connection and try again.',
        );
      }

      try {
        return await call(api, _accessToken!);
      } on AuthApiException catch (error) {
        if (error.statusCode == 401) {
          logout();
          throw expired;
        }
        rethrow;
      }
    } finally {
      api.close();
    }
  }

  // Loads the latest profile from the backend.
  static Future<void> reloadProfile() async {
    if (!isSignedIn) return;

    final profile = await withAccessToken(
          (api, token) => api.getCurrentUser(accessToken: token),
    );

    final account = _accountFromProfile(profile);

    if (account.username == _currentUsername) {
      _users[account.username] = account;
    }
  }

  static Future<void> updateFullName(String fullName) async {
    final result = await withAccessToken(
          (api, token) => api.updateFullName(
        accessToken: token,
        fullName: fullName,
      ),
    );

    final username = _currentUsername;
    if (username == null) return;

    final existing = _users[username];
    if (existing == null) return;

    final savedName = (result['fullName'] ?? fullName).toString();
    final (name, surname) = _splitName(savedName, existing.email);

    _users[username] = existing.copyWith(name: name, surname: surname);
  }

  // Step 1 of an email change. The backend emails a link to the new address,
  // and the email only changes after the link is clicked.
  static Future<String> requestEmailChange({
    required String newEmail,
    required String currentPassword,
  }) {
    return withAccessToken(
          (api, token) => api.requestEmailChange(
        accessToken: token,
        newEmail: newEmail,
        currentPassword: currentPassword,
      ),
    );
  }

  // The backend ends every session when the password changes, so the user
  // is logged out here and has to log in again with the new password.
  static Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final message = await withAccessToken(
          (api, token) => api.changePassword(
        accessToken: token,
        currentPassword: currentPassword,
        newPassword: newPassword,
      ),
    );

    logout();
    return message;
  }

  // Clears the local session straight away, deletes the saved token, and
  // tells the backend in the background so the tokens are revoked.
  static void logout() {
    final access = _accessToken;
    final refresh = _refreshToken;

    _currentUsername = null;
    _accessToken = null;
    _refreshToken = null;

    _pendingClear = SessionStorage.clear();

    if (access != null && refresh != null) {
      unawaited(_revokeOnServer(access, refresh));
    }
  }

  static Future<void> _revokeOnServer(String access, String refresh) async {
    final api = AuthApi();
    try {
      await api.logout(refreshToken: refresh, accessToken: access);
    } catch (_) {
      // The local session is already cleared. If the server could not be
      // reached, the tokens simply expire on their own.
    } finally {
      api.close();
    }
  }

  static List<String> get savedAreas {
    final username = _currentUsername;
    if (username == null) {
      return const [];
    }
    return List.unmodifiable(_savedAreas[username] ?? const []);
  }

  static bool addSavedArea(String area) {
    final username = _currentUsername;
    final cleanArea = area.trim();
    if (username == null || cleanArea.isEmpty) {
      return false;
    }
    final areas = _savedAreas.putIfAbsent(username, () => []);
    if (areas.any(
          (savedArea) => savedArea.toLowerCase() == cleanArea.toLowerCase(),
    )) {
      return false;
    }
    areas.add(cleanArea);
    return true;
  }

  static void removeSavedArea(String area) {
    final username = _currentUsername;
    if (username == null) {
      return;
    }
    _savedAreas[username]?.remove(area);
  }

  static void updateCommunityArea(String area) {
    final username = _currentUsername;
    final cleanArea = area.trim();
    if (username == null || cleanArea.isEmpty) {
      return;
    }

    final existing = _users[username];
    if (existing == null) {
      return;
    }

    _users[username] = existing.copyWith(communityArea: cleanArea);
  }

  static bool emailExists(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    return _users.values.any(
          (user) => user.email.toLowerCase() == normalizedEmail,
    );
  }

  static UserAccount? findUser(String username) {
    return _users[username.trim()];
  }

  static bool canSuperviseIssue({
    required String supervisorUsername,
    required String issueType,
  }) {
    final supervisor = findUser(supervisorUsername);
    final responsibility = supervisor?.supervisorIssueType?.trim().toLowerCase();
    if (supervisor?.isSupervisor != true ||
        responsibility == null ||
        responsibility.isEmpty) {
      return supervisor?.isSupervisor == true;
    }
    final normalizedIssueType = issueType.trim().toLowerCase();
    return switch (responsibility) {
      'electricity' => normalizedIssueType.contains('electric'),
      'water' || 'water and sanitation' =>
          normalizedIssueType.contains('water'),
      'road' || 'roads and stormwater' => normalizedIssueType.contains('road'),
      _ => normalizedIssueType == responsibility,
    };
  }

  static List<UserAccount> get workers =>
      _users.values.where((user) => user.isWorker).toList(growable: false);

  static bool addWorker({
    required String name,
    required String surname,
    required String username,
    required String email,
    required String password,
  }) {
    if (currentUser?.isSupervisor != true && currentUser?.isAdmin != true) {
      return false;
    }

    final cleanUsername = username.trim();
    final normalizedEmail = email.trim().toLowerCase();
    if (name.trim().isEmpty ||
        surname.trim().isEmpty ||
        cleanUsername.isEmpty ||
        _users.containsKey(cleanUsername) ||
        normalizedEmail.isEmpty ||
        emailExists(normalizedEmail) ||
        password.isEmpty) {
      return false;
    }

    _users[cleanUsername] = UserAccount(
      name: name.trim(),
      surname: surname.trim(),
      username: cleanUsername,
      email: email.trim(),
      password: password,
      isWorker: true,
      isVerified: true,
    );
    return true;
  }

  static void updateCurrentUser({
    required String name,
    required String surname,
    required String email,
  }) {
    final username = _currentUsername;
    if (username == null) {
      return;
    }

    final existing = _users[username];
    if (existing == null) {
      return;
    }

    _users[username] = existing.copyWith(
      name: name.trim(),
      surname: surname.trim(),
      email: email.trim(),
    );
  }

  static String maskEmail(String email) {
    final trimmed = email.trim();
    if (!trimmed.contains('@')) {
      return trimmed;
    }

    final atIndex = trimmed.indexOf('@');
    final localPart = trimmed.substring(0, atIndex);
    final domain = trimmed.substring(atIndex);

    if (localPart.length <= 4) {
      return '${localPart.substring(0, localPart.length)}****$domain';
    }

    return '${localPart.substring(0, 3)}****${localPart.substring(localPart.length - 3)}$domain';
  }
}