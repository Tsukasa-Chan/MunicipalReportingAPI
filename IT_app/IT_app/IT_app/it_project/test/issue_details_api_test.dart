import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:it_project/Pages/auth_api.dart';

void main() {
  test('issue details request returns current status and timestamps', () async {
    late http.Request request;
    final api = AuthApi(
      baseUrl: 'https://api.example.com',
      client: MockClient((incomingRequest) async {
        request = incomingRequest;
        return http.Response(
          '{"id":7,"status":"InProgress","scheduledAt":'
          '"2026-11-04T09:00:00Z","updatedAt":"2026-11-05T10:00:00Z"}',
          200,
        );
      }),
    );

    final issue = await api.getIssueDetails(
      issueId: 7,
      accessToken: 'test-token',
    );

    expect(request.method, 'GET');
    expect(request.url.path, '/api/Issues/7');
    expect(request.headers['authorization'], 'Bearer test-token');
    expect(issue['status'], 'InProgress');
    api.close();
  });
}
