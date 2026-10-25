import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:it_project/Pages/Supervisor_dash.dart';
import 'package:it_project/Pages/auth_store.dart';
import 'package:it_project/Pages/report_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ReportStore.initialize();
    AuthStore.registerUser(
      name: 'Resident',
      surname: 'User',
      username: 'schedule_resident',
      email: 'schedule.resident@example.com',
      password: 'SecurePass1',
    );
  });

  testWidgets('supervisor opens today schedule and advances job status', (
    tester,
  ) async {
    final report = ReportStore.addReport(
      issueType: 'Roads and Stormwater',
      issue: 'Pothole',
      area: 'Area 1',
      imagePath: '',
    )!;
    final tomorrowReport = ReportStore.addReport(
      issueType: 'Electricity',
      issue: 'Power outage',
      area: 'Area 1',
      imagePath: '',
    )!;
    AuthStore.registerUser(
      name: 'Schedule',
      surname: 'Supervisor',
      username: 'schedule_supervisor',
      email: 'schedule.supervisor@example.com',
      password: 'SecurePass1',
      isSupervisor: true,
    );
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
        reports: [report],
        supervisorUsername: 'schedule_supervisor',
        scheduledAt: scheduledAt,
      ),
      isTrue,
    );
    expect(
      ReportStore.assignSupervisor(
        reports: [tomorrowReport],
        supervisorUsername: 'schedule_supervisor',
        scheduledAt: scheduledAt.add(const Duration(days: 1)),
      ),
      isTrue,
    );
    expect(
      ReportStore.reportsForSupervisorOnDate(
        supervisorUsername: 'schedule_supervisor',
        date: scheduledAt,
      ),
      contains(report),
    );
    expect(
      ReportStore.reportsForSupervisorOnDate(
        supervisorUsername: 'schedule_supervisor',
        date: scheduledAt,
      ),
      isNot(contains(tomorrowReport)),
    );

    expect(
      AuthStore.validateLogin(
        email: 'schedule.supervisor@example.com',
        password: 'SecurePass1',
      ),
      isTrue,
    );
    await tester.pumpWidget(const MaterialApp(home: SupervisorDashboardPage()));

    expect(find.text('Today’s schedule'), findsOneWidget);
    expect(find.text('1 job(s) allocated today'), findsOneWidget);
    await tester.tap(find.text('Today’s schedule'));
    await tester.pumpAndSettle();

    expect(find.text('1 job(s) allocated for this day'), findsOneWidget);
    await tester.tap(find.textContaining('Report #${report.id}'));
    await tester.pumpAndSettle();

    expect(find.text('On-site'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    await tester.tap(find.text('Mark In progress'));
    await tester.pumpAndSettle();
    expect(report.status, 'In progress');
  });
}
