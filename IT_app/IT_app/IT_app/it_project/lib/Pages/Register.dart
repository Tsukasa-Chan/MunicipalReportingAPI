import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth_api.dart';
import 'auth_store.dart';
import 'email_verification.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({this.authApi, super.key});

  final AuthApi? authApi;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  late final AuthApi _authApi;
  late final bool _ownsAuthApi;
  bool _authApiTransferred = false;

  bool _isRegistering = false;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  int? selectedWard;
  String? selectedCommunityArea;

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _ownsAuthApi = widget.authApi == null;
    _authApi = widget.authApi ?? AuthApi();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Center(
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 16),
                  const Text(
                    'Register',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _field(
                    controller: fullNameController,
                    label: 'Full Name',
                    validator: (value) => _required(value, 'full name'),
                  ),
                  const SizedBox(height: 14),

                  _field(
                    controller: emailController,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    inputFormatters: [LowerCaseTextFormatter()],
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 14),

                  DropdownButtonFormField<int>(
                    initialValue: selectedWard,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Ward',
                    ),
                    items: AuthStore.wardAreas.keys
                        .map(
                          (ward) => DropdownMenuItem<int>(
                        value: ward,
                        child: Text(
                          'Ward $ward',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                        .toList(),
                    validator: (value) =>
                    value == null ? 'Please select your ward' : null,
                    onChanged: (ward) {
                      setState(() {
                        selectedWard = ward;
                        selectedCommunityArea = null;
                      });
                    },
                  ),

                  if (selectedWard != null) ...[
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCommunityArea,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Area',
                      ),
                      items:
                      (AuthStore.wardAreas[selectedWard] ?? const <String>[])
                          .map(
                            (area) => DropdownMenuItem<String>(
                          value: area,
                          child: Text(
                            area,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                          .toList(),
                      validator: (value) => value == null
                          ? 'Please select your area'
                          : null,
                      onChanged: (area) {
                        setState(() {
                          selectedCommunityArea = area;
                        });
                      },
                    ),
                  ],

                  const SizedBox(height: 14),

                  _field(
                    controller: passwordController,
                    label: 'Password',
                    obscureText: !isPasswordVisible,
                    suffixIcon: IconButton(
                      tooltip: isPasswordVisible
                          ? 'Hide password'
                          : 'Show password',
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                    ),
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 14),

                  _field(
                    controller: confirmPasswordController,
                    label: 'Confirm Password',
                    obscureText: !isConfirmPasswordVisible,
                    suffixIcon: IconButton(
                      tooltip: isConfirmPasswordVisible
                          ? 'Hide password'
                          : 'Show password',
                      icon: Icon(
                        isConfirmPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          isConfirmPasswordVisible =
                          !isConfirmPasswordVisible;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }

                      if (value != passwordController.text) {
                        return 'Security prompt: your passwords do not match';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 5),
                  const Text(
                    'Password must:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    '- Contain 8 or more characters '
                        '\n- At least one uppercase character '
                        '\n- At least one lowercase character '
                        '\n- At least one number',
                  ),

                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _isRegistering ? null : _register,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: _isRegistering
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : const Text('Register'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Container(
        width: 78,
        height: 78,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.location_city_rounded,
          size: 42,
          color: Color(0xFFC94F1B),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    bool obscureText = false,
    int? maxLength,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      maxLength: maxLength,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        border: const OutlineInputBorder(),
        suffixIcon: suffixIcon,
      ),
    );
  }

  String? _required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your $fieldName';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    final emailPattern = RegExp(
      r'^[^\s@]+@(gmail|yahoo|outlook|hotmail|live|microsoft)\.com$',
      caseSensitive: false,
    );

    if (email.isEmpty) {
      return 'Please enter your email';
    }

    if (email != email.toLowerCase()) {
      return 'Email must be in lower case';
    }

    if (!emailPattern.hasMatch(email)) {
      return 'Use a Gmail, Yahoo, Outlook, or Microsoft email';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';

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

  int? _getAreaId(int wardNumber, String areaName) {
    final areas = AuthStore.wardAreas[wardNumber];

    if (areas == null) return null;

    final areaIndex = areas.indexOf(areaName);

    if (areaIndex == -1) return null;

    // These IDs match the area IDs seeded in the backend.
    switch (wardNumber) {
      case 58:
        return areaIndex + 1;
      case 61:
        return areaIndex + 14;
      case 62:
        return areaIndex + 24;
      default:
        return null;
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isRegistering = true);

    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text;
    final wardNumber = selectedWard;
    final wardLocation = selectedCommunityArea;

    if (wardNumber == null || wardLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your ward and area.'),
        ),
      );

      setState(() => _isRegistering = false);
      return;
    }

    final areaId = _getAreaId(wardNumber, wardLocation);

    if (areaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The selected area could not be found.'),
        ),
      );

      setState(() => _isRegistering = false);
      return;
    }

    try {
      final result = await _authApi.register(
        fullName: fullName,
        email: email,
        password: password,
        areaId: areaId,
      );

      // The account is created even when the email could not be sent.
      final emailSent = result['emailSent'] != false;

      if (!mounted) return;

      // The verification page now owns and closes this AuthApi.
      _authApiTransferred = true;

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EmailVerificationPage(
            email: email,
            authApi: _authApi,
            emailSent: emailSent,
          ),
        ),
      );
    } on AuthApiException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration failed. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false);
      }
    }
  }

  @override
  void dispose() {
    if (_ownsAuthApi && !_authApiTransferred) {
      _authApi.close();
    }

    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }
}

class LowerCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    return newValue.copyWith(
      text: newValue.text.toLowerCase(),
      selection: newValue.selection,
    );
  }
}