
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
      backgroundColor: _cream,

      appBar: AppBar(
        title: const Text(
          'Contact Us',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: pagePrimaryColor(isSupervisor: isSupervisor),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      // Background fills the entire screen below the AppBar
      body: SizedBox.expand(
        child: Container(
          decoration: isSupervisor
              ? pageBackgroundDecoration(isSupervisor: isSupervisor)
              : const BoxDecoration(
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 40,
              ),

              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Contact icon
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: _orange.withOpacity(0.12),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1E8),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.app_registration,
                        size: 65,
                        color: _orange,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Contact heading
                  const Text(
                    'Contact Us',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: _darkText,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Contact description
                  const Text(
                    'Get in touch with our team for assistance or enquiries.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: _secondaryText,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 38),

                  // Email contact card
                  _contactDetail(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: 'example@gmail.com',
                  ),

                  const SizedBox(height: 14),

                  // Phone contact card
                  _contactDetail(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: '+27 12 345 6789',
                  ),

                  const SizedBox(height: 14),

                  // Office hours card
                  _contactDetail(
                    icon: Icons.access_time,
                    label: 'Office Hours',
                    value: 'Mon - Fri, 08:00 - 17:00',
                  ),

                  const SizedBox(height: 14),

                  // Support information card
                  _contactDetail(
                    icon: Icons.support_agent,
                    label: 'Support',
                    value:
                    'For support, concerns, or general enquiries, contact our support team and we will respond as quickly as possible.',
                  ),

                  const SizedBox(height: 24),

                  // Back button
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: _orange,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _contactDetail({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _borderColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _orange.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contact detail icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1E8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: _orange,
              size: 26,
            ),
          ),

          const SizedBox(width: 16),

          // Contact information
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: _darkText,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _secondaryText,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
