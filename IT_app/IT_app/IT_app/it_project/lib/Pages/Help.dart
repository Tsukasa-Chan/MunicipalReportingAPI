import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'auth_store.dart';
import 'Supervisor_theme.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static final Uri _phoneUri = Uri(scheme: 'tel', path: '+27688460252');

  Future<void> _callSupport(BuildContext context) async {
    if (!await launchUrl(_phoneUri)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the phone app.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSupervisor = AuthStore.currentUser?.isStaff == true;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Need help?'),
        backgroundColor: const Color(0xFFC94F1B),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: pageBackgroundDecoration(isSupervisor: isSupervisor),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(Icons.support_agent, size: 72, color: Colors.white),
              const SizedBox(height: 16),
              const Text(
                'Support centre',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Choose how you would like to reach the support team.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 28),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.phone, color: Color(0xFFC94F1B)),
                  title: const Text('Call support'),
                  subtitle: const Text('+27 68 846 0252'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _callSupport(context),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Back',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
