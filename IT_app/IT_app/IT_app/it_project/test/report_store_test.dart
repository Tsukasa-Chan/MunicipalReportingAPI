import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:it_project/Pages/auth_store.dart';
import 'package:it_project/Pages/report_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ReportStore.initialize();
    AuthStore.registerUser(
      name: 'Test',
      surname: 'User',
      username: 'tester',
      email: 'tester@example.com',
      password: 'Pass1234',
    );
  });

  test('offline report tracks creation and submission timestamps', () async {
    ReportStore.setConnectionStatus(false);

    final report = ReportStore.addReport(
      issueType: 'Water and Sanitation',
      issue: 'Burst Pipe',
      area: 'Durban',
      description: 'Pipe leaking',
      locationAddress: '20 Main Rd',
      pinLocation: 'GPS-1',
      imagePath: '',
      isOfflineSubmission: true,
    );

    expect(report, isNotNull);
    expect(report!.createdAt, isNotNull);
    expect(report.queuedAt, isNotNull);
    expect(report.submittedAt, isNull);
    expect(report.storageType, 'offline');

    report.markSubmitted();
    expect(report.submittedAt, isNotNull);
    expect(report.syncStatus, 'Synced');
  });

  test(
    'reports group by issue and area with the first report as the group ID',
    () {
      final firstReport = ReportRequest(
        id: 1,
        senderName: 'First Reporter',
        senderUsername: 'first',
        issueType: 'Roads and Stormwater',
        issue: 'Pothole',
        area: 'Area 1',
        createdAt: DateTime(2026, 10, 1),
      );
      final duplicateReport = ReportRequest(
        id: 2,
        senderName: 'Second Reporter',
        senderUsername: 'second',
        issueType: ' roads and stormwater ',
        issue: ' pothole ',
        area: ' area 1 ',
        createdAt: DateTime(2026, 10, 2),
      );
      final sameIssueDifferentArea = ReportRequest(
        id: 3,
        senderName: 'Third Reporter',
        senderUsername: 'third',
        issueType: 'Roads and Stormwater',
        issue: 'Pothole',
        area: 'Area 2',
        createdAt: DateTime(2026, 10, 3),
      );
      final repeatReporter = ReportRequest(
        id: 4,
        senderName: 'First Reporter',
        senderUsername: 'first',
        issueType: 'Roads and Stormwater',
        issue: 'Pothole',
        area: 'Area 1',
        createdAt: DateTime(2026, 10, 4),
      );

      final groups = ReportStore.groupReports([
        duplicateReport,
        sameIssueDifferentArea,
        firstReport,
        repeatReporter,
      ]);

      expect(groups, hasLength(2));
      final areaOneGroup = groups.singleWhere(
        (group) => group.firstReport.area.trim().toLowerCase() == 'area 1',
      );
      expect(areaOneGroup.firstReport.id, 1);
      expect(areaOneGroup.reporterCount, 2);
      expect(
        areaOneGroup.reports,
        containsAll([firstReport, duplicateReport, repeatReporter]),
      );
    },
  );

  test(
    'report store exposes analytics for offline and online submissions',
    () async {
      ReportStore.setConnectionStatus(false);

      final offlineReport = ReportStore.addReport(
        issueType: 'Waste Management',
        issue: 'Illegal Dumping',
        area: 'Durban',
        description: 'Dumped waste',
        locationAddress: '10 Beach Rd',
        pinLocation: 'GPS-2',
        imagePath: '',
        isOfflineSubmission: true,
      );

      offlineReport!.markSubmitted();

      final analytics = ReportStore.analyticsSummary();

      expect(analytics['totalReports'], greaterThanOrEqualTo(1));
      expect(analytics['syncedReports'], greaterThanOrEqualTo(1));
      expect(analytics['offlineReports'], greaterThanOrEqualTo(0));
    },
  );

  test('reports are queued offline first and later synced online', () async {
    ReportStore.setConnectionStatus(true);

    final queuedReport = ReportStore.addReport(
      issueType: 'Water and Sanitation',
      issue: 'Burst Pipe',
      area: 'Cape Town',
      description: 'Main water line leaking',
      locationAddress: '15 Long Street',
      pinLocation: 'GPS-3',
      imagePath: '',
    );

    expect(queuedReport, isNotNull);
    expect(queuedReport!.storageType, 'offline');
    expect(queuedReport.syncStatus, 'Queued offline');
    expect(queuedReport.submittedAt, isNull);

    await ReportStore.syncPendingReports((report) async {
      expect(report.id, queuedReport.id);
      return true;
    });

    expect(queuedReport.storageType, 'online');
    expect(queuedReport.syncStatus, 'Synced');
    expect(queuedReport.submittedAt, isNotNull);
  });

  test(
    'saving the job invoice completes the report pending admin delivery',
    () {
      final report = ReportStore.addReport(
        issueType: 'Roads and Stormwater',
        issue: 'Pothole',
        area: 'Area 1',
        imagePath: '',
      )!;

      ReportStore.saveJobCompletion(
        report: report,
        workerName: 'Field Worker',
        workerId: 'F-001',
        jobNumber: 'JOB-001',
        locationAddress: '1 Main Road',
        pinLocation: '-29.8, 31.0',
        startTime: '09:00',
        stopTime: '10:00',
        totalTime: '1 hour',
        managerSignature: 'Manager',
        workerSignature: 'Worker',
      );

      expect(report.status, 'Completed');
      expect(
        report.invoiceNumber,
        'LOG-${report.id.toString().padLeft(4, '0')}',
      );
      expect(report.invoiceSubmissionStatus, 'Pending admin submission');
      expect(report.invoiceSubmittedAt, isNull);
    },
  );

  test('supervisors assign reports to field workers', () async {
    expect(
      AuthStore.validateLogin(
        email: 'shaling357@gmail.com',
        password: 'Smg_22@7',
      ),
      isTrue,
    );
    expect(
      AuthStore.addWorker(
        name: 'Field',
        surname: 'Worker',
        username: 'fieldworker',
        email: 'fieldworker@example.com',
        password: 'Worker123',
      ),
      isTrue,
    );

    final report = ReportStore.addReport(
      issueType: 'Roads and Stormwater',
      issue: 'Pothole',
      area: 'Area 1',
      imagePath: '',
    );
    expect(report, isNotNull);

    expect(
      ReportStore.assignWorker(report: report!, workerUsername: 'fieldworker'),
      isTrue,
    );
    expect(report.assignedWorkerUsername, 'fieldworker');
    expect(
      ReportRequest.fromJson(report.toJson()).assignedWorkerUsername,
      'fieldworker',
    );
    expect(report.status, 'Assigned');
    expect(ReportStore.reportsForWorker('fieldworker'), contains(report));

    ReportStore.updateStatus(report, 'In progress');
    expect(
      ReportStore.assignWorker(report: report, workerUsername: 'fieldworker'),
      isFalse,
    );
  });

  test('Shalin can only be assigned electricity reports', () async {
    final roadReport = ReportStore.addReport(
      issueType: 'Roads and Stormwater',
      issue: 'Pothole',
      area: 'Ward 52 - Tongaat',
      imagePath: '',
    )!;
    final electricityReport = ReportStore.addReport(
      issueType: 'Electricity',
      issue: 'Power outage',
      area: 'Ward 52 - Tongaat',
      imagePath: '',
    )!;
    expect(
      AuthStore.validateLogin(
        email: 'shaling357@gmail.com',
        password: 'Smg_22@7',
      ),
      isTrue,
    );

    final scheduledAt = DateTime.now();
    expect(
      ReportStore.assignSupervisor(
        reports: [roadReport],
        supervisorUsername: 'shalin',
        scheduledAt: scheduledAt,
      ),
      isFalse,
    );
    expect(roadReport.assignedSupervisorUsername, isEmpty);
    expect(roadReport.status, 'Pending');
    roadReport
      ..assignedSupervisorUsername = 'shalin'
      ..scheduledAt = scheduledAt;
    expect(
      ReportStore.assignSupervisor(
        reports: [electricityReport],
        supervisorUsername: 'shalin',
        scheduledAt: scheduledAt,
      ),
      isTrue,
    );
    expect(
      ReportStore.reportsForSupervisorOnDate(
        supervisorUsername: 'shalin',
        date: scheduledAt,
      ),
      [electricityReport],
    );
  });

  test('regular users cannot assign reports', () async {
    expect(
      AuthStore.validateLogin(
        email: 'shaling357@gmail.com',
        password: 'Smg_22@7',
      ),
      isTrue,
    );
    expect(
      AuthStore.addWorker(
        name: 'Field',
        surname: 'Worker',
        username: 'fieldworker2',
        email: 'fieldworker2@example.com',
        password: 'Worker123',
      ),
      isTrue,
    );
    AuthStore.logout();
    expect(
      AuthStore.validateLogin(
        email: 'tester@example.com',
        password: 'Pass1234',
      ),
      isTrue,
    );

    final report = ReportStore.addReport(
      issueType: 'Water and Sanitation',
      issue: 'Burst Pipe',
      area: 'Area 1',
      imagePath: '',
    );
    expect(report, isNotNull);
    expect(
      ReportStore.assignWorker(report: report!, workerUsername: 'fieldworker2'),
      isFalse,
    );
  });
}
