import 'package:flutter/material.dart';

import 'ContactUs.dart';
import 'EditProfile.dart';
import 'Help.dart';
import 'OtherReports.dart';
import 'StartUp.dart';
import 'auth_api.dart';
import 'auth_store.dart';
import 'report_store.dart';
import 'Supervisor_theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _reloadProfile();
  }

  // Gets the latest details from the backend when the page opens.
  Future<void> _reloadProfile() async {
    try {
      await AuthStore.reloadProfile();
      if (mounted) setState(() {});
    } on AuthApiException catch (error) {
      if (error.isSessionExpired && mounted) {
        _goToStart();
      }
    } catch (_) {
      // No connection: keep showing what is already on the screen.
    }
  }

  void _goToStart() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const StartupPage()),
          (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthStore.currentUser;
    final reports = ReportStore.reportsForCurrentUser();
    final isSupervisor = user?.isStaff == true;
    final displayName = user?.fullName ?? 'User';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: pagePrimaryColor(isSupervisor: isSupervisor),
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Help',
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpPage()),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: pageBackgroundDecoration(isSupervisor: isSupervisor),
        child: SafeArea(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: Color(0xFFC94F1B),
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          color: Color(0xFF292524),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit profile',
                      icon: const Icon(
                        Icons.edit,
                        color: Color(0xFF292524),
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfilePage(),
                          ),
                        );

                        // Show any changes made on the edit page.
                        if (mounted) setState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  label: 'Full Name',
                  value: user?.fullName ?? 'Not set',
                ),
                _InfoCard(
                  label: 'Email',
                  value: user?.email ?? 'Not set',
                ),
                _InfoCard(
                  label: 'Area',
                  value: user?.ward ?? 'Not set',
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _quickLink(
                      context,
                      label: 'View Reports',
                      icon: Icons.assignment,
                      page: const OtherReportsPage(),
                    ),
                    _quickLink(
                      context,
                      label: 'Contact Us',
                      icon: Icons.contact_mail,
                      page: const ContactPage(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Your Recent Reports',
                  style: TextStyle(
                    color: Color(0xFF292524),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (reports.isEmpty)
                  const Text(
                    'You have not submitted any reports yet.',
                    style: TextStyle(
                      color: Color(0xFF78716C),
                      fontSize: 14,
                    ),
                  )
                else
                  ...reports.map(_reportCard),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Back to top',
        backgroundColor: pagePrimaryColor(isSupervisor: isSupervisor),
        elevation: 2,
        onPressed: () => scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        ),
        child: const Icon(
          Icons.arrow_upward,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _quickLink(
      BuildContext context, {
        required String label,
        required IconData icon,
        required Widget page,
      }) {
    return ElevatedButton.icon(
      onPressed: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      icon: Icon(icon),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFC94F1B),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _reportCard(ReportRequest report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white.withValues(alpha: 0.95),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: Color(0xFFE8C7B8),
          width: 0.8,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: const Color(0xFFC94F1B),
          ),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: const Color(0xFFC94F1B),
          collapsedIconColor: const Color(0xFF78716C),
          title: Text(
            'Report #${report.id} - ${report.issueType}',
            style: const TextStyle(
              color: Color(0xFF292524),
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          children: [
            _reportDetail('Status', report.status),
            _reportDetail(
              'Date Submitted',
              report.createdAt.toLocal().toString().split('.').first,
            ),
            _reportDetail('Specific Issue', report.issue),
            _reportDetail('Location', report.locationAddress),
            _reportDetail(
              'Additional Information',
              report.description.isEmpty ? 'None' : report.description,
            ),
            _reportDetail('Sync', report.syncStatus),
          ],
        ),
      ),
    );
  }

  Widget _reportDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: RichText(
          text: TextSpan(
            style: const TextStyle(
              color: Color(0xFF78716C),
              fontSize: 14,
              height: 1.4,
            ),
            children: [
              TextSpan(
                text: '$label: ',
                style: const TextStyle(
                  color: Color(0xFFC94F1B),
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(text: value),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8C7B8),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFC94F1B),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF292524),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}