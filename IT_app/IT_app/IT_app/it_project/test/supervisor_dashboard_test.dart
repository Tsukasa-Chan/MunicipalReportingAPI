import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:it_project/Pages/Supervisor_dash.dart';
import 'package:it_project/Pages/auth_store.dart';
import 'package:it_project/Pages/report_store.dart';

void main() {
  setUp(() {
    AuthStore.registerUser(
      name: 'Supervisor',
      surname: 'Test',
      username: 'dashboard_supervisor',
      email: 'dashboard_supervisor@example.com',
      password: 'SecurePass1',
      isSupervisor: true,
      supervisorIssueType: 'Electricity',
    );
  });

  testWidgets('dashboard removes report-type selection and shows assigned type', (
    tester,
  ) async {
    ReportStore.addReport(
      issueType: 'Water and Sanitation',
      issue: 'Burst Pipe',
      area: 'Area 1',
      imagePath: '',
    );
    ReportStore.addReport(
      issueType: 'Electricity',
      issue: 'Power Outage',
      area: 'Area 1',
      imagePath: '',
    );
    ReportStore.addReport(
      issueType: 'Roads and Stormwater',
      issue: 'Pothole',
      area: 'Area 1',
      imagePath: '',
    );

    await tester.pumpWidget(const MaterialApp(home: SupervisorDashboardPage()));

    expect(find.text('Report type:'), findsNothing);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(find.text('Assigned'), findsNothing);
    expect(find.text('Today’s Electricity reports'), findsOneWidget);
    await tester.tap(find.text('Today’s Electricity reports'));
    await tester.pumpAndSettle();

    expect(find.text('Electricity reports'), findsOneWidget);
    expect(find.textContaining('Electricity - Power Outage'), findsOneWidget);
    expect(find.text('Water and Sanitation: Burst Pipe'), findsNothing);
    expect(find.text('Roads and Stormwater - Pothole'), findsNothing);
  });
}
