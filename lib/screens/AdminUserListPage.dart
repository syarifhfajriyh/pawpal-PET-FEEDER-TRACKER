import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/FirestoreService.dart';
import '../services/AuthService.dart';
import '../services/FunctionsService.dart';

import 'AdminUserEditPage.dart';
import 'AdminUserProfileViewPage.dart';
import 'AdminDispensePage.dart';
import 'VerifyEmail.dart';

class AdminUserListPage extends StatelessWidget {
  const AdminUserListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    final auth = AuthService();
    final fx = FunctionsService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        backgroundColor: const Color(0xFFFFF3C4),
        foregroundColor: const Color(0xFF0E2A47),
      ),
      backgroundColor: const Color(0xFFFFFDF3),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: fs.streamAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final d = docs[i];
              final data = d.data();
              final email = data['email'] as String? ?? '-';
              final name = data['displayName'] as String? ?? email.split('@').first;
              final rawRole = data['role'];
              final role = (rawRole is int)
                  ? (rawRole == 1 ? 'admin' : 'user')
                  : ((rawRole?.toString() ?? 'user'));
              final avatar = data['avatarUrl'] as String? ?? '';
              final isMe = d.id == auth.currentUser?.uid;
              final isAdmin = role == 'admin';

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (avatar.isNotEmpty) ? NetworkImage(avatar) : null,
                    child: (avatar.isEmpty)
                        ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?')
                        : null,
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('$email • $role'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'view') {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AdminUserProfileViewPage(userId: d.id),
                          ),
                        );
                      } else if (v == 'dispense') {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AdminDispensePage(
                              initialUserId: d.id,
                            ),
                          ),
                        );
                      } else if (v == 'reset') {
                        try {
                          await auth.sendPasswordResetEmail(email);
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Reset email sent to $email')),
                          );
                        } catch (e) {
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed: $e')),
                          );
                        }
                      } else if (v == 'edit') {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AdminUserEditPage(
                              userId: d.id,
                              initialData: data,
                            ),
                          ),
                        );
                      } else if (v == 'make_admin' || v == 'make_user') {
                        // Require verified email before calling admin Cloud Functions
                        final verified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
                        if (!verified) {
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please verify your email before performing admin actions.')),
                          );
                          // ignore: use_build_context_synchronously
                          await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const VerifyEmail()),
                          );
                          return;
                        }
                        final newRole = (v == 'make_admin') ? 1 : 0;
                        try {
                          await fx.setUserRole(uid: d.id, role: newRole);
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(newRole == 1
                                  ? 'Promoted to admin'
                                  : 'Demoted to user'),
                            ),
                          );
                        } catch (e) {
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed: $e')),
                          );
                        }
                      } else if (v == 'delete') {
                        if (isMe) {
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('You cannot delete your own account.')),
                          );
                          return;
                        }
                        // Require verified email before calling admin Cloud Functions
                        final verified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
                        if (!verified) {
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please verify your email before performing admin actions.')),
                          );
                          // ignore: use_build_context_synchronously
                          await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const VerifyEmail()),
                          );
                          return;
                        }
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete user?'),
                            content: Text('This will permanently delete $email.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          try {
                            await fx.deleteUserAccount(uid: d.id);
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('User deleted')),
                            );
                          } catch (e) {
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed: $e')),
                            );
                          }
                        }
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: ListTile(
                          leading: Icon(Icons.person),
                          title: Text('View profile'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'dispense',
                        child: ListTile(
                          leading: Icon(Icons.restaurant),
                          title: Text('Dispense food'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'reset',
                        child: ListTile(
                          leading: Icon(Icons.mail),
                          title: Text('Send password reset email'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit user'),
                        ),
                      ),
                      PopupMenuItem(
                        enabled: !(isMe && isAdmin),
                        value: isAdmin ? 'make_user' : 'make_admin',
                        child: ListTile(
                          leading: Icon(
                            isAdmin ? Icons.person_remove : Icons.admin_panel_settings,
                          ),
                          title: Text(isAdmin ? 'Demote to user' : 'Make admin'),
                        ),
                      ),
                      PopupMenuItem(
                        enabled: !isMe,
                        value: 'delete',
                        child: const ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Delete user'),
                        ),
                      ),
                    ],
                  ),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdminUserProfileViewPage(userId: d.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
