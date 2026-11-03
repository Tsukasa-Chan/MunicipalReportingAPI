
import 'package:flutter/material.dart';

import 'auth_api.dart';
import 'auth_store.dart';

class ForgotPage extends StatefulWidget {
  const ForgotPage({this.authApi, super.key});

  final AuthApi? authApi;

  @override
  State<ForgotPage> createState() => _ForgotPageState();
}

class _ForgotPageState extends State<ForgotPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();

  late final AuthApi _authApi;
  late final bool _ownsAuthApi;

  static const Color _orange = Color(0xFFC94F1B);
  static const Color _cream = Color(0xFFFFF8F4);
  static const Color _darkText = Color(0xFF292524);
  static const Color _secondaryText = Color(0xFF78716C);
  static const Color _borderColor = Color(0xFFE8C7B8);

  bool _isSending = false;
  bool _emailSent = false;
  String _sentTo = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _ownsAuthApi = widget.authApi == null;
    _authApi = widget.authApi ?? AuthApi();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,

      appBar: AppBar(
        title: const Text(
          'Forgot Password',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      // Full-screen cream-to-peach background
      body: SizedBox.expand(
        child: Container(
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
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 40,
              ),
              child: _emailSent
                  ? _buildSentView()
                  : _buildFormView(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Forgot password icon
          _buildLogo(),

          const SizedBox(height: 32),

          // Heading
          const Text(
            'Forgot Password',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: _darkText,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 10),

          // Description
          const Text(
            'Enter your email and we will send you a link to choose a new password.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: _secondaryText,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 38),

          // Email field
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textCapitalization: TextCapitalization.none,
            validator: _validateEmail,
            style: const TextStyle(
              color: _darkText,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'example@gmail.com',
              prefixIcon: const Icon(
                Icons.email_outlined,
                color: _orange,
              ),
              labelStyle: const TextStyle(
                color: _secondaryText,
              ),
              floatingLabelStyle: const TextStyle(
                color: _orange,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: _borderColor,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: _borderColor,
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: _orange,
                  width: 1.5,
                ),
              ),
            ),
          ),

          // Error message
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Send reset link button
          _actionButton(
            label: 'Send reset link',
            onPressed: _isSending ? null : _sendLink,
            isLoading: _isSending,
          ),

          const SizedBox(height: 12),

          // Back button
          TextButton(
            onPressed: _isSending
                ? null
                : () => Navigator.pop(context),
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email sent icon
        _buildIconContainer(
          Icons.mark_email_read_outlined,
        ),

        const SizedBox(height: 32),

        // Confirmation heading
        const Text(
          'Check your email',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: _darkText,
            letterSpacing: 0.5,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          'If an account exists for ${AuthStore.maskEmail(_sentTo)}, we have '
              'sent a link to reset your password.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            color: _secondaryText,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 12),

        const Text(
          'Open the email and click the link to choose a new password. '
              'Then come back here and log in.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: _secondaryText,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 38),

        // Back to login button
        _actionButton(
          label: 'Back to login',
          onPressed: () => Navigator.pop(context),
        ),

        const SizedBox(height: 12),

        // Use another email
        TextButton(
          onPressed: () => setState(() => _emailSent = false),
          style: TextButton.styleFrom(
            foregroundColor: _orange,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
          ),
          child: const Text(
            'Use a different email',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // Forgot password logo
  Widget _buildLogo() {
    return _buildIconContainer(
      Icons.lock_reset_outlined,
    );
  }

  // Rounded icon container matching the other pages
  Widget _buildIconContainer(IconData icon) {
    return Center(
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
          child: Icon(
            icon,
            size: 65,
            color: _orange,
          ),
        ),
      ),
    );
  }

  // Orange buttons matching the Startup page
  Widget _actionButton({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _orange,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: _orange.withValues(alpha: 0.25),
          padding: const EdgeInsets.symmetric(
            vertical: 17,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Text(
          label,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  // Only checks the email format.
  // The backend decides whether an account exists.
  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Please enter your email';
    }

    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Please enter a valid email';
    }

    return null;
  }

  // Send password reset link through the backend
  Future<void> _sendLink() async {
    if (_isSending) return;
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    final email = emailController.text.trim().toLowerCase();

    try {
      await _authApi.forgotPassword(email: email);

      if (!mounted) return;

      setState(() {
        _emailSent = true;
        _sentTo = email;
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
        'Unable to send the reset email. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  void dispose() {
    if (_ownsAuthApi) {
      _authApi.close();
    }

    emailController.dispose();
    super.dispose();
  }
}
