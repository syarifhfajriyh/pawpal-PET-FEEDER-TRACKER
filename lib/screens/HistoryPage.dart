import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

enum HistoryType { dispense, schedule, error }
enum HistoryFilter { all, dispense, schedule, error }
enum HistoryRange { last7, last30, all }

class HistoryEntry {
  final String id;
  final HistoryType type;
  final DateTime time;
  final String title;      // e.g., "Dispensed 200g"
  final String device;     // e.g., "Kitchen PawFeeder"
  final int? grams;        // nullable for schedule/error
  final String? note;      // optional message

  const HistoryEntry({
    required this.id,
    required this.type,
    required this.time,
    required this.title,
    required this.device,
    this.grams,
    this.note,
  });
}

class _HistoryPageState extends State<HistoryPage> {
  final _fmtDate = DateFormat('EEE, MMM d');
  final _fmtTime = DateFormat('h:mm a');

  // --- UI state ---
  HistoryFilter _filter = HistoryFilter.all;
  HistoryRange _range = HistoryRange.last7;
  String _query = '';

  // --- Mock data (UI-only) ---
  final List<HistoryEntry> _all = [
    HistoryEntry(
      id: '1',
      type: HistoryType.dispense,
      time: DateTime.now().subtract(const Duration(hours: 2)),
      title: 'Dispensed 200g',
      device: 'Kitchen PawFeeder',
      grams: 200,
      note: 'Manual dispense from app',
    ),
    HistoryEntry(
      id: '2',
      type: HistoryType.schedule,
      time: DateTime.now().subtract(const Duration(hours: 6)),
      title: 'Scheduled feed',
      device: 'Kitchen PawFeeder',
      grams: 300,
      note: 'Daily breakfast',
    ),
    HistoryEntry(
      id: '3',
      type: HistoryType.error,
      time: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      title: 'Dispense failed',
      device: 'Garage PawFeeder',
      grams: 200,
      note: 'Hopper jam detected',
    ),
    HistoryEntry(
      id: '4',
      type: HistoryType.dispense,
      time: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
      title: 'Dispensed 100g',
      device: 'Garage PawFeeder',
      grams: 100,
    ),
    HistoryEntry(
      id: '5',
      type: HistoryType.schedule,
      time: DateTime.now().subtract(const Duration(days: 3)),
      title: 'Scheduled feed',
      device: 'Kitchen PawFeeder',
      grams: 250,
    ),
    HistoryEntry(
      id: '6',
      type: HistoryType.dispense,
      time: DateTime.now().subtract(const Duration(days: 6)),
      title: 'Dispensed 400g',
      device: 'Kitchen PawFeeder',
      grams: 400,
    ),
    HistoryEntry(
      id: '7',
      type: HistoryType.dispense,
      time: DateTime.now().subtract(const Duration(days: 12)),
      title: 'Dispensed 300g',
      device: 'Garage PawFeeder',
      grams: 300,
    ),
    HistoryEntry(
      id: '8',
      type: HistoryType.error,
      time: DateTime.now().subtract(const Duration(days: 20)),
      title: 'Schedule skipped',
      device: 'Kitchen PawFeeder',
      note: 'Low battery',
    ),
  ];

  // --- Filtering/searching ---
  List<HistoryEntry> get _filtered {
    final now = DateTime.now();
    DateTime minDate;
    switch (_range) {
      case HistoryRange.last7:
        minDate = now.subtract(const Duration(days: 7));
        break;
      case HistoryRange.last30:
        minDate = now.subtract(const Duration(days: 30));
        break;
      case HistoryRange.all:
        minDate = DateTime(2000);
        break;
    }

    return _all.where((e) {
      if (e.time.isBefore(minDate)) return false;

      if (_filter != HistoryFilter.all) {
        if (_filter == HistoryFilter.dispense && e.type != HistoryType.dispense) return false;
        if (_filter == HistoryFilter.schedule && e.type != HistoryType.schedule) return false;
        if (_filter == HistoryFilter.error && e.type != HistoryType.error) return false;
      }

      if (_query.trim().isNotEmpty) {
        final q = _query.toLowerCase();
        final hay = '${e.title} ${e.device} ${e.note ?? ''}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }

      return true;
    }).toList()
      ..sort((a, b) => b.time.compareTo(a.time));
  }

  Future<void> _refresh() async {
    // UI-only: pretend to refresh
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Refreshed')),
    );
  }

  void _showDetails(HistoryEntry e) {
    final t = Theme.of(context).textTheme;
    final label = _labelForType(e.type);
    final icon = _iconForType(e.type);
    final color = _colorForType(context, e.type);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0x00000000),
      builder: (ctx) => Container(
        height: 360,
        color: const Color(0xFF737373),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // message bar (empty, for your sheet look)
                  Container(
                    height: 30,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: (t.bodyMedium?.color ?? Colors.black54).withOpacity(0.1),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: color.withOpacity(0.15),
                        child: Icon(icon, color: color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(e.title, style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w800, fontSize: 16)),
                      ),
                      Text(_fmtTime.format(e.time), style: t.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _kv('Type', label, t),
                  _kv('Device', e.device, t),
                  _kv('Date', _fmtDate.format(e.time), t),
                  if (e.grams != null) _kv('Portion', '${e.grams}g', t),
                  if (e.note != null && e.note!.isNotEmpty) _kv('Note', e.note!, t),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: const Color(0xFF0E2A47),
                            elevation: 0.5,
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Reschedule (UI-only)')),
                            );
                          },
                          child: const Text('Reschedule', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final items = _filtered;
    final grouped = _groupByDate(items);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: const Text('History'),
      ),
      body: Column(
        children: [
          // --- Search ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search history',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),

          // --- Filters ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: SegmentedButton<HistoryFilter>(
              segments: const [
                ButtonSegment(value: HistoryFilter.all, label: Text('All'), icon: Icon(Icons.list)),
                ButtonSegment(value: HistoryFilter.dispense, label: Text('Dispenses'), icon: Icon(Icons.restaurant)),
                ButtonSegment(value: HistoryFilter.schedule, label: Text('Schedules'), icon: Icon(Icons.timer)),
                ButtonSegment(value: HistoryFilter.error, label: Text('Errors'), icon: Icon(Icons.error_outline)),
              ],
              selected: <HistoryFilter>{_filter},
              onSelectionChanged: (s) => setState(() => _filter = s.first),
              showSelectedIcon: false,
            ),
          ),

          // --- Range chips ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Last 7 days'),
                  selected: _range == HistoryRange.last7,
                  onSelected: (_) => setState(() => _range = HistoryRange.last7),
                ),
                ChoiceChip(
                  label: const Text('Last 30 days'),
                  selected: _range == HistoryRange.last30,
                  onSelected: (_) => setState(() => _range = HistoryRange.last30),
                ),
                ChoiceChip(
                  label: const Text('All'),
                  selected: _range == HistoryRange.all,
                  onSelected: (_) => setState(() => _range = HistoryRange.all),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: items.isEmpty ? null : () => setState(() => _query = ''),
                  child: const Text('Clear search'),
                ),
              ],
            ),
          ),

          // --- List / Empty ---
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: items.isEmpty
                  ? _emptyState(t)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: grouped.length,
                      itemBuilder: (_, i) {
                        final g = grouped[i];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                              child: Text(g.$1, style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w800)),
                            ),
                            ...g.$2.map(_buildCard),
                          ],
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // tuple<dateLabel, items>
  List<(String, List<HistoryEntry>)> _groupByDate(List<HistoryEntry> entries) {
    final map = <String, List<HistoryEntry>>{};
    for (final e in entries) {
      final k = _fmtDate.format(e.time);
      map.putIfAbsent(k, () => []).add(e);
    }
    final out = map.entries.toList()
      ..sort((a, b) => _parseDate(b.key).compareTo(_parseDate(a.key)));
    return out.map((e) => (e.key, e.value)).toList();
  }

  DateTime _parseDate(String label) {
    // since label uses _fmtDate, reformat via parsing today’s year logic if needed
    // safer: find a representative time from items when grouping (already done),
    // but for stability, we’ll best-effort parse month/day by splitting:
    try {
      final parts = label.replaceAll(',', '').split(' ');
      // e.g., "Mon, Aug 11" -> ["Mon", "Aug", "11"]
      final month = DateFormat('MMM').parse(parts[1]).month;
      final day = int.parse(parts[2]);
      final now = DateTime.now();
      return DateTime(now.year, month, day);
    } catch (_) {
      return DateTime.now();
    }
  }

  Widget _buildCard(HistoryEntry e) {
    final icon = _iconForType(e.type);
    final color = _colorForType(context, e.type);
    final t = Theme.of(context).textTheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${_fmtTime.format(e.time)} • ${e.device}', style: t.bodyMedium),
        trailing: e.grams != null
            ? Text('${e.grams}g', style: const TextStyle(fontWeight: FontWeight.w800))
            : const Icon(Icons.chevron_right),
        onTap: () => _showDetails(e),
      ),
    );
  }

  Widget _emptyState(TextTheme t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/petfeed.jpg', height: 160),
            const SizedBox(height: 20),
            Text(
              'No history yet.',
              style: t.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _labelForType(HistoryType type) {
    switch (type) {
      case HistoryType.dispense:
        return 'Dispense';
      case HistoryType.schedule:
        return 'Schedule';
      case HistoryType.error:
        return 'Error';
    }
  }

  IconData _iconForType(HistoryType type) {
    switch (type) {
      case HistoryType.dispense:
        return Icons.restaurant;
      case HistoryType.schedule:
        return Icons.timer;
      case HistoryType.error:
        return Icons.error_outline;
    }
  }

  Color _colorForType(BuildContext context, HistoryType type) {
    switch (type) {
      case HistoryType.dispense:
        return const Color(0xFF0E2A47); // navy
      case HistoryType.schedule:
        return Colors.blueGrey.shade700;
      case HistoryType.error:
        return Colors.red.shade600;
    }
  }

  Widget _kv(String k, String v, TextTheme t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(k, style: t.bodyMedium)),
          Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}
