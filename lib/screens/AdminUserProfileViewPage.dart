import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import '../services/FirestoreService.dart';
import 'AdminUserEditPage.dart';

class AdminUserProfileViewPage extends StatelessWidget {
  const AdminUserProfileViewPage({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        actions: [
          IconButton(
            tooltip: 'Edit user',
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final snap = await fs.users.doc(userId).get();
              if (!context.mounted) return;
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AdminUserEditPage(
                    userId: userId,
                    initialData: (snap.data() ?? <String, dynamic>{}),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: fs.streamUser(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final data = snapshot.data?.data() ?? <String, dynamic>{};

          final email = (data['email'] as String?) ?? '-';
          final name = (data['displayName'] as String?) ?? email.split('@').first;
          final username = (data['username'] as String?) ?? '';
          final bio = (data['bio'] as String?) ?? '';
          final petName = (data['petName'] as String?) ?? '';
          final petType = (data['petType'] as String?) ?? '';
          final notifEnabled = (data['notifEnabled'] as bool?) ?? false;
          final avatar = (data['avatarUrl'] as String?) ?? '';
          final rawRole = data['role'];
          final role = (rawRole is int)
              ? (rawRole == 1 ? 'admin' : 'user')
              : ((rawRole?.toString() ?? 'user'));
          final emailVerified = (data['emailVerified'] as bool?)
                  ?.toString()
                  .toLowerCase() ==
              'true'
              ? 'Verified'
              : 'Unverified';

          String _fmtTs(dynamic ts) {
            try {
              if (ts is Timestamp) {
                final d = ts.toDate().toLocal();
                final mm = d.month.toString().padLeft(2, '0');
                final dd = d.day.toString().padLeft(2, '0');
                final hh = d.hour.toString().padLeft(2, '0');
                final mi = d.minute.toString().padLeft(2, '0');
                return '${d.year}-$mm-$dd $hh:$mi';
              }
            } catch (_) {}
            return '-';
          }
          final createdAt = _fmtTs(data['createdAt']);
          final lastSeen = _fmtTs(data['lastSeen']);

          ImageProvider<Object>? avatarProvider() {
            if (avatar.isNotEmpty) return NetworkImage(avatar);
            return null;
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: const Color(0xFF0E2A47).withOpacity(0.1),
                  backgroundImage: avatarProvider(),
                  child: avatar.isEmpty
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(role, style: const TextStyle(color: Colors.black54)),
              ),
              const SizedBox(height: 16),

              _ReadOnlyTile(
                label: 'Email',
                value: email,
                leading: Icons.mail,
                copyable: true,
                copyText: email,
              ),
              _ReadOnlyTile(
                label: 'UID',
                value: userId,
                leading: Icons.perm_identity,
                copyable: true,
                copyText: userId,
              ),
              _ReadOnlyTile(label: 'Username', value: username, leading: Icons.alternate_email),
              _ReadOnlyTile(label: 'Bio', value: bio, leading: Icons.info_outline),
              _ReadOnlyTile(label: 'Pet name', value: petName, leading: Icons.pets),
              _ReadOnlyTile(label: 'Pet type', value: petType, leading: Icons.category_outlined),
              _ReadOnlyTile(label: 'Verification', value: emailVerified, leading: Icons.verified_user_outlined),
              SwitchListTile(
                value: notifEnabled,
                onChanged: null,
                title: const Text('Notifications'),
                subtitle: const Text('Feeding reminders & device alerts'),
              ),

              const Divider(height: 24),
              _ReadOnlyTile(label: 'Created', value: createdAt, leading: Icons.event_available_outlined),
              _ReadOnlyTile(label: 'Last seen', value: lastSeen, leading: Icons.schedule),

              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () async {
                  final snap = await fs.users.doc(userId).get();
                  if (!context.mounted) return;
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AdminUserEditPage(
                        userId: userId,
                        initialData: (snap.data() ?? <String, dynamic>{}),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit User'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReadOnlyTile extends StatelessWidget {
  const _ReadOnlyTile({
    required this.label,
    required this.value,
    required this.leading,
    this.copyable = false,
    this.copyText,
  });
  final String label;
  final String value;
  final IconData leading;
  final bool copyable;
  final String? copyText;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(leading),
      title: Text(label, style: Theme.of(context).textTheme.labelMedium),
      subtitle: Text(value.isEmpty ? '-' : value,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: copyable
          ? IconButton(
              tooltip: 'Copy',
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () async {
                final text = (copyText == null || copyText!.isEmpty) ? value : copyText!;
                await Clipboard.setData(ClipboardData(text: text));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                }
              },
            )
          : null,
    );
  }
}
