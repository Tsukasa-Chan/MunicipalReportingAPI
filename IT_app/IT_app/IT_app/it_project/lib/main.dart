import 'package:flutter/material.dart';
import 'package:it_project/Pages/CheckStatus.dart';
import 'package:it_project/Pages/Home.dart';
import 'package:it_project/Pages/OtherReports.dart';
import 'package:it_project/Pages/Profile.dart';
import 'package:it_project/Pages/Reporting.dart';
import 'package:it_project/Pages/Supervisor_dash.dart';
import 'package:it_project/Pages/email_verification.dart';

import 'Pages/StartUp.dart';
import 'Pages/auth_api.dart';
import 'Pages/auth_store.dart';
import 'Pages/report_store.dart';

// starts the app and loads saved reports.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ReportStore.initialize();
  runApp(const MyApp());
}

// sets up the main application.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {

  // allow navigation from anywhere in the app.
  final _navigatorKey = GlobalKey<NavigatorState>();

  bool _checkingSession = false;
  bool _showingSessionDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // checks the session when the app is reopened.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSession();
    }
  }

  // checks whether the users session is on.
  Future<void> _checkSession() async {
    if (_checkingSession || !AuthStore.isSignedIn) return;

    _checkingSession = true;

    try {
      await AuthStore.reloadProfile();
    } on AuthApiException catch (error) {
      if (error.isSessionExpired || error.code == 'account_deactivated') {
        _sendToStart(isDeactivated: error.code == 'account_deactivated');
      }
    } catch (_) {

      // keeps the user on the current screen if offline.
    } finally {
      _checkingSession = false;
    }
  }

  // returns the user to the startup screen.
  void _sendToStart({bool isDeactivated = false}) {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const StartupPage()),
          (_) => false,
    );

    _showSessionEndedDialog(isDeactivated: isDeactivated);
  }

  // informs the user that their session has ended.
  void _showSessionEndedDialog({bool isDeactivated = false}) {
    final dialogContext = _navigatorKey.currentContext;
    if (dialogContext == null || _showingSessionDialog) return;

    _showingSessionDialog = true;

    showDialog<void>(
      context: dialogContext,
      builder: (context) => AlertDialog(
        title: Text(isDeactivated
            ? 'Account deactivated'
            : 'You have been logged out'),
        content: Text(isDeactivated
            ? 'Your account has been deactivated by an administrator. '
            'Please contact an administrator for assistance.'
            : 'Your session has ended. Please log in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    ).whenComplete(() => _showingSessionDialog = false);
  }

  // builds the app's main layout and theme.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC94F1B),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Color(0xFF292929),
          iconTheme: IconThemeData(color: Color(0xFF292929)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFFC94F1B),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC94F1B),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),
      ),
      builder: (context, child) {
        return Container(
          color: const Color(0xFFF5F5F5),
          child: child,
        );
      },
      home: const StartupPage(),
    );
  }
}