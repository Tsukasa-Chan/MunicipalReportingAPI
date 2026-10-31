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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 700),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: showWelcomeScreen ? const WelcomeScreen() : const SplashScreen(),
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
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF5F5F5), Color(0xFFF5F5F5)],
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
          colors: [Color(0xFFF5F5F5), Color(0xFFF5F5F5)],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
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
                const SizedBox(height: 28),
                const Text(
                  'Welcome',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC94F1B),
                  ),
                ),
                const SizedBox(height: 30),
                _actionButton(
                  label: 'Login',
                  backgroundColor: const Color(0xFFC94F1B),
                  foregroundColor: Colors.white,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  ),
                ),
                const SizedBox(height: 16),
                _actionButton(
                  label: 'Register',
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFC94F1B),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HelpPage()),
                  ),
                  child: const Text(
                    'Need help?',
                    style: TextStyle(
                      color: Color(0xFFC94F1B),
                      fontSize: 16,
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}