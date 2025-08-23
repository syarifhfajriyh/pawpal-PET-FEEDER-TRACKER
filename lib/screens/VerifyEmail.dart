import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VerifyEmail extends StatefulWidget {
  const VerifyEmail({super.key});

  @override
  State<VerifyEmail> createState() => _VerifyEmailState();
}

class _VerifyEmailState extends State<VerifyEmail> {
  bool _sending = false;
  bool _checking = false;

  Future<void> _resend() async {
    setState(() => _sending = true);
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _iveVerified() async {
    setState(() => _checking = true);
    await FirebaseAuth.instance.currentUser?.reload();
    final ok = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
    if (!mounted) return;
    setState(() => _checking = false);

    if (ok) {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not verified yet — check your email.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify your email')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'We sent a verification link to your email.\n'
              'Open it to activate your account.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _sending ? null : _resend,
              child: Text(_sending ? 'Sending…' : 'Resend email'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _checking ? null : _iveVerified,
              child: Text(_checking ? 'Checking…' : "I've verified"),
            ),
          ],
        ),
      ),
    );
  }
}
