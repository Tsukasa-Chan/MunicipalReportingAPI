
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'auth_store.dart';
import 'Supervisor_theme.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static final Uri _phoneUri = Uri(
    scheme: 'tel',
    path: '+27688460252',
  );

  Future<void> _callSupport(BuildContext context) async {
    if (!await launchUrl(_phoneUri)) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open the phone app.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSupervisor = AuthStore.currentUser?.isStaff == true;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F4),

      appBar: AppBar(
        title: const Text(
          'Need help?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: const Color(0xFFC94F1B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      // Background fills the available screen space
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
                  // Support icon
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC94F1B)
                              .withOpacity(0.12),
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
                        Icons.support_agent,
                        size: 65,
                        color: Color(0xFFC94F1B),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Support heading
                  const Text(
                    'Support centre',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF292524),
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Support description
                  const Text(
                    'Choose how you would like to reach the support team.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF78716C),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 38),

                  // Call support card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE8C7B8),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC94F1B)
                              .withOpacity(0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),

                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),

                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _callSupport(context),

                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 18,
                          ),

                          child: Row(
                            children: [
                              // Phone icon
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF1E8),
                                  borderRadius:
                                  BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.phone,
                                  color: Color(0xFFC94F1B),
                                  size: 28,
                                ),
                              ),

                              const SizedBox(width: 16),

                              // Support information
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Call support',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF292524),
                                      ),
                                    ),

                                    SizedBox(height: 5),

                                    Text(
                                      '+27 68 846 0252',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF78716C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const Icon(
                                Icons.open_in_new,
                                color: Color(0xFFC94F1B),
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Back button
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFC94F1B),
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
}
