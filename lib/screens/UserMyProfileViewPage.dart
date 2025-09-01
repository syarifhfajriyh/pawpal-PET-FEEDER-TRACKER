import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/AuthService.dart';
import '../services/FirestoreService.dart';
import 'ProfilePage.dart';

class UserMyProfileViewPage extends StatelessWidget {
  const UserMyProfileViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final uid = auth.currentUser?.uid;
    final fs = FirestoreService();
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Not signed in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Edit profile',
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: fs.streamUser(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final data = snapshot.data?.data() ?? <String, dynamic>{};

          final email =
              (data['email'] as String?) ?? auth.currentUser?.email ?? '-';
          final name =
              (data['displayName'] as String?) ?? email.split('@').first;
          final username = (data['username'] as String?) ?? '';
          final bio = (data['bio'] as String?) ?? '';
          final petName = (data['petName'] as String?) ?? '';
          final petType = (data['petType'] as String?) ?? '';
          final notifEnabled = (data['notifEnabled'] as bool?) ?? false;
          final avatar = (data['avatarUrl'] as String?) ?? '';

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
                          style: const TextStyle(
                              fontSize: 28, fontWeight: FontWeight.w700),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  name,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 16),
              _tile('Email', email, Icons.mail),
              _tile('Username', username, Icons.alternate_email),
              _tile('Bio', bio, Icons.info_outline),
              _tile('Pet name', petName, Icons.pets),
              _tile('Pet type', petType, Icons.category_outlined),
              SwitchListTile(
                value: notifEnabled,
                onChanged: null,
                title: const Text('Notifications'),
                subtitle: const Text('Feeding reminders & device alerts'),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit Profile'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(String label, String value, IconData icon) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label,
          style: const TextStyle(fontSize: 12, color: Colors.black54)),
      subtitle: Text(value.isEmpty ? '-' : value,
          style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
