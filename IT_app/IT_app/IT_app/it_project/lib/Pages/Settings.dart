import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'Help.dart';
import 'OtherReports.dart';
import 'Profile.dart';
import 'Reporting.dart';
import 'auth_store.dart';
import 'legal_documents.dart';
import 'Supervisor_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with WidgetsBindingObserver {
  bool _locationEnabled = false;
  bool _cameraEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPermissionStates();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadPermissionStates();
    }
  }

  Future<void> _loadPermissionStates() async {
    final locationStatus = await Permission.locationWhenInUse.status;
    final cameraStatus = await Permission.camera.status;

    if (!mounted) return;

    setState(() {
      _locationEnabled = locationStatus.isGranted || locationStatus.isLimited;
      _cameraEnabled = cameraStatus.isGranted || cameraStatus.isLimited;
    });
  }

  Future<void> _handlePermissionToggle(
      Permission permission,
      bool enabled,
      ValueChanged<bool> updateState,
      ) async {
    if (enabled) {
      final status = await permission.request();
      final granted = status.isGranted || status.isLimited;
      if (!mounted) return;

      if (granted) {
        updateState(true);
        return;
      }

      await openAppSettings();
      await _loadPermissionStates();
      return;
    }

    await openAppSettings();
    await _loadPermissionStates();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSupervisor = AuthStore.currentUser?.isStaff == true;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: pagePrimaryColor(isSupervisor: isSupervisor),
        title: const Text('FIX MY CITY'),
        actions: [
          IconButton(
            tooltip: 'Help',
            icon: const Icon(Icons.help_outline),
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
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'SETTINGS',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                _sectionTitle('DEVICE PERMISSIONS'),
                _permissionSwitchTile(
                  icon: Icons.location_on_outlined,
                  label: 'Location Permissions',
                  subtitle:
                  'Enable to let the app use your location when submitting reports.',
                  value: _locationEnabled,
                  onChanged: (enabled) async {
                    await _handlePermissionToggle(
                      Permission.locationWhenInUse,
                      enabled,
                          (value) => setState(() => _locationEnabled = value),
                    );
                  },
                ),
                _permissionSwitchTile(
                  icon: Icons.camera_alt_outlined,
                  label: 'Camera Permissions',
                  subtitle:
                  'Enable to allow the app to take photos for issue reports.',
                  value: _cameraEnabled,
                  onChanged: (enabled) async {
                    await _handlePermissionToggle(
                      Permission.camera,
                      enabled,
                          (value) => setState(() => _cameraEnabled = value),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _sectionTitle('INFORMATION'),
                _bubbleButton(
                  context,
                  icon: Icons.info_outline,
                  label: 'About App',
                  onTap: () => _showInformationDialog(
                    context,
                    title: 'About App',
                    message:
                    'Fix My City helps you report local issues and follow their progress.',
                  ),
                ),
                _bubbleButton(
                  context,
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacy Policy',
                  onTap: () => _showLegalDialog(
                    context,
                    title: privacyPolicyTitle,
                    text: privacyPolicyText,
                    fileName: privacyPolicyFileName,
                  ),
                ),
                _bubbleButton(
                  context,
                  icon: Icons.description_outlined,
                  label: 'Terms & Conditions',
                  onTap: () => _showLegalDialog(
                    context,
                    title: termsTitle,
                    text: termsText,
                    fileName: termsFileName,
                  ),
                ),
                const SizedBox(height: 20),
                _sectionTitle('APP ISSUES'),
                _bubbleButton(
                  context,
                  icon: Icons.bug_report_outlined,
                  label: 'Report a Bug in App',
                  onTap: () => _showBugReportDialog(context),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: pagePrimaryColor(isSupervisor: isSupervisor),
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OtherReportsPage()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportingPage()),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'View Complaints',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'New Report'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _permissionSwitchTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white.withValues(alpha: 0.88),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon, color: const Color(0xFFC94F1B)),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _bubbleButton(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onTap,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFFC94F1B)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showInformationDialog(
      BuildContext context, {
        required String title,
        required String message,
      }) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Text(message),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLegalDialog(
      BuildContext context, {
        required String title,
        required String text,
        required String fileName,
      }) {
    final messenger = ScaffoldMessenger.of(context);

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(child: Text(text)),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.download),
            label: const Text('Download'),
            onPressed: () async {
              try {
                final savedPath = await downloadPdfFile(fileName, title, text);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      savedPath == null || savedPath.isEmpty
                          ? '$title downloaded.'
                          : '$title saved.',
                    ),
                  ),
                );
              } catch (_) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Could not download the file.'),
                  ),
                );
              }
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showBugReportDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final issueController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Report a Bug in App'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter your name'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) => value == null || !value.contains('@')
                      ? 'Please enter a valid email'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: issueController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Type of issue',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please describe the issue'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bug report submitted.')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    ).whenComplete(() {
      nameController.dispose();
      emailController.dispose();
      issueController.dispose();
    });
  }
}
