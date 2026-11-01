import 'package:flutter/material.dart';

import 'Help.dart';
import 'Home.dart';
import 'Register.dart';
import 'Supervisor_dash.dart';
import 'auth_store.dart';
import 'login.dart';

class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  bool showWelcomeScreen = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    // The saved login is checked while the splash screen is showing.
    final restoreFuture = AuthStore.restoreSession();

    await Future<void>.delayed(const Duration(seconds: 2));
    final restored = await restoreFuture;

    if (!mounted) return;

    if (restored) {
      _openDashboard();
    } else {
      setState(() => showWelcomeScreen = true);
    }
  }

  void _openDashboard() {
    final user = AuthStore.currentUser;
    final destination = user?.isSupervisor == true
        ? const SupervisorDashboardPage()
        : const HomePage();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F4),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 700),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: showWelcomeScreen
            ? const WelcomeScreen()
            : const SplashScreen(),
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('splash'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF8F4),
            Color(0xFFFFE9DC),
          ],
        ),
      ),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Image.asset(
            'lib/img/app logo.png',
            width: 180,
            height: 180,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('welcome'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFF8F4),
            Color(0xFFFFE9DC),
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC94F1B).withOpacity(0.12),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: 110,
                    height: 110,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'lib/img/app logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Welcome heading
                const Text(
                  'Welcome',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF292524),
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Making our communities better, together.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF78716C),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 38),

                // Login button
                _actionButton(
                  label: 'Login',
                  backgroundColor: const Color(0xFFC94F1B),
                  foregroundColor: Colors.white,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginPage(),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Register button
                _actionButton(
                  label: 'Register',
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFC94F1B),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RegisterPage(),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Help button
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HelpPage(),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFC94F1B),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Need help?',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
    required VoidCallback onPressed,
  }) {
    final isPrimary = backgroundColor == const Color(0xFFC94F1B);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: isPrimary ? 4 : 0,
          shadowColor: const Color(0xFFC94F1B).withOpacity(0.25),
          padding: const EdgeInsets.symmetric(vertical: 17),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: isPrimary
                ? BorderSide.none
                : const BorderSide(
              color: Color(0xFFE8C7B8),
              width: 1.2,
            ),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}