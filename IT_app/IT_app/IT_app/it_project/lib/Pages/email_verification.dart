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

class _EmailVerificationPageState
    extends State<EmailVerificationPage> {
  bool _isResending = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void initState() {
    super.initState();

    if (!widget.emailSent) {
      _message = 'Your account was created, but we could not send the '
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
      appBar: AppBar(
        title: const Text('Verify your email'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 64,
                  color: Color(0xFFC94F1B),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Check your email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'A confirmation link has been requested for '
                      '${AuthStore.maskEmail(widget.email)}. '
                      'Open the email and click the confirmation link '
                      'to verify your account.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'After confirming your email, return to the app '
                      'and log in. If you do not receive the email, '
                      'you can request another confirmation email below.',
                  textAlign: TextAlign.center,
                ),
                if (_message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _messageIsError
                          ? Colors.red.shade700
                          : Colors.green.shade700,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isResending ? null : _resendEmail,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: _isResending
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Text('Resend confirmation email'),
                ),
                TextButton(
                  onPressed: _isResending ? null : _goToLogin,
                  child: const Text('I have verified my email - go to login'),
                ),
              ],
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
        builder: (_) => LoginPage(initialEmail: widget.email),
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
        _message = 'Unable to resend the email. Please try again.';
        _messageIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }
}