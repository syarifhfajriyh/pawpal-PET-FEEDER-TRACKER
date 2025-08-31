import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw FirebaseAuthException(
          code: 'no-user',
          message: 'No signed-in user.',
        );
      }

      final currentPwd = _currentCtrl.text.trim();
      final newPwd = _newCtrl.text.trim();

      // Try update immediately; if backend requires recent login, we reauth below.
      try {
        await user.updatePassword(newPwd);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          // Reauthenticate with current password, then update.
          final cred = EmailAuthProvider.credential(
            email: user.email!,
            password: currentPwd,
          );
          await user.reauthenticateWithCredential(cred);
          await user.updatePassword(newPwd);
        } else {
          rethrow;
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully.')),
      );
      Navigator.pop(context); // go back to previous screen
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Failed to change password.');
    } catch (e) {
      setState(() => _error = 'Failed to change password: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_error!, style: const TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _currentCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current password',
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter your current password' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _newCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New password',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter a new password';
                    if (v.length < 6) return 'Use at least 6 characters';
                    if (v == _currentCtrl.text.trim()) {
                      return 'New password must be different from current password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm new password',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirm your new password';
                    if (v.trim() != _newCtrl.text.trim()) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _submitting ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _changePassword,
                        child: _submitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Update password'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
