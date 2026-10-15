import 'package:flutter/material.dart';

import 'auth_api.dart';
import 'auth_store.dart';
import 'ForgetPassword.dart';
import 'Home.dart';
import 'Supervisor_dash.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({this.initialEmail, this.authApi, super.key});

  // Filled in after registering so the user does not retype it.
  final String? initialEmail;
  final AuthApi? authApi;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  late final AuthApi _authApi;
  late final bool _ownsAuthApi;

  bool _isLoggingIn = false;
  bool _isResending = false;
  bool _showResend = false;
  String? _errorMessage;
  String? _infoMessage;

  bool isPasswordVisible = false;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _ownsAuthApi = widget.authApi == null;
    _authApi = widget.authApi ?? AuthApi();
    emailController.text = widget.initialEmail ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
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
                    'Login',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  _field(
                    controller: emailController,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
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
                      onPressed: () => setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      }),
                    ),
                    validator: _validatePassword,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ],
                  if (_infoMessage != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _infoMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.green.shade700),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoggingIn ? null : _login,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                          child: _isLoggingIn
                              ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                              : const Text('Login'),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                  if (_showResend)
                    TextButton(
                      onPressed: _isResending ? null : _resendConfirmation,
                      child: Text(
                        _isResending
                            ? 'Sending...'
                            : 'Resend confirmation email',
                      ),
                    ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ForgotPage()),
                    ),
                    child: const Text('Forgot Password'),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.asset(
          'lib/img/app logo.png',
          width: 110,
          height: 90,
          fit: BoxFit.cover,
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
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      maxLength: maxLength,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: const OutlineInputBorder(),
        suffixIcon: suffixIcon,
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Please enter your email';
    if (!email.contains('@')) return 'Please enter a valid email';
    return null;
  }

  // Only checks that something was typed. The password rules are enforced
  // when registering, and the backend decides if the login is correct.
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password';
    return null;
  }

  Future<void> _login() async {
    if (_isLoggingIn) return;
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoggingIn = true;
      _errorMessage = null;
      _infoMessage = null;
      _showResend = false;
    });

    try {
      final tokens = await _authApi.login(
        email: emailController.text,
        password: passwordController.text,
      );

      final accessToken = tokens['token']?.toString() ?? '';
      final refreshToken = tokens['refreshToken']?.toString() ?? '';

      if (accessToken.isEmpty || refreshToken.isEmpty) {
        throw const AuthApiException(
          'The server did not return a valid session. Please try again.',
        );
      }

      // Role, name and area come from the backend, not from the device.
      final profile = await _authApi.getCurrentUser(
        accessToken: accessToken,
      );

      AuthStore.signIn(
        profile: profile,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      if (!mounted) return;

      final user = AuthStore.currentUser;
      final destination = user?.isSupervisor == true
          ? const SupervisorDashboardPage()
          : const HomePage();

      // Clear the login screens so Back cannot return to them.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => destination),
            (route) => false,
      );
    } on AuthApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.message;
        _showResend = error.isEmailNotVerified;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Login failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoggingIn = false);
      }
    }
  }

  Future<void> _resendConfirmation() async {
    if (_isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final message = await _authApi.resendEmailConfirmation(
        email: emailController.text,
      );

      if (!mounted) return;

      setState(() => _infoMessage = message);
    } on AuthApiException catch (error) {
      if (!mounted) return;

      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to resend the email. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  void dispose() {
    if (_ownsAuthApi) {
      _authApi.close();
    }

    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}