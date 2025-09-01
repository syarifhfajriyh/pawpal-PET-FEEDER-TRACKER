import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/AuthService.dart';

class AdminChangePasswordPage extends StatefulWidget {
  const AdminChangePasswordPage({super.key});

  @override
  State<AdminChangePasswordPage> createState() =>
      _AdminChangePasswordPageState();
}

class _AdminChangePasswordPageState extends State<AdminChangePasswordPage> {
  final _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _currentCtl = TextEditingController();
  final _newCtl = TextEditingController();
  final _confirmCtl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _currentCtl.dispose();
    _newCtl.dispose();
    _confirmCtl.dispose();
    super.dispose();
  }

  Future<void> _change() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final email = _auth.currentUser!.email!;
      await _auth.reauthWithPassword(email, _currentCtl.text.trim());
      await _auth.updatePassword(_newCtl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated')),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? e.code)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin • Change Password')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _currentCtl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newCtl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New password',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v.length < 6) return 'Min 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmCtl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v != _newCtl.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loading ? null : _change,
                icon: const Icon(Icons.lock_reset),
                label: Text(_loading ? 'Updating…' : 'Update password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
