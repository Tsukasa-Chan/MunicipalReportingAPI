import 'package:flutter/material.dart';

import 'Help.dart';
import 'StartUp.dart';
import 'auth_api.dart';
import 'auth_store.dart';
import 'Supervisor_theme.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static final _emailPattern = RegExp(
    r'^[^\s@]+@(gmail|yahoo|outlook|hotmail|live|microsoft)\.com$',
    caseSensitive: false,
  );

  @override
  Widget build(BuildContext context) {
    final user = AuthStore.currentUser;
    final isSupervisor = user?.isStaff == true;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: pagePrimaryColor(isSupervisor: isSupervisor),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: Color(0xFFC94F1B),
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Edit your profile',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                _profileCard(
                  icon: Icons.person_outline,
                  label: 'Name',
                  value: user?.fullName ?? 'Not set',
                  onTap: _showNameDialog,
                ),
                _profileCard(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: user?.email ?? 'Not set',
                  onTap: _showEmailDialog,
                ),
                _profileCard(
                  icon: Icons.lock_outline,
                  label: 'Password',
                  value: 'Change your password',
                  onTap: _showPasswordDialog,
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileCard({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white.withValues(alpha: 0.82),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        leading: Icon(icon, color: const Color(0xFFC94F1B)),
        title: Text(
          label,
          style: const TextStyle(
            color: Color(0xFFC94F1B),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            color: Color(0xFF1F1F1F),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showInfoDialog(String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (infoContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(infoContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Used when the saved login can no longer be used.
  void _goToStart() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const StartupPage()),
          (_) => false,
    );
  }

  // Shows a dialog with the given fields. onSave runs when Save is pressed
  // and the form is valid. If it throws an AuthApiException, the message is
  // shown in the dialog. Returns true when the save worked.
  Future<bool> _showActionDialog({
    required String title,
    required GlobalKey<FormState> formKey,
    required List<Widget> fields,
    required Future<void> Function() onSave,
  }) async {
    var saving = false;
    String? error;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...fields,
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        error!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed:
              saving ? null : () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                if (!formKey.currentState!.validate()) return;

                setDialogState(() {
                  saving = true;
                  error = null;
                });

                try {
                  await onSave();

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext, true);
                  }
                } on AuthApiException catch (e) {
                  if (!dialogContext.mounted) return;

                  if (e.isSessionExpired) {
                    Navigator.pop(dialogContext, false);
                    _goToStart();
                    return;
                  }

                  setDialogState(() {
                    saving = false;
                    error = e.message;
                  });
                } catch (_) {
                  if (!dialogContext.mounted) return;

                  setDialogState(() {
                    saving = false;
                    error = 'Something went wrong. Please try again.';
                  });
                }
              },
              child: saving
                  ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );

    return saved ?? false;
  }

  Future<void> _showNameDialog() async {
    final controller = TextEditingController(
      text: AuthStore.currentUser?.fullName ?? '',
    );

    final saved = await _showActionDialog(
      title: 'Edit name',
      formKey: GlobalKey<FormState>(),
      fields: [
        TextFormField(
          controller: controller,
          maxLength: 100,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Full name'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your name';
            }
            return null;
          },
        ),
      ],
      onSave: () async {
        await AuthStore.updateFullName(controller.text);
      },
    );

    if (saved && mounted) {
      setState(() {});
      _showMessage('Name updated.');
    }
  }

  Future<void> _showEmailDialog() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String? serverMessage;

    final saved = await _showActionDialog(
      title: 'Change email',
      formKey: GlobalKey<FormState>(),
      fields: [
        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'New email'),
          validator: (value) {
            final email = value?.trim().toLowerCase() ?? '';
            if (email.isEmpty) return 'Please enter the new email';
            if (!_emailPattern.hasMatch(email)) {
              return 'Use a Gmail, Yahoo, Outlook, or Microsoft email';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Current password'),
          validator: (value) => (value == null || value.isEmpty)
              ? 'Please enter your current password'
              : null,
        ),
      ],
      onSave: () async {
        serverMessage = await AuthStore.requestEmailChange(
          newEmail: emailController.text,
          currentPassword: passwordController.text,
        );
      },
    );

    if (!saved || !mounted) return;

    await _showInfoDialog(
      'Check your new email',
      '${serverMessage ?? 'A confirmation link has been sent.'}\n\n'
          'After you click the link, log in again with your new email.',
    );
  }

  Future<void> _showPasswordDialog() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    final saved = await _showActionDialog(
      title: 'Change password',
      formKey: GlobalKey<FormState>(),
      fields: [
        TextFormField(
          controller: currentController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Current password'),
          validator: (value) => (value == null || value.isEmpty)
              ? 'Please enter your current password'
              : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: newController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'New password'),
          validator: _validateNewPassword,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: confirmController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Confirm new password'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your new password';
            }
            if (value != newController.text) {
              return 'Your passwords do not match';
            }
            return null;
          },
        ),
      ],
      onSave: () async {
        await AuthStore.changePassword(
          currentPassword: currentController.text,
          newPassword: newController.text,
        );
      },
    );

    if (!saved || !mounted) return;

    await _showInfoDialog(
      'Password changed',
      'Your password was changed. Please log in again with your new password.',
    );

    if (!mounted) return;
    _goToStart();
  }

  String? _validateNewPassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) return 'Please enter a new password';

    if (password.length < 8) {
      return 'Password must be 8 characters or more';
    }

    if (!RegExp(r'[A-Z]').hasMatch(password) ||
        !RegExp(r'[a-z]').hasMatch(password) ||
        !RegExp(r'[0-9]').hasMatch(password)) {
      return 'Use uppercase, lowercase, and a number';
    }

    if (!RegExp(r'^[A-Za-z0-9@#_]+$').hasMatch(password)) {
      return 'Only letters, numbers, @, #, and _ are allowed';
    }

    return null;
  }
}