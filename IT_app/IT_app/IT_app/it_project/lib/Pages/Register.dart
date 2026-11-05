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
      backgroundColor: const Color(0xFFFFF8F4),
      appBar: AppBar(
        title: const Text(
          'Register',
          style: TextStyle(
            color: Color(0xFF292524),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFFFF8F4),
        foregroundColor: const Color(0xFF292524),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF8F4),
              Color(0xFFFFE9DC),
            ],
          ),
        ),
        child: Form(
          key: _formKey,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFC94F1B).withOpacity(0.08),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLogo(),

                    const SizedBox(height: 22),

                    const Text(
                      'Create Account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF292524),
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Join your community and help make a difference.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF78716C),
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 30),

                    _field(
                      controller: fullNameController,
                      label: 'Full Name',
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'[^a-zA-Z\s]')),
                      ],
                      validator: (value) => _required(value, 'full name'),
                    ),

                    const SizedBox(height: 18),

                    _field(
                      controller: emailController,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      inputFormatters: [LowerCaseTextFormatter()],
                      validator: _validateEmail,
                    ),

                    const SizedBox(height: 18),

                    DropdownButtonFormField<int>(
                      initialValue: selectedWard,
                      isExpanded: true,
                      decoration: _dropdownDecoration('Ward'),
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
                      const SizedBox(height: 18),

                      DropdownButtonFormField<String>(
                        initialValue: selectedCommunityArea,
                        isExpanded: true,
                        decoration: _dropdownDecoration('Area'),
                        items: (AuthStore.wardAreas[selectedWard] ??
                            const <String>[])
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

                    const SizedBox(height: 18),

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
                          color: const Color(0xFF9A6A55),
                        ),
                        onPressed: () {
                          setState(() {
                            isPasswordVisible = !isPasswordVisible;
                          });
                        },
                      ),
                      validator: _validatePassword,
                    ),

                    const SizedBox(height: 18),

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
                          color: const Color(0xFF9A6A55),
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
                          return 'Your passwords do not match';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Password requirements
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8F4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFE8C7B8),
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                color: Color(0xFFC94F1B),
                                size: 19,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Password must:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF292524),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          _PasswordRequirement(
                            text: 'Contain 8 or more characters',
                          ),
                          _PasswordRequirement(
                            text: 'At least one uppercase character',
                          ),
                          _PasswordRequirement(
                            text: 'At least one lowercase character',
                          ),
                          _PasswordRequirement(
                            text: 'At least one number',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),

                    ElevatedButton(
                      onPressed: _isRegistering ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC94F1B),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFE8A184),
                        elevation: 4,
                        shadowColor:
                        const Color(0xFFC94F1B).withOpacity(0.25),
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isRegistering
                          ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
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
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC94F1B).withOpacity(0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.asset(
            'lib/img/app logo.png',
            width: 110,
            height: 90,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFF9A6A55),
      ),
      filled: true,
      fillColor: const Color(0xFFFFF8F4),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Color(0xFFE8C7B8),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Color(0xFFE8C7B8),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Color(0xFFC94F1B),
          width: 1.8,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
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
      style: const TextStyle(
        color: Color(0xFF292524),
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: const TextStyle(
          color: Color(0xFF9A6A55),
        ),
        filled: true,
        fillColor: const Color(0xFFFFF8F4),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: Color(0xFFE8C7B8),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: Color(0xFFE8C7B8),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: Color(0xFFC94F1B),
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: Colors.red,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1.5,
          ),
        ),
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

class _PasswordRequirement extends StatelessWidget {
  const _PasswordRequirement({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Color(0xFFC94F1B),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF78716C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
