
import 'package:flutter/material.dart';

import 'auth_api.dart';
import 'auth_store.dart';
import 'login.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({
    required this.email,
    required this.authApi,
    this.emailSent = true,
    super.key,
  });

  final String email;
  final AuthApi authApi;

  // False when the account was created but the backend could not send the email.
  final bool emailSent;

  @override
  State<EmailVerificationPage> createState() =>
      _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  static const Color _orange = Color(0xFFC94F1B);
  static const Color _cream = Color(0xFFFFF8F4);
  static const Color _darkText = Color(0xFF292524);
  static const Color _secondaryText = Color(0xFF78716C);
  static const Color _borderColor = Color(0xFFE8C7B8);

  bool _isResending = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void initState() {
    super.initState();

    if (!widget.emailSent) {
      _message =
      'Your account was created, but we could not send the '
          'email. Tap the button below to try again.';
      _messageIsError = true;
    }
  }

  @override
  void dispose() {
    widget.authApi.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,

      appBar: AppBar(
        title: const Text(
          'Verify your email',
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

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Email verification icon
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
                          Icons.mark_email_unread_outlined,
                          size: 65,
                          color: _orange,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Verification heading
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

                  // Confirmation instructions
                  Text(
                    'A confirmation link has been requested for '
                        '${AuthStore.maskEmail(widget.email)}. '
                        'Open the email and click the confirmation link '
                        'to verify your account.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: _secondaryText,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'After confirming your email, return to the app '
                        'and log in. If you do not receive the email, '
                        'you can request another confirmation email below.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: _secondaryText,
                      height: 1.5,
                    ),
                  ),

                  // Success or error message
                  if (_message != null) ...[
                    const SizedBox(height: 20),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _messageIsError
                              ? Colors.red.shade300
                              : Colors.green.shade300,
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        _message!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: _messageIsError
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 38),

                  // Resend confirmation email button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                      _isResending ? null : _resendEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor:
                        _orange.withValues(alpha: 0.25),
                        padding: const EdgeInsets.symmetric(
                          vertical: 17,
                          horizontal: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(14),
                        ),
                      ),

                      child: _isResending
                          ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Text(
                        'Resend confirmation email',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Go to login button
                  TextButton(
                    onPressed:
                    _isResending ? null : _goToLogin,
                    style: TextButton.styleFrom(
                      foregroundColor: _orange,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'I have verified my email - go to login',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _goToLogin() {
    // Keep only the welcome screen underneath, and fill in the email.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => LoginPage(
          initialEmail: widget.email,
        ),
      ),
          (route) => route.isFirst,
    );
  }

  Future<void> _resendEmail() async {
    if (_isResending) return;

    setState(() {
      _isResending = true;
      _message = null;
    });

    try {
      final response = await widget.authApi
          .resendEmailConfirmation(email: widget.email);

      if (!mounted) return;

      setState(() {
        _message = response.isNotEmpty
            ? response
            : 'A confirmation email has been requested.';
        _messageIsError = false;
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _message = error.message;
        _messageIsError = true;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _message =
        'Unable to resend the email. Please try again.';
        _messageIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }
}
