import 'package:flutter_test/flutter_test.dart';
import 'package:it_project/Pages/report_store.dart';

void main() {
  test('report timeline metadata survives local persistence', () {
    final updatedAt = DateTime.utc(2026, 11, 5, 10);
    final scheduledAt = DateTime.utc(2026, 11, 4, 9);
    final report = ReportRequest(
      id: 1,
      backendId: 12,
      issueId: 34,
      updatedAt: updatedAt,
      scheduledAt: scheduledAt,
      status: 'InProgress',
      senderName: 'Test User',
      issueType: 'Roads',
      issue: 'Pothole',
      area: 'Area 1',
      createdAt: DateTime.utc(2026, 11, 3, 8),
    );

    final restored = ReportRequest.fromJson(report.toJson());

    expect(restored.issueId, 34);
    expect(restored.status, 'InProgress');
    expect(restored.scheduledAt, scheduledAt);
    expect(restored.updatedAt, updatedAt);
  });
}
