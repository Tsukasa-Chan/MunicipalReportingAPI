import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:it_project/Pages/login.dart';

void main() {
  testWidgets('login requests email and password only', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Username / Email'), findsNothing);
  });
}
