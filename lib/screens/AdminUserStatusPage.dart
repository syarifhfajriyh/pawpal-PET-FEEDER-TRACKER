import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Displays the current status of users.
/// Reads from the `paw_user` collection in Firestore.
class AdminUserStatusPage extends StatelessWidget {
  const AdminUserStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance.collection('paw_user');

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Status'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No user status found.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final email = data['email']?.toString() ?? 'unknown';
              final status = data['status']?.toString() ?? 'n/a';
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(email),
                subtitle: Text('Status: $status'),
              );
            },
          );
        },
      ),
    );
  }
}
