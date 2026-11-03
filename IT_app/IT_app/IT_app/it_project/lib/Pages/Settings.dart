
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'Help.dart';
import 'OtherReports.dart';
import 'Profile.dart';
import 'Reporting.dart';
import 'auth_store.dart';
import 'Supervisor_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with WidgetsBindingObserver {
  static const Color _orange = Color(0xFFC94F1B);
  static const Color _cream = Color(0xFFFFF8F4);
  static const Color _darkText = Color(0xFF292524);
  static const Color _secondaryText = Color(0xFF78716C);
  static const Color _borderColor = Color(0xFFE8C7B8);

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
      _locationEnabled =
          locationStatus.isGranted || locationStatus.isLimited;
      _cameraEnabled =
          cameraStatus.isGranted || cameraStatus.isLimited;
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
      backgroundColor: _cream,

      appBar: AppBar(
        backgroundColor: pagePrimaryColor(
          isSupervisor: isSupervisor,
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'FIX MY CITY',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Help',
            icon: const Icon(
              Icons.help_outline,
              color: Colors.white,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const HelpPage(),
              ),
            ),
          ),
        ],
      ),

      // Full-screen background
      body: SizedBox.expand(
        child: Container(
          decoration: isSupervisor
              ? pageBackgroundDecoration(
            isSupervisor: isSupervisor,
          )
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Settings icon
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: _orange.withValues(alpha: 0.12),
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
                          Icons.settings_outlined,
                          size: 65,
                          color: _orange,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'Settings',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: _darkText,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Manage your app preferences and permissions.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: _secondaryText,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 38),

                  // Device permissions
                  _sectionTitle('DEVICE PERMISSIONS'),

                  const SizedBox(height: 4),

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
                            (value) => setState(
                              () => _locationEnabled = value,
                        ),
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
                            (value) => setState(
                              () => _cameraEnabled = value,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Information section
                  _sectionTitle('INFORMATION'),

                  const SizedBox(height: 4),

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
                    onTap: () => _showInformationDialog(
                      context,
                      title: 'Privacy Policy',
                      message:
                      'Your account information is used to manage reports and provide support. Keep your login details private.',
                    ),
                  ),

                  const SizedBox(height: 24),

                  // App issues section
                  _sectionTitle('APP ISSUES'),

                  const SizedBox(height: 4),

                  _bubbleButton(
                    context,
                    icon: Icons.bug_report_outlined,
                    label: 'Report a Bug in App',
                    onTap: () => _showBugReportDialog(context),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),

      // Original bottom navigation functionality
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: pagePrimaryColor(
          isSupervisor: isSupervisor,
        ),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const OtherReportsPage(),
              ),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ReportingPage(),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProfilePage(),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'View Complaints',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'New Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // Permission cards
  Widget _permissionSwitchTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _borderColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _orange.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeTrackColor: _orange,
        activeThumbColor: Colors.white,
        inactiveTrackColor: const Color(0xFFE7E5E4),
        inactiveThumbColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        secondary: Container(
          padding: const EdgeInsets.all(10),
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
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _darkText,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: _secondaryText,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  // Section headings
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: _darkText,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  // Information and app issue buttons
  Widget _bubbleButton(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onTap,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _borderColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _orange.withValues(alpha: 0.08),
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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            child: Row(
              children: [
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

                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _darkText,
                    ),
                  ),
                ),

                const Icon(
                  Icons.chevron_right,
                  color: _orange,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Information dialogs
  void _showInformationDialog(
      BuildContext context, {
        required String title,
        required String message,
      }) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: _borderColor,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: _darkText,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cream,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message,
            style: const TextStyle(
              color: _secondaryText,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: _orange,
            ),
            child: const Text(
              'Close',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Bug report dialog
  void _showBugReportDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final issueController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: _borderColor,
          ),
        ),
        title: const Text(
          'Report a Bug in App',
          style: TextStyle(
            color: _darkText,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  style: const TextStyle(
                    color: _darkText,
                  ),
                  decoration: _inputDecoration('Name'),
                  validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Please enter your name'
                      : null,
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    color: _darkText,
                  ),
                  decoration: _inputDecoration('Email'),
                  validator: (value) =>
                  value == null || !value.contains('@')
                      ? 'Please enter a valid email'
                      : null,
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: issueController,
                  maxLines: 3,
                  style: const TextStyle(
                    color: _darkText,
                  ),
                  decoration: _inputDecoration(
                    'Type of issue',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) =>
                  value == null || value.trim().isEmpty
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
            style: TextButton.styleFrom(
              foregroundColor: _secondaryText,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;

              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bug report submitted.'),
                ),
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

  // Form field styling
  InputDecoration _inputDecoration(
      String label, {
        bool alignLabelWithHint = false,
      }) {
    return InputDecoration(
      labelText: label,
      alignLabelWithHint: alignLabelWithHint,
      labelStyle: const TextStyle(
        color: _secondaryText,
      ),
      floatingLabelStyle: const TextStyle(
        color: _orange,
      ),
      filled: true,
      fillColor: _cream,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: _borderColor,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: _borderColor,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: _orange,
          width: 1.5,
        ),
      ),
    );
  }
}
