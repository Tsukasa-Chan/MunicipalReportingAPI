import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:it_project/Pages/auth_api.dart';
import 'package:it_project/Pages/report_store.dart';

void main() {
  test(
    'loads current-user reports with persisted resolution feedback',
    () async {
      late http.Request request;
      final api = AuthApi(
        baseUrl: 'https://api.example.com',
        client: MockClient((incomingRequest) async {
          request = incomingRequest;
          return http.Response(
            jsonEncode([
              {
                'id': 42,
                'issueId': 12,
                'issueCategory': 'RoadsAndTransport',
                'issueType': 'Pothole',
                'status': 'Resolved',
                'areaId': 2,
                'areaName': 'Central',
                'wardName': 'Ward 1',
                'location': 'Main Street',
                'createdAt': '2026-11-03T08:00:00Z',
                'feedbackRating': 4,
                'feedbackComment': 'Thank you for fixing it.',
                'feedbackUpdatedAt': '2026-11-05T10:00:00Z',
              },
            ]),
            200,
          );
        }),
      );

      final reports = await api.getMyReports(accessToken: 'test-token');
      final report = ReportRequest.fromApiJson(reports.single);

      expect(request.method, 'GET');
      expect(request.url.path, '/api/Reports/mine');
      expect(request.headers['authorization'], 'Bearer test-token');
      expect(report.backendId, 42);
      expect(report.status, 'Resolved');
      expect(report.feedbackRating, 4);
      expect(report.feedbackComment, 'Thank you for fixing it.');
      expect(report.feedbackUpdatedAt, isNotNull);
      api.close();
    },
  );

  test('submits editable rating and optional comment for a report', () async {
    late http.Request request;
    final api = AuthApi(
      baseUrl: 'https://api.example.com',
      client: MockClient((incomingRequest) async {
        request = incomingRequest;
        return http.Response(
          '{"rating":5,"comment":"Resolved promptly.","updatedAt":'
          '"2026-11-06T09:00:00Z"}',
          200,
        );
      }),
    );

    final result = await api.submitReportFeedback(
      accessToken: 'test-token',
      reportId: 42,
      rating: 5,
      comment: '  Resolved promptly.  ',
    );

    expect(request.method, 'PUT');
    expect(request.url.path, '/api/Reports/42/feedback');
    expect(request.headers['authorization'], 'Bearer test-token');
    expect(jsonDecode(request.body), {
      'rating': 5,
      'comment': 'Resolved promptly.',
    });
    expect(result['rating'], 5);
    api.close();
  });

  test('rejects invalid feedback ratings before sending a request', () {
    final api = AuthApi(
      baseUrl: 'https://api.example.com',
      client: MockClient((_) async => http.Response('{}', 200)),
    );

    expect(
      () => api.submitReportFeedback(
        accessToken: 'test-token',
        reportId: 42,
        rating: 6,
        comment: '',
      ),
      throwsArgumentError,
    );
    api.close();
  });

  test('keeps feedback in the local report cache model', () {
    final report = ReportRequest(
      id: 8,
      backendId: 42,
      senderName: 'Resident',
      issueType: 'Roads',
      issue: 'Pothole',
      area: 'Ward 1',
      feedbackRating: 5,
      feedbackComment: 'Fixed quickly.',
      feedbackUpdatedAt: DateTime.utc(2026, 11, 6, 9),
    );

    final restored = ReportRequest.fromJson(report.toJson());

    expect(restored.feedbackRating, 5);
    expect(restored.feedbackComment, 'Fixed quickly.');
    expect(restored.feedbackUpdatedAt, report.feedbackUpdatedAt);
  });
}
