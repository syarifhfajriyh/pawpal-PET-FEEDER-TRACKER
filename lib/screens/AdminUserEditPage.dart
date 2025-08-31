import 'package:flutter/material.dart';
import '../services/FirestoreService.dart';
import '../services/FunctionsService.dart';
import '../services/AuthService.dart';

class AdminUserEditPage extends StatefulWidget {
  const AdminUserEditPage({
    super.key,
    required this.userId,
    required this.initialData,
  });

  final String userId;
  final Map<String, dynamic> initialData;

  @override
  State<AdminUserEditPage> createState() => _AdminUserEditPageState();
}

class _AdminUserEditPageState extends State<AdminUserEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _fs = FirestoreService();
  final _fx = FunctionsService();
  final _auth = AuthService();

  late final TextEditingController _nameCtl;
  late final TextEditingController _avatarCtl;
  late int _role; // 0=user, 1=admin
  bool _saving = false;
  bool get _isMe => _auth.currentUser?.uid == widget.userId;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    _nameCtl = TextEditingController(text: (data['displayName'] ?? '').toString());
    _avatarCtl = TextEditingController(text: (data['avatarUrl'] ?? '').toString());
    final r = data['role'];
    _role = (r is int) ? r : (r == 'admin' ? 1 : 0);
    if (_isMe && _role != 1) _role = 1;
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _avatarCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (_isMe && _role != 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot demote your own admin account.')),
        );
        return;
      }
      // Update profile fields
      await _fs.updateUserByAdmin(
        uid: widget.userId,
        displayName: _nameCtl.text.trim(),
        avatarUrl: _avatarCtl.text.trim(),
      );
      // Set role through Cloud Function (also sets custom claims)
      await _fx.setUserRole(uid: widget.userId, role: _role);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User updated')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmAndDelete() async {
    if (_isMe) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot delete your own account.')),
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete user?'),
        content: const Text('This action is permanent.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _saving = true);
      try {
        await _fx.deleteUserAccount(uid: widget.userId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted')),
        );
        Navigator.of(context).pop(true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.initialData;
    final email = (data['email'] ?? '-') as String;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit User'),
        actions: [
          IconButton(
            tooltip: 'Delete user',
            onPressed: (_saving || _isMe) ? null : _confirmAndDelete,
            icon: const Icon(Icons.delete),
            color: Colors.red,
          ),
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving…' : 'Save'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text('Email', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(email, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtl,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _avatarCtl,
                decoration: const InputDecoration(
                  labelText: 'Avatar URL (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _role,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('user (0)')),
                  DropdownMenuItem(value: 1, child: Text('admin (1)')),
                ],
                onChanged: (v) => setState(() => _role = v ?? 0),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save),
                label: Text(_saving ? 'Saving…' : 'Save'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Note: Editing is limited to Firestore profile fields. '
                'Changing an account\'s email/password requires server-side admin privileges.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
