import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:it_project/Pages/OtherReports.dart';
import 'package:it_project/Pages/auth_store.dart';
import 'package:it_project/Pages/report_store.dart';

void main() {
  setUp(() {
    AuthStore.registerUser(
      name: 'First',
      surname: 'Reporter',
      username: 'first_reporter',
      email: 'first@example.com',
      password: 'SecurePass1',
    );
  });

  testWidgets('community reports group same issues only within the same area', (
    tester,
  ) async {
    final firstReport = ReportStore.addReport(
      issueType: 'Roads and Stormwater',
      issue: 'Pothole',
      area: 'Area 1',
      description: 'Private address details for first reporter',
      locationAddress: 'Private first reporter address',
      imagePath: '',
    )!;

    AuthStore.registerUser(
      name: 'Second',
      surname: 'Reporter',
      username: 'second_reporter',
      email: 'second@example.com',
      password: 'SecurePass1',
    );
    ReportStore.addReport(
      issueType: 'roads and stormwater',
      issue: ' pothole ',
      area: ' area 1 ',
      description: 'Private address details for second reporter',
      locationAddress: 'Private second reporter address',
      imagePath: '',
    );

    AuthStore.registerUser(
      name: 'Third',
      surname: 'Reporter',
      username: 'third_reporter',
      email: 'third@example.com',
      password: 'SecurePass1',
    );
    ReportStore.addReport(
      issueType: 'Roads and Stormwater',
      issue: 'Pothole',
      area: 'Area 2',
      imagePath: '',
    );

    await tester.pumpWidget(const MaterialApp(home: OtherReportsPage()));

    expect(find.text('Report #${firstReport.id}'), findsOneWidget);
    expect(
      find.textContaining('2 people reported the same issue'),
      findsOneWidget,
    );
    expect(find.textContaining('1 person reported'), findsNothing);
    expect(
      find.textContaining('Reported by First Reporter, Second Reporter'),
      findsOneWidget,
    );
    expect(find.textContaining('Private first reporter address'), findsNothing);

    await tester.tap(find.text('Report #${firstReport.id}'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Private first reporter address'), findsNothing);
    expect(
      find.textContaining('Private address details for first reporter'),
      findsNothing,
    );
    expect(find.text('Same issue reported by: 2 people'), findsOneWidget);
  });

  testWidgets('a user can view full details of their own report', (
    tester,
  ) async {
    final report = ReportStore.addReport(
      issueType: 'Electricity',
      issue: 'Street light outage',
      area: 'Ward 52 - Tongaat',
      description: 'My own private report details',
      locationAddress: 'My own report address',
      pinLocation: '-29.5, 31.1',
      imagePath: '',
    )!;

    await tester.pumpWidget(const MaterialApp(home: OtherReportsPage()));
    await tester.tap(find.text('Report #${report.id}'));
    await tester.pumpAndSettle();

    expect(find.textContaining('My own report address'), findsOneWidget);
    expect(
      find.textContaining('My own private report details'),
      findsOneWidget,
    );
    expect(find.text('Ward: Ward 52 - Tongaat'), findsOneWidget);
    expect(find.text('Pin location: -29.5, 31.1'), findsOneWidget);
  });
}
