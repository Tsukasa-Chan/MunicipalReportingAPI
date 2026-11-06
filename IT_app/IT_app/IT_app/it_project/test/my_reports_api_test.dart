import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:it_project/Pages/auth_api.dart';
import 'package:it_project/Pages/report_store.dart';

void main() {
  test('my reports request uses the authenticated endpoint', () async {
    late http.Request request;
    final api = AuthApi(
      baseUrl: 'https://api.example.com',
      client: MockClient((incomingRequest) async {
        request = incomingRequest;
        return http.Response(
          '[{"id":12,"issueId":34,"status":"InProgress"}]',
          200,
        );
      }),
    );

    final reports = await api.getMyReports(accessToken: 'test-token');

    expect(request.method, 'GET');
    expect(request.url.path, '/api/Reports/mine');
    expect(request.headers['authorization'], 'Bearer test-token');
    expect(reports.single['id'], 12);
    api.close();
  });

  test('maps a server report to the profile report model', () {
    final report = ReportRequest.fromApiJson({
      'id': 12,
      'issueId': 34,
      'issueCategory': 'RoadsAndTransport',
      'issueType': 'Pothole',
      'status': 'InProgress',
      'areaId': 3,
      'areaName': 'Central',
      'wardName': 'Ward 1',
      'latitude': -1.2,
      'longitude': 36.8,
      'location': 'Main Street',
      'description': 'Large pothole',
      'createdAt': '2026-11-03T08:00:00Z',
      'updatedAt': '2026-11-05T10:00:00Z',
      'userFullName': 'Test User',
    });

    expect(report.backendId, 12);
    expect(report.issueId, 34);
    expect(report.isSubmitted, isTrue);
    expect(report.syncStatus, 'Synced');
    expect(report.issueType, 'Roads And Transport');
    expect(report.issue, 'Pothole');
    expect(report.area, 'Ward 1 - Central');
    expect(report.areaId, 3);
    expect(report.locationAddress, 'Main Street');
    expect(report.description, 'Large pothole');
    expect(report.status, 'InProgress');
  });

  test(
    'status refresh updates a report loaded directly from the server',
    () async {
      final report = ReportRequest(
        id: -12,
        backendId: 12,
        issueId: 34,
        senderName: 'Test User',
        issueType: 'Roads',
        issue: 'Pothole',
        area: 'Ward 1 - Central',
        submittedAt: DateTime.utc(2026, 11, 3),
        status: 'Reported',
      );

      await ReportStore.updateIssueDetails(
        report: report,
        status: 'Resolved',
        scheduledAt: DateTime.utc(2026, 11, 4),
        updatedAt: DateTime.utc(2026, 11, 5),
      );

      expect(report.status, 'Resolved');
      expect(report.scheduledAt, DateTime.utc(2026, 11, 4));
      expect(report.updatedAt, DateTime.utc(2026, 11, 5));
    },
  );
}
