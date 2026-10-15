import 'package:flutter/material.dart';

import 'auth_store.dart';
import 'Supervisor_theme.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isSupervisor = AuthStore.currentUser?.isStaff == true;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: pagePrimaryColor(isSupervisor: isSupervisor),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: pageBackgroundDecoration(isSupervisor: isSupervisor),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.app_registration,
                            size: 60,
                            color: Color(0xFFC94F1B),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Contact Us',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFC94F1B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _contactDetail(label: 'Email', value: 'example@gmail.com'),
                    const SizedBox(height: 14),
                    _contactDetail(label: 'Phone', value: '+27 12 345 6789'),
                    const SizedBox(height: 14),
                    _contactDetail(
                      label: 'Office Hours',
                      value: 'Mon - Fri, 08:00 - 17:00',
                    ),
                    const SizedBox(height: 14),
                    _contactDetail(
                      label: 'Support',
                      value:
                          'For support, concerns, or general enquiries, contact our support team and we will respond as quickly as possible.',
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Back',
                        style: TextStyle(
                          color: Color(0xFFC94F1B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactDetail({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFC94F1B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(value),
        ],
      ),
    );
  }
}
