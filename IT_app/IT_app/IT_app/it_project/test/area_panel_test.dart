import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:it_project/Pages/api_paths.dart';
import 'package:it_project/Pages/auth_api.dart';
import 'package:it_project/Pages/Home.dart';
import 'package:it_project/Pages/Profile.dart';
import 'package:it_project/Pages/Register.dart';
import 'package:it_project/Pages/auth_store.dart';
import 'package:it_project/Pages/report_store.dart';

void main() {
  setUp(() {
    AuthStore.registerUser(
      name: 'Shalin',
      surname: 'Govender',
      username: 'shalin',
      email: 'shaling357@gmail.com',
      password: 'Smg_22@7',
      communityArea: 'Area 2',
    );
  });

  testWidgets('Area detail shows read-only area reports', (tester) async {
    final report = ReportStore.addReport(
      issueType: 'Roads and Stormwater',
      issue: 'Pothole',
      area: 'Area 2',
      imagePath: '',
    )!;
    ReportStore.updateStatus(report, 'In progress');

    await tester.pumpWidget(
      const MaterialApp(home: AreaDetailPage(areaName: 'Area 2')),
    );

    expect(
      find.widgetWithText(ElevatedButton, 'Reports for Area 2'),
      findsOneWidget,
    );
    expect(find.text('Community reports • Area 2'), findsOneWidget);
    expect(
      find.textContaining('Roads and Stormwater: Pothole'),
      findsOneWidget,
    );
    expect(find.textContaining('Reported by Shalin Govender'), findsOneWidget);
    expect(find.textContaining('1 person reported'), findsNothing);
    expect(find.text('Read-only updates for this area.'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byIcon(Icons.send), findsNothing);
  });

  testWidgets('My Ward drawer opens the registered ward reports', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    expect(find.text('Area 2'), findsWidgets);
    await tester.tap(find.text('My Ward').last);
    await tester.pumpAndSettle();

    expect(find.text('Reports for Area 2'), findsWidgets);
    expect(find.text('Community reports • Area 2'), findsOneWidget);
  });

  testWidgets('registration opens Home only after email verification', (
    tester,
  ) async {
    AuthStore.logout();
    final api = AuthApi(
      baseUrl: 'https://api.example.com',
      client: MockClient((request) async {
        if (request.url.path == ApiPaths.registerAccount) {
          return http.Response('', 202);
        }
        if (request.url.path == ApiPaths.verifyEmail) {
          return http.Response('{"verified": true}', 200);
        }
        return http.Response('{"message": "Unexpected route"}', 404);
      }),
    );
    await tester.pumpWidget(MaterialApp(home: RegisterPage(authApi: api)));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Community Member');
    await tester.enterText(fields.at(1), 'community.member@gmail.com');
    await tester.enterText(fields.at(2), '52');
    await tester.enterText(fields.at(3), 'Tongaat');
    await tester.enterText(fields.at(4), 'SecurePass1');
    await tester.enterText(fields.at(5), 'SecurePass1');

    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Register'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
    await tester.pumpAndSettle();

    expect(find.text('Check your email'), findsOneWidget);
    expect(AuthStore.currentUser, isNull);

    await tester.enterText(find.byType(TextFormField), '123456');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Verify Email'));
    await tester.pumpAndSettle();

    expect(AuthStore.currentUser?.fullName, 'Community Member');
    expect(AuthStore.currentUser?.ward, 'Ward 52 - Tongaat');
    expect(find.text('My Ward'), findsOneWidget);
  });

  testWidgets('My Area shows in-progress reports for the registered area', (
    tester,
  ) async {
    final report = ReportStore.addReport(
      issueType: 'Water and Sanitation',
      issue: 'Burst Pipe',
      area: 'Area 2',
      imagePath: '',
    )!;
    ReportStore.updateStatus(report, 'In progress');

    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    expect(find.text('Reports in progress • Area 2'), findsOneWidget);
    expect(
      find.textContaining('Water and Sanitation: Burst Pipe'),
      findsOneWidget,
    );
  });

  testWidgets('Profile shows only reports submitted by the current user', (
    tester,
  ) async {
    final ownReport = ReportStore.addReport(
      issueType: 'User-only repair',
      issue: 'Owned report',
      area: 'Area 2',
      imagePath: '',
    )!;

    AuthStore.registerUser(
      name: 'Another',
      surname: 'Resident',
      username: 'another_resident',
      email: 'another@example.com',
      password: 'SecurePass1',
    );
    ReportStore.addReport(
      issueType: 'Hidden account report',
      issue: 'Not owned',
      area: 'Area 2',
      imagePath: '',
    );
    AuthStore.validateLogin(
      email: 'shaling357@gmail.com',
      password: 'Smg_22@7',
    );

    await tester.pumpWidget(const MaterialApp(home: ProfilePage()));

    expect(
      find.text('Report #${ownReport.id} - User-only repair'),
      findsOneWidget,
    );
    expect(find.textContaining('Hidden account report'), findsNothing);
  });
}
