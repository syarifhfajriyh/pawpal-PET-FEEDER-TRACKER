import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/FeederService.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User History for admins: Cat Detection and Food Weight.
/// Robust to different timestamp formats and shows sample data if Firestore is empty.
class AdminUserHistoryPage extends StatefulWidget {
  const AdminUserHistoryPage({super.key, this.initialQuery});
  final String? initialQuery;

  @override
  State<AdminUserHistoryPage> createState() => _AdminUserHistoryPageState();
}

class _AdminUserHistoryPageState extends State<AdminUserHistoryPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  int _rangeIndex = 0; // 0=24h, 1=7d, 2=30d, 3=All

  static const _prefsRangeKey = 'admin_history_range_index';
  static const _prefsQueryKey = 'admin_history_query';

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchCtrl.text = widget.initialQuery!;
      _query = widget.initialQuery!.toLowerCase();
    }
    _loadPrefs();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('User History'),
          backgroundColor: const Color(0xFFFFF3C4),
          foregroundColor: const Color(0xFF0E2A47),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.pets), text: 'Cat Detection'),
              Tab(icon: Icon(Icons.scale), text: 'Food Weight'),
            ],
          ),
        ),
        backgroundColor: const Color(0xFFFFFDF3),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() {
                  _query = v.trim().toLowerCase();
                  _saveQuery();
                }),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Filter by email or username',
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: _searchCtrl.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchCtrl.clear();
                              _query = '';
                              _saveQuery();
                            });
                          },
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      children: [
                        for (final entry in const [
                          ['24h', 0],
                          ['7d', 1],
                          ['30d', 2],
                          ['All', 3],
                        ])
                          ChoiceChip(
                            label: Text(entry[0] as String),
                            selected: _rangeIndex == (entry[1] as int),
                            onSelected: (_) => setState(() {
                              _rangeIndex = entry[1] as int;
                              _saveRange();
                            }),
                          ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _searchCtrl.clear();
                        _query = '';
                        _rangeIndex = 0; // default to 24h
                      });
                      _saveQuery();
                      _saveRange();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                  )
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _CatDetectionHistoryTab(filter: _query, cutoff: _cutoff()),
                  _FoodWeightHistoryTab(filter: _query, cutoff: _cutoff()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DateTime? _cutoff() {
    final now = DateTime.now();
    switch (_rangeIndex) {
      case 0:
        return now.subtract(const Duration(hours: 24));
      case 1:
        return now.subtract(const Duration(days: 7));
      case 2:
        return now.subtract(const Duration(days: 30));
      default:
        return null; // All
    }
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idx = prefs.getInt(_prefsRangeKey);
      final q = prefs.getString(_prefsQueryKey);
      if (idx != null && mounted) {
        setState(() => _rangeIndex = idx);
      }
      if (q != null && q.isNotEmpty && mounted && (widget.initialQuery == null || widget.initialQuery!.isEmpty)) {
        setState(() {
          _searchCtrl.text = q;
          _query = q.toLowerCase();
        });
      }
    } catch (_) {
      // ignore: no persistent storage available
    }
  }

  Future<void> _saveRange() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsRangeKey, _rangeIndex);
    } catch (_) {
      // ignore
    }
  }

  Future<void> _saveQuery() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsQueryKey, _searchCtrl.text);
    } catch (_) {}
  }
}

class _CatDetectionHistoryTab extends StatelessWidget {
  const _CatDetectionHistoryTab({required this.filter, required this.cutoff});
  final String filter;
  final DateTime? cutoff;

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('cat_detection_history')
        .orderBy('timestamp', descending: true);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
          // Fallback to device telemetry if collection is empty
          final feeder = FeederService();
          return StreamBuilder<List<TelemetryEntry>>(
            stream: feeder.streamTelemetry(feeder.defaultDeviceId),
            builder: (context, tSnap) {
              if (tSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (tSnap.hasError) {
                return Center(child: Text('Error: ${tSnap.error}'));
              }
              final items = (tSnap.data ?? const <TelemetryEntry>[]) 
                  .where((e) => e.catDetected != null)
                  .map((e) => _CatDet.fromMap({
                        'timestamp': e.timestamp,
                        'detected': e.catDetected == true,
                      }))
                  .where((e) => _within(e.time, cutoff))
                  .toList();
              return _historyList(items);
            },
          );
        }
        final items = docs
            .map((d) => _CatDet.fromMap(d.data()))
            .where((e) => _matchUser(e.userEmail, e.username, filter) && _within(e.time, cutoff))
            .toList();
        return _historyList(items);
      },
    );
  }

  Widget _historyList(List<_CatDet> items) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final it = items[index];
        final detected = it.detected == true;
        final icon = detected ? Icons.pets : Icons.pets_outlined;
        final color = detected ? Colors.green : Colors.black87;
        return ListTile(
          leading: Icon(icon, color: color),
          title: Text(detected ? 'Cat Detected' : 'No Cat Detected', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          subtitle: Text('${it.userEmail ?? 'unknown'} • ${_fmt(it.time)}'),
        );
      },
    );
  }
}

class _FoodWeightHistoryTab extends StatelessWidget {
  const _FoodWeightHistoryTab({required this.filter, required this.cutoff});
  final String filter;
  final DateTime? cutoff;

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('food_weight_history')
        .orderBy('timestamp', descending: true);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
          // Fallback to device telemetry if collection is empty
          final feeder = FeederService();
          return StreamBuilder<List<TelemetryEntry>>(
            stream: feeder.streamTelemetry(feeder.defaultDeviceId),
            builder: (context, tSnap) {
              if (tSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (tSnap.hasError) {
                return Center(child: Text('Error: ${tSnap.error}'));
              }
              final items = (tSnap.data ?? const <TelemetryEntry>[]) 
                  .where((e) => e.foodWeightGrams != null)
                  .map((e) => _FoodLog.fromMap({
                        'timestamp': e.timestamp,
                        'weight': e.foodWeightGrams,
                      }))
                  .where((e) => _within(e.time, cutoff))
                  .toList();
              return _list(items);
            },
          );
        }
        final items = docs
            .map((d) => _FoodLog.fromMap(d.data()))
            .where((e) => _matchUser(e.userEmail, e.username, filter) && _within(e.time, cutoff))
            .toList();
        return _list(items);
      },
    );
  }

  Widget _list(List<_FoodLog> items) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final it = items[index];
        final low = (it.weight ?? 0) < 150;
        final color = low ? Colors.red : Colors.black87;
        return ListTile(
          leading: Icon(Icons.scale, color: color),
          title: Text('${it.weight ?? '-'} g', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          subtitle: Text('${it.userEmail ?? 'unknown'} • ${_fmt(it.time)}'),
        );
      },
    );
  }
}

class _CatDet {
  _CatDet({required this.userEmail, required this.username, required this.time, required this.detected});
  final String? userEmail;
  final String? username;
  final DateTime? time;
  final bool? detected;

  static _CatDet fromMap(Map<String, dynamic> data) {
    return _CatDet(
      userEmail: data['userEmail']?.toString() ?? data['user']?.toString(),
      username: data['username']?.toString() ?? data['displayName']?.toString() ?? data['userName']?.toString(),
      time: _parseTs(data['timestamp']),
      detected: data['detected'] is bool
          ? data['detected'] as bool
          : (data['status']?.toString().toLowerCase() == 'detected'),
    );
  }
}

class _FoodLog {
  _FoodLog({required this.userEmail, required this.username, required this.time, required this.weight});
  final String? userEmail;
  final String? username;
  final DateTime? time;
  final num? weight;

  static _FoodLog fromMap(Map<String, dynamic> data) {
    final w = data['weight'] ?? data['grams'] ?? data['foodWeight'];
    return _FoodLog(
      userEmail: data['userEmail']?.toString() ?? data['user']?.toString(),
      username: data['username']?.toString() ?? data['displayName']?.toString() ?? data['userName']?.toString(),
      time: _parseTs(data['timestamp']),
      weight: (w is num) ? w : num.tryParse(w?.toString() ?? ''),
    );
  }
}

// ---- Helpers ----
DateTime? _parseTs(dynamic ts) {
  try {
    if (ts == null) return null;
    if (ts is Timestamp) return ts.toDate();
    if (ts is DateTime) return ts;
    if (ts is int) {
      // Heuristic: treat 13-digit as ms, 10-digit as s
      if (ts > 100000000000) {
        return DateTime.fromMillisecondsSinceEpoch(ts, isUtc: true).toLocal();
      }
      return DateTime.fromMillisecondsSinceEpoch(ts * 1000, isUtc: true).toLocal();
    }
    if (ts is String) {
      // Try ISO or numeric
      final asInt = int.tryParse(ts);
      if (asInt != null) return _parseTs(asInt);
      return DateTime.tryParse(ts)?.toLocal();
    }
  } catch (_) {}
  return null;
}

String _fmt(DateTime? d) {
  if (d == null) return '-';
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  final hh = d.hour.toString().padLeft(2, '0');
  final mi = d.minute.toString().padLeft(2, '0');
  return '${d.year}-$mm-$dd $hh:$mi';
}

bool _matchUser(String? email, String? username, String filter) {
  if (filter.isEmpty) return true;
  final hay = '${(email ?? '').toLowerCase()} ${(username ?? '').toLowerCase()}';
  return hay.contains(filter);
}

bool _within(DateTime? t, DateTime? cutoff) {
  if (cutoff == null) return true;
  if (t == null) return false;
  return t.isAfter(cutoff);
}
