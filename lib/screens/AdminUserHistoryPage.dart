import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Displays recent user activity logs for administrators.
/// Reads documents from the `admin_history` collection in Firestore.
class AdminUserHistoryPage extends StatelessWidget {
  const AdminUserHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('admin_history')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User History'),
        backgroundColor: const Color(0xFFFFF3C4),
        foregroundColor: const Color(0xFF0E2A47),
      ),
      backgroundColor: const Color(0xFFFFFDF3),
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
            return const Center(child: Text('No history found.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final action = data['action']?.toString() ?? 'unknown';
              final user = data['userEmail']?.toString() ??
                  data['user']?.toString() ??
                  '';
              final ts = (data['timestamp'] as Timestamp?)?.toDate();
              final timeStr = ts != null ? ts.toLocal().toString() : '';
              final subtitle =
                  [user, timeStr].where((s) => s.isNotEmpty).join(' • ');
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(action),
                subtitle: Text(subtitle),
              );
            },
          );
        },
      ),
    );
  }
}
