import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  static const Color _orange = Color(0xFFC94F1B);
  static const Color _cream = Color(0xFFFFF8F4);
  static const Color _darkText = Color(0xFF292524);
  static const Color _secondaryText = Color(0xFF78716C);
  static const Color _borderColor = Color(0xFFE8C7B8);

  static final _emailPattern = RegExp(
    r'^[^\s@]+@(gmail|yahoo|outlook|hotmail|live|microsoft)\.com$',
    caseSensitive: false,
  );

  @override
  Widget build(BuildContext context) {
    final user = AuthStore.currentUser;
    final isSupervisor = user?.isStaff == true;

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: pagePrimaryColor(isSupervisor: isSupervisor),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
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

      // Full-screen background
      body: SizedBox.expand(
        child: Container(
          decoration: isSupervisor
              ? pageBackgroundDecoration(isSupervisor: isSupervisor)
              : const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF8F4), Color(0xFFFFE9DC)],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile icon
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
                          Icons.person,
                          size: 65,
                          color: _orange,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'Edit your profile',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _darkText,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Update your personal information and account security.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _secondaryText,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 38),

                  // Name card
                  _profileCard(
                    icon: Icons.person_outline,
                    label: 'Name',
                    value: user?.fullName ?? 'Not set',
                    onTap: _showNameDialog,
                  ),

                  // Email card
                  _profileCard(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: user?.email ?? 'Not set',
                    onTap: _showEmailDialog,
                  ),

                  // Registered area card (residential users only).
                  if (user != null && !user.isStaff && !user.isAdmin)
                    _profileCard(
                      icon: Icons.location_on_outlined,
                      label: 'Registered Area',
                      value: user.ward,
                      onTap: _showAreaDialog,
                    ),

                  // Password card
                  _profileCard(
                    icon: Icons.lock_outline,
                    label: 'Password',
                    value: 'Change your password',
                    onTap: _showPasswordDialog,
                  ),

                  const SizedBox(height: 24),

                  // Done button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: _orange.withValues(alpha: 0.25),
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
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

  // Profile information cards
  Widget _profileCard({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1.2),
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1E8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: _orange, size: 26),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: _orange,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        value,
                        style: const TextStyle(
                          color: _darkText,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(Icons.chevron_right, color: _orange),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showInfoDialog(String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (infoContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(color: _darkText, fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: _secondaryText,
            fontSize: 15,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(infoContext),
            style: TextButton.styleFrom(foregroundColor: _orange),
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

  // Shows a dialog with the given fields.
  // onSave runs when Save is pressed and the form is valid.
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
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: _darkText,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
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
              onPressed: saving
                  ? null
                  : () => Navigator.pop(dialogContext, false),
              style: TextButton.styleFrom(foregroundColor: _orange),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: saving
                  ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );

    return saved ?? false;
  }

  Future<void> _showAreaDialog() async {
    final api = AuthApi();
    try {
      final wards = await api.getWards();
      if (!mounted) return;
      if (wards.isEmpty) {
        _showMessage('No wards are available.');
        return;
      }

      final currentUser = AuthStore.currentUser;
      int? selectedWard;
      int? selectedArea = currentUser?.areaId;
      List<Map<String, dynamic>> areas = [];

      // Preselect the ward that contains the user's current area.
      if (selectedArea != null) {
        for (final ward in wards) {
          final wardId = (ward['id'] as num).toInt();
          final wardAreas = await api.getAreasForWard(wardId);
          if (wardAreas.any((a) => a['id'] == selectedArea)) {
            selectedWard = wardId;
            areas = wardAreas;
            break;
          }
        }
      }
      if (!mounted) return;
      bool loading = false;
      String? errorMessage;
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: const Text('Change registered area'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your existing reports will remain linked to their original areas. '
                        'Your dashboard will use the newly selected area.',
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<int>(
                    value: selectedWard,
                    isExpanded: true,
                    decoration: _fieldDecoration('Ward'),
                    items: wards.map((ward) => DropdownMenuItem<int>(
                      value: (ward['id'] as num).toInt(),
                      child: Text(ward['name'].toString()),
                    )).toList(),
                    onChanged: loading ? null : (value) async {
                      if (value == null) return;
                      setDialogState(() {
                        selectedWard = value;
                        selectedArea = null;
                        areas = [];
                        loading = true;
                        errorMessage = null;
                      });
                      try {
                        final loaded = await api.getAreasForWard(value);
                        if (!dialogContext.mounted) return;
                        setDialogState(() => areas = loaded);
                      } on AuthApiException catch (error) {
                        if (!dialogContext.mounted) return;
                        setDialogState(() => errorMessage = error.message);
                      } catch (_) {
                        if (!dialogContext.mounted) return;
                        setDialogState(() => errorMessage = 'Could not load areas.');
                      } finally {
                        if (dialogContext.mounted) {
                          setDialogState(() => loading = false);
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: selectedArea,
                    isExpanded: true,
                    decoration: _fieldDecoration('Area'),
                    items: areas.map((area) => DropdownMenuItem<int>(
                      value: (area['id'] as num).toInt(),
                      child: Text(area['name'].toString(),
                          overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: loading ? null : (value) {
                      setDialogState(() => selectedArea = value);
                    },
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: loading ? null : () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: loading || selectedArea == null ||
                    selectedArea == currentUser?.areaId
                    ? null
                    : () async {
                  setDialogState(() {
                    loading = true;
                    errorMessage = null;
                  });
                  try {
                    await AuthStore.updateRegisteredArea(selectedArea!);
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext, true);
                  } on AuthApiException catch (error) {
                    if (!dialogContext.mounted) return;
                    setDialogState(() => errorMessage = error.message);
                  } catch (_) {
                    if (!dialogContext.mounted) return;
                    setDialogState(() => errorMessage =
                    'Unable to update area. Please try again.');
                  } finally {
                    if (dialogContext.mounted) {
                      setDialogState(() => loading = false);
                    }
                  }
                },
                child: loading
                    ? const SizedBox(height: 18, width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save Area'),
              ),
            ],
          ),
        ),
      );
      if (result == true && mounted) {
        setState(() {});
        _showMessage('Registered area updated successfully.');
      }
    } on AuthApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('Unable to load wards. Please try again.');
    } finally {
      api.close();
    }
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
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[^a-zA-Z\s]'))],
          decoration: _fieldDecoration('Full name'),
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
          decoration: _fieldDecoration('New email'),
          validator: (value) {
            final email = value?.trim().toLowerCase() ?? '';

            if (email.isEmpty) {
              return 'Please enter the new email';
            }

            if (!_emailPattern.hasMatch(email)) {
              return 'Use a Gmail, Yahoo, Outlook, or Microsoft email';
            }

            return null;
          },
        ),

        const SizedBox(height: 12),

        _VisibilityPasswordField(
          controller: passwordController,
          decoration: _fieldDecoration('Current password'),
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
        _VisibilityPasswordField(
          controller: currentController,
          decoration: _fieldDecoration('Current password'),
          validator: (value) => (value == null || value.isEmpty)
              ? 'Please enter your current password'
              : null,
        ),

        const SizedBox(height: 12),

        _VisibilityPasswordField(
          controller: newController,
          decoration: _fieldDecoration('New password'),
          validator: _validateNewPassword,
        ),

        const SizedBox(height: 12),

        _VisibilityPasswordField(
          controller: confirmController,
          decoration: _fieldDecoration('Confirm new password'),
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

  // Styling for the form fields in the dialogs.
  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _secondaryText),
      floatingLabelStyle: const TextStyle(color: _orange),
      filled: true,
      fillColor: _cream,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _orange, width: 1.5),
      ),
    );
  }

  String? _validateNewPassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Please enter a new password';
    }

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

// Independent show/hide control for password fields in Edit Profile dialogs.
class _VisibilityPasswordField extends StatefulWidget {
  const _VisibilityPasswordField({
    required this.controller,
    required this.decoration,
    this.validator,
  });

  final TextEditingController controller;
  final InputDecoration decoration;
  final FormFieldValidator<String>? validator;

  @override
  State<_VisibilityPasswordField> createState() =>
      _VisibilityPasswordFieldState();
}

class _VisibilityPasswordFieldState extends State<_VisibilityPasswordField> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: !_isVisible,
      validator: widget.validator,
      decoration: widget.decoration.copyWith(
        suffixIcon: IconButton(
          tooltip: _isVisible ? 'Hide password' : 'Show password',
          icon: Icon(
            _isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: const Color(0xFFC94F1B),
          ),
          onPressed: () => setState(() => _isVisible = !_isVisible),
        ),
      ),
    );
  }
}
