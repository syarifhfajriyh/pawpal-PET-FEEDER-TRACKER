import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/AuthService.dart';
import '../services/databaseUser.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final db = DatabaseUser();
    final uid = auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feeding History'),
      ),
      body: (uid == null)
          ? const Center(child: Text('No user logged in'))
          : FutureBuilder<QuerySnapshot>(
              future: db.getUserHistory(uid),
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
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final ts = data['timestamp'] as Timestamp?;
                    final time = ts?.toDate() ?? DateTime.now();
                    final grams = data['portionSize'] ?? data['grams'] ?? '-';
                    final note = data['note'] ?? data['action'] ?? '';

                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.history)),
                      title: Text('${grams}g • $note'),
                      subtitle: Text(_formatDateTime(time)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Fed ${grams}g ($note)')),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  String _formatDateTime(DateTime dt) {
    // e.g. "Sun, 25 Aug 2025 • 14:05"
    final w = _weekday[dt.weekday]!;
    final m = _month[dt.month]!;
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$w, ${dt.day} $m ${dt.year} • $hh:$mm';
  }
}

const _weekday = {
  1: 'Mon',
  2: 'Tue',
  3: 'Wed',
  4: 'Thu',
  5: 'Fri',
  6: 'Sat',
  7: 'Sun',
};

const _month = {
  1: 'Jan',
  2: 'Feb',
  3: 'Mar',
  4: 'Apr',
  5: 'May',
  6: 'Jun',
  7: 'Jul',
  8: 'Aug',
  9: 'Sep',
  10: 'Oct',
  11: 'Nov',
  12: 'Dec',
};
