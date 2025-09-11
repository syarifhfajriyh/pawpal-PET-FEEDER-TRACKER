import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/FeederService.dart';
import '../services/FirestoreService.dart';
import '../widgets/InstantFeed.dart';

class AdminDispensePage extends StatefulWidget {
  const AdminDispensePage({super.key, this.deviceId, this.initialUserId});

  final String? deviceId;
  final String? initialUserId;

  @override
  State<AdminDispensePage> createState() => _AdminDispensePageState();
}

class _AdminDispensePageState extends State<AdminDispensePage> {
  final _feeder = FeederService();
  final _fs = FirestoreService();

  bool _loading = false;
  bool _error = false;
  String _message = "Select user, portion, then Feed Now.";

  String? _targetUid;
  String? _targetLabel; // email / name for UI
  String? _targetDeviceId; // optional: if user doc stores a deviceId

  @override
  void initState() {
    super.initState();
    // Preselect user if provided.
    if (widget.initialUserId != null && widget.initialUserId!.isNotEmpty) {
      _targetUid = widget.initialUserId;
      // Try to read once to populate label & device id.
      _fs.users.doc(widget.initialUserId!).get().then((snap) {
        if (!mounted) return;
        final m = snap.data() ?? <String, dynamic>{};
        final email = (m['email'] as String?) ?? '-';
        final name = (m['displayName'] as String?) ?? email.split('@').first;
        final label = name.isNotEmpty ? '$name · $email' : email;
        final deviceId = (m['deviceId'] ?? m['feederId'] ?? m['device'] ?? m['pawFeederId'])?.toString();
        setState(() {
          _targetLabel = label;
          _targetDeviceId = deviceId;
        });
      }).catchError((_) {});
    }
  }

  Future<void> _feedNow(String portion) async {
    if (_targetUid == null) {
      setState(() {
        _error = true;
        _message = 'Please select a user first.';
      });
      return;
    }
    // portion like "400g" => parse to int 400
    final grams = int.tryParse(portion.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (grams <= 0) {
      setState(() {
        _error = true;
        _message = 'Invalid portion: $portion';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = false;
      _message = 'Dispensing ${grams}g…';
    });

    try {
      final adminUid = FirebaseAuth.instance.currentUser?.uid;
      await _feeder.dispense(
        // Prefer selected user's device if known; else widget.deviceId; else default.
        deviceId: _targetDeviceId ?? widget.deviceId,
        grams: grams,
        byUid: _targetUid,
        byRole: 'admin',
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = false;
        _message = 'Dispensed ${grams}g for $_targetLabel';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dispensed ${grams}g for $_targetLabel')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
        _message = 'Failed to dispense: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispense Food (Admin)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Instant Feed',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Pick a user, choose portion, then tap Feed Now to command that user\'s feeder.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            // User picker
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _fs.streamAllUsers(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                final items = docs
                    .map((d) {
                      final m = d.data();
                      final email = (m['email'] as String?) ?? '-';
                      final name = (m['displayName'] as String?) ?? email.split('@').first;
                      final label = name.isNotEmpty ? '$name · $email' : email;
                      // Try to pick a device id if present under common keys.
                      final deviceId = (m['deviceId'] ?? m['feederId'] ?? m['device'] ?? m['pawFeederId'])?.toString();
                      return {
                        'uid': d.id,
                        'label': label,
                        'deviceId': deviceId,
                      };
                    })
                    .toList();

                final currentValue = items.any((m) => m['uid'] == _targetUid) ? _targetUid : null;
                return DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Select user',
                    border: OutlineInputBorder(),
                  ),
                  value: currentValue,
                  items: items
                      .map((m) => DropdownMenuItem<String>(
                            value: m['uid'] as String,
                            child: Text(m['label'] as String),
                          ))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _targetUid = v;
                      final pick = items.firstWhere(
                        (m) => m['uid'] == v,
                        orElse: () => {'label': 'user', 'deviceId': null},
                      );
                      _targetLabel = pick['label'];
                      _targetDeviceId = pick['deviceId'];
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            InstantFeed(
              loading: _loading,
              error: _error,
              message: _message,
              onFeedNow: _feedNow,
              onSelect: (_) {},
            ),
          ],
        ),
      ),
    );
  }
}
