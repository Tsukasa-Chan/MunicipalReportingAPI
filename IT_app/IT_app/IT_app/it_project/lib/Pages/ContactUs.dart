import 'package:flutter/material.dart';

import 'auth_store.dart';
import 'Supervisor_theme.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  static const Color _orange = Color(0xFFC94F1B);
  static const Color _cream = Color(0xFFFFF8F4);
  static const Color _darkText = Color(0xFF292524);
  static const Color _secondaryText = Color(0xFF78716C);
  static const Color _borderColor = Color(0xFFE8C7B8);

  @override
  Widget build(BuildContext context) {
    final isSupervisor = AuthStore.currentUser?.isStaff == true;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: pagePrimaryColor(isSupervisor: isSupervisor),
        foregroundColor: Colors.white,
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _borderColor.withValues(alpha: 0.65),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _darkText.withValues(alpha: 0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
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
                            color: _orange,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Contact Us',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: _darkText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _contactDetail(
                      label: 'Email',
                      value: 'example@gmail.com',
                    ),
                    const SizedBox(height: 14),
                    _contactDetail(
                      label: 'Phone',
                      value: '+27 12 345 6789',
                    ),
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
                      style: TextButton.styleFrom(
                        foregroundColor: _orange,
                      ),
                      child: const Text(
                        'Back',
                        style: TextStyle(
                          color: _orange,
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

  Widget _contactDetail({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _borderColor.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _orange,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: _darkText,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}