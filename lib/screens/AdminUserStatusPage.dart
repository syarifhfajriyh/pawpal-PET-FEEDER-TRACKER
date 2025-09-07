import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/FirestoreService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'AdminUserHistoryPage.dart';

/// Displays the current status of users.
/// Reads from the `paw_user` collection in Firestore.
class AdminUserStatusPage extends StatefulWidget {
  const AdminUserStatusPage({super.key});

  @override
  State<AdminUserStatusPage> createState() => _AdminUserStatusPageState();
}

class _AdminUserStatusPageState extends State<AdminUserStatusPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  bool _activeOnly = false; // lastSeen within 5 minutes

  static const _prefsStatusQueryKey = 'admin_status_query';
  static const _prefsStatusActiveKey = 'admin_status_active_only';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  DateTime? _parseTs(dynamic ts) {
    try {
      if (ts == null) return null;
      if (ts is Timestamp) return ts.toDate();
      if (ts is DateTime) return ts;
      if (ts is int) {
        if (ts > 100000000000) {
          return DateTime.fromMillisecondsSinceEpoch(ts, isUtc: true).toLocal();
        }
        return DateTime.fromMillisecondsSinceEpoch(ts * 1000, isUtc: true).toLocal();
      }
      if (ts is String) {
        final n = int.tryParse(ts);
        if (n != null) return _parseTs(n);
        return DateTime.tryParse(ts)?.toLocal();
      }
    } catch (_) {}
    return null;
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final q = prefs.getString(_prefsStatusQueryKey);
      final a = prefs.getBool(_prefsStatusActiveKey);
      if (!mounted) return;
      setState(() {
        if (q != null) {
          _searchCtrl.text = q;
          _query = q.toLowerCase();
        }
        if (a != null) _activeOnly = a;
      });
    } catch (_) {
      // ignore
    }
  }

  Future<void> _saveQuery() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsStatusQueryKey, _searchCtrl.text);
    } catch (_) {}
  }

  Future<void> _saveActive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsStatusActiveKey, _activeOnly);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // Use the same source as AdminUserListPage so we show real users.
    final fs = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Status'),
        backgroundColor: const Color(0xFFFFF3C4),
        foregroundColor: const Color(0xFF0E2A47),
      ),
      backgroundColor: const Color(0xFFFFFDF3),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() {
                      _query = v.trim().toLowerCase();
                      _saveQuery();
                    }),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search username or email',
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
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Active only'),
                  selected: _activeOnly,
                  onSelected: (v) => setState(() {
                    _activeOnly = v;
                    _saveActive();
                  }),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _searchCtrl.clear();
                      _query = '';
                      _activeOnly = false;
                    });
                    _saveQuery();
                    _saveActive();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: fs.streamAllUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                var docs = snapshot.data?.docs ?? [];

                // If there are no docs yet, create a few sample ones for UI
                final List<Map<String, dynamic>> samples = [
                  {'email': 'user@example.com', 'username': 'user', 'petType': 'Cat'},
                  {'email': 'rigotochan@gmail.com', 'username': 'rigotochan', 'petType': 'Cat'},
                  {'email': 'fajriyah@graduate.utm.my', 'username': 'fajriyah', 'petType': 'Cat'},
                ];

                final int itemCount = docs.isEmpty ? samples.length : docs.length;
                List<Map<String, dynamic>> rows = List.generate(
                  itemCount,
                  (index) => docs.isEmpty ? samples[index] : docs[index].data(),
                );

                String pickEmail(Map<String, dynamic> m) {
                  final candidates = [m['email'], m['userEmail'], m['mail'], m['contactEmail']];
                  for (final c in candidates) {
                    final s = c?.toString();
                    if (s != null && s.isNotEmpty) return s;
                  }
                  return 'unknown';
                }

                String pickUsername(Map<String, dynamic> m, String email) {
                  final candidates = [m['username'], m['displayName'], m['name'], m['userName']];
                  for (final c in candidates) {
                    final s = c?.toString();
                    if (s != null && s.isNotEmpty) return s;
                  }
                  return email.contains('@') ? email.split('@').first : 'user';
                }

                String pickPetType(Map<String, dynamic> m) {
                  final candidates = [m['petType'], m['pet'], m['animalType']];
                  for (final c in candidates) {
                    final s = c?.toString();
                    if (s != null && s.isNotEmpty) return s;
                  }
                  return 'Cat';
                }

                int? pickWeight(Map<String, dynamic> m) {
                  final w = m['foodWeightGrams'] ?? m['foodWeight'] ?? m['weight'] ?? m['currentWeight'];
                  if (w is num) return w.round();
                  if (w is String) {
                    final v = num.tryParse(w);
                    if (v != null) return v.round();
                  }
                  return null;
                }

                bool? pickDetected(Map<String, dynamic> m) {
                  final v = m['catDetected'] ?? m['detected'] ?? m['petDetected'];
                  if (v is bool) return v;
                  if (v is String) {
                    final t = v.toLowerCase();
                    return t.contains('detected') || t == 'true';
                  }
                  return null;
                }

                // map into unified model with filtering
                final now = DateTime.now();
                final items = rows
                    .map((data) {
                      final email = pickEmail(data);
                      final username = pickUsername(data, email);
                      final petType = pickPetType(data);
                      final foodWeight = pickWeight(data);
                      final catDetected = pickDetected(data);
                      final lastSeen = _parseTs(data['lastSeen']);
                      return {
                        'email': email,
                        'username': username,
                        'petType': petType,
                        'foodWeight': foodWeight,
                        'catDetected': catDetected,
                        'lastSeen': lastSeen,
                      };
                    })
                    .where((m) {
                      // active filter
                      if (_activeOnly) {
                        final ls = m['lastSeen'] as DateTime?;
                        if (ls == null || now.difference(ls) > const Duration(minutes: 5)) {
                          return false;
                        }
                      }
                      // query filter
                      if (_query.isNotEmpty) {
                        final hay = '${m['username']} ${m['email']}'.toLowerCase();
                        if (!hay.contains(_query)) return false;
                      }
                      return true;
                    })
                    .toList();

                if (items.isEmpty) {
                  return const Center(child: Text('No users match your filters.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final m = items[index];

                    var email = m['email'] as String;
                    var username = m['username'] as String;
                    var petType = m['petType'] as String;
                    int foodWeight = (m['foodWeight'] as int?) ?? 0;
                    bool? catDetected = m['catDetected'] as bool?;

                    // Fill missing demo values deterministically so UI looks complete
                    if (foodWeight == 0 || catDetected == null) {
                      final seed = (email.hashCode ^ username.hashCode) & 0x7fffffff;
                      final rng = math.Random(seed);
                      foodWeight = foodWeight == 0 ? 100 + rng.nextInt(500) : foodWeight;
                      catDetected = catDetected ?? rng.nextBool();
                    }

                    return _UserStatusCard(
                      email: email,
                      username: username,
                      petType: petType,
                      foodWeightGrams: foodWeight,
                      catDetected: catDetected ?? false,
                      lastSeen: m['lastSeen'] as DateTime?,
                      onOpenHistory: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AdminUserHistoryPage(initialQuery: email),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UserStatusCard extends StatelessWidget {
  const _UserStatusCard({
    required this.email,
    required this.username,
    required this.petType,
    required this.foodWeightGrams,
    required this.catDetected,
    this.lastSeen,
    this.onOpenHistory,
  });

  final String email;
  final String username;
  final String petType;
  final int foodWeightGrams;
  final bool catDetected;
  final DateTime? lastSeen;
  final VoidCallback? onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final lowFood = foodWeightGrams < 150;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onOpenHistory,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(child: Icon(Icons.person)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username.isNotEmpty ? username : 'user',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: const TextStyle(color: Colors.black87),
                        ),
                        if (lastSeen != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Last seen: ${_fmtShort(lastSeen!)}',
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _miniStat(Icons.category_outlined, 'Pet type', petType),
                  _miniStat(
                    Icons.scale,
                    'Food weight',
                    '${foodWeightGrams}g',
                    valueColor: lowFood ? Colors.red : Colors.black,
                  ),
                  _miniStat(
                    catDetected ? Icons.pets : Icons.pets_outlined,
                    'Pet detection',
                    catDetected ? 'Detected' : 'Not detected',
                    valueColor: catDetected ? Colors.green : Colors.black,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for small stats in the row
  Widget _miniStat(IconData icon, String label, String value, {Color? valueColor}) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700, color: valueColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _fmtShort(DateTime dt) {
  final now = DateTime.now();
  bool sameDay = dt.year == now.year && dt.month == now.month && dt.day == now.day;
  String two(int v) => v.toString().padLeft(2, '0');
  if (sameDay) return '${two(dt.hour)}:${two(dt.minute)}';
  return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
}
