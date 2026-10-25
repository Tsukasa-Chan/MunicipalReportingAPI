import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:it_project/Pages/api_paths.dart';
import 'package:it_project/Pages/auth_api.dart';

void main() {
  test(
    'registration sends full name and ward to the documented route',
    () async {
      late http.Request request;
      final api = AuthApi(
        baseUrl: 'https://api.example.com',
        client: MockClient((incomingRequest) async {
          request = incomingRequest;
          return http.Response('', 202);
        }),
      );

      await api.register(
        fullName: 'Example User',
        email: 'user@example.com',
        password: 'Pass1234',
        wardNumber: '52',
        wardLocation: 'Tongaat',
      );

      expect(request.method, 'POST');
      expect(request.url.path, ApiPaths.registerAccount);
      expect(jsonDecode(request.body), {
        'fullName': 'Example User',
        'email': 'user@example.com',
        'password': 'Pass1234',
        'ward': {'number': '52', 'location': 'Tongaat'},
      });
      api.close();
    },
  );

  test(
    'verification succeeds only for an explicit verified response',
    () async {
      final api = AuthApi(
        baseUrl: 'https://api.example.com',
        client: MockClient(
          (_) async => http.Response('{"verified": false}', 200),
        ),
      );

      expect(
        await api.verifyEmail(email: 'user@example.com', code: '123456'),
        isFalse,
      );
      api.close();
    },
  );

  test('missing API configuration fails with an actionable message', () async {
    final api = AuthApi(
      baseUrl: '',
      client: MockClient((_) async => http.Response('', 202)),
    );

    await expectLater(
      api.register(
        fullName: 'Example User',
        email: 'user@example.com',
        password: 'Pass1234',
        wardNumber: '52',
        wardLocation: 'Tongaat',
      ),
      throwsA(
        isA<AuthApiException>().having(
          (error) => error.message,
          'message',
          contains('API_BASE_URL'),
        ),
      ),
    );
    api.close();
  });
}
