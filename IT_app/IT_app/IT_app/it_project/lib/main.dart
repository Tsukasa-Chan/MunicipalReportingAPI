import 'package:flutter/material.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ReportStore.initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // Lets this class move to another screen from anywhere in the app.
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

  // Runs when the app comes back to the screen, for example after the user
  // clicks the email-change link in the browser and returns.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSession();
    }
  }

  Future<void> _checkSession() async {
    if (_checkingSession || !AuthStore.isSignedIn) return;

    _checkingSession = true;

    try {
      // Asks the backend for the profile. If the login was ended (email or
      // password changed), this throws a "session expired" error.
      await AuthStore.reloadProfile();
    } on AuthApiException catch (error) {
      if (error.isSessionExpired) {
        _sendToStart();
      }
    } catch (_) {
      // No connection: leave the person where they are.
    } finally {
      _checkingSession = false;
    }
  }

  void _sendToStart() {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const StartupPage()),
          (_) => false,
    );

    _showSessionEndedDialog();
  }

  void _showSessionEndedDialog() {
    final dialogContext = _navigatorKey.currentContext;
    if (dialogContext == null || _showingSessionDialog) return;

    _showingSessionDialog = true;

    showDialog<void>(
      context: dialogContext,
      builder: (context) => AlertDialog(
        title: const Text('You have been logged out'),
        content: const Text(
          'Your login has ended. This happens when your email or password '
              'is changed. Please log in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    ).whenComplete(() => _showingSessionDialog = false);
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner:
      false, // removes the demo tag on the top right corner
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
          ),
        ),
      ),
      builder: (context, child) {
        return Container(
          color: const Color(0xFFF5F5F5),
          child: child,
        );
      },
      home: const StartupPage(), // Shows the animated startup screen first
    );
  }
}