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
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: _emailSent ? _buildSentView() : _buildFormView(),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLogo(),
          const SizedBox(height: 16),
          const Text(
            'Forgot Password',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Enter your email and we will send you a link to choose a '
                'new password.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textCapitalization: TextCapitalization.none,
            validator: _validateEmail,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'example@gmail.com',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSending ? null : _sendLink,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: _isSending
                ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text('Send reset link'),
          ),
          TextButton(
            onPressed: _isSending ? null : () => Navigator.pop(context),
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildSentView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        const Icon(
          Icons.mark_email_read_outlined,
          size: 64,
          color: Color(0xFFC94F1B),
        ),
        const SizedBox(height: 16),
        const Text(
          'Check your email',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          'If an account exists for ${AuthStore.maskEmail(_sentTo)}, we have '
              'sent a link to reset your password.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Open the email and click the link to choose a new password. '
              'Then come back here and log in.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
          child: const Text('Back to login'),
        ),
        TextButton(
          onPressed: () => setState(() => _emailSent = false),
          child: const Text('Use a different email'),
        ),
      ],
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

  // Only checks that it looks like an email. The backend decides if an
  // account exists. Admin and supervisor accounts can use other domains.
  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) return 'Please enter your email';

    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Please enter a valid email';
    }

    return null;
  }

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

      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to send the reset email. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
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