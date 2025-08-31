import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:paw_ui/widgets/OptionCard.dart';

/*
Firestore structure:
devices/{deviceId}
  online: bool
  nextFeedTime: Timestamp
  commands (collection)
    autoId:
      type: "dispense" | "schedule"
      amount: number?       // for dispense
      feedAt: Timestamp?    // for schedule
      createdAt: server timestamp
*/

// ===== YOUR EXISTING VIEW (unchanged) =====
class DeviceControlView extends StatelessWidget {
  const DeviceControlView({
    super.key,
    required this.activeIndex, // 0: Schedule, 1: Release, 2: Connect
    this.scheduledDate,
    required this.loading,
    required this.error,
    required this.online,
    this.onLogout,
    this.onNetworkIconTap,
    this.onCardSelected,
    this.onSchedulePressed, // FAB "Schedule"
    this.content, // e.g., ScheduleList(...)
  });

  final int activeIndex;
  final String? scheduledDate;
  final bool loading;
  final bool error;
  final bool online;

  final VoidCallback? onLogout;
  final VoidCallback? onNetworkIconTap;
  final ValueChanged<int>? onCardSelected;
  final VoidCallback? onSchedulePressed;

  final Widget? content;

  bool get _showScheduleFab {
    if (loading || error) return false;
    if (activeIndex != 0) return false;
    final hasSchedule = (scheduledDate != null && scheduledDate!.isNotEmpty);
    return !hasSchedule;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final topBar = Padding(
      padding: const EdgeInsets.fromLTRB(0, 25.0, 0, 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onNetworkIconTap,
            child: Icon(
              Icons.network_check,
              color: online ? Colors.green : Colors.red,
              size: 20.0,
            ),
          ),
          Image.asset("assets/logo.png", height: 70),
          GestureDetector(
            onTap: onLogout,
            child: Icon(
              Icons.exit_to_app_rounded,
              color: theme.textTheme.bodyMedium?.color,
              size: 20.0,
            ),
          ),
        ],
      ),
    );

    final options = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        OptionCard(
          id: 0,
          title: "Schedule",
          title2: "Feed",
          icon: "assets/scheduler.png",
          active: activeIndex == 0,
          onClick: onCardSelected,
        ),
        OptionCard(
          id: 1,
          title: "Release",
          title2: "Food",
          icon: "assets/feeder.png",
          active: activeIndex == 1,
          onClick: onCardSelected,
        ),
        OptionCard(
          id: 2,
          title: "Connect",
          title2: "Device",
          icon: "assets/conn.png",
          active: activeIndex == 2,
          onClick: onCardSelected,
        ),
      ],
    );

    final Widget bodyContent = error
        ? const SizedBox.shrink()
        : (content ?? const SizedBox.shrink());

    final fab = _showScheduleFab
        ? FloatingActionButton.extended(
            onPressed: onSchedulePressed,
            label: const Text(
              'Schedule',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            icon: const Icon(Icons.timer),
            tooltip: 'Schedule Feed',
            elevation: 2,
            backgroundColor: const Color(0xFF0e2a47),
            foregroundColor: theme.primaryColor,
          )
        : const SizedBox.shrink();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            topBar,
            options,
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: bodyContent,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: fab,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ===== ADD THIS WRAPPER SO YOU CAN PUSH const DeviceControl() =====
class DeviceControl extends StatefulWidget {
  const DeviceControl({super.key});

  @override
  State<DeviceControl> createState() => _DeviceControlState();
}

class _DeviceControlState extends State<DeviceControl> {
  final DocumentReference<Map<String, dynamic>> _deviceRef =
      FirebaseFirestore.instance.collection('devices').doc('demo-device');
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _statusSub;
  int _activeIndex = 0;           // 0: Schedule, 1: Release, 2: Connect
  final bool _loading = false;
  final bool _error = false;
  bool _online = false;
  String? _scheduledDate;         // show as a hint on Schedule tab

  @override
  void initState() {
    super.initState();
    _statusSub = _deviceRef.snapshots().listen((snapshot) {
      final data = snapshot.data();
      setState(() {
        _online = data?['online'] == true;
        final ts = data?['nextFeedTime'] as Timestamp?;
        _scheduledDate = ts?.toDate().toString();
      });
    });
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    super.dispose();
  }

  void _onSelectTab(int i) {
    setState(() => _activeIndex = i);
  }

  Future<void> _onSchedule() async {
    final when = DateTime.now().add(const Duration(hours: 1));
    await _deviceRef.update({'nextFeedTime': Timestamp.fromDate(when)});
    await _deviceRef.collection('commands').add({
      'type': 'schedule',
      'feedAt': Timestamp.fromDate(when),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  void _onLogout() {
    // If you use FirebaseAuth: await FirebaseAuth.instance.signOut();
    Navigator.of(context).maybePop();
  }

  void _onNetworkTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checking network...')),
    );
  }

  Future<void> _dispenseNow() async {
    await _deviceRef.collection('commands').add({
      'type': 'dispense',
      'amount': 20,
      'createdAt': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dispensing 20g…')),
    );
  }

  void _connectDevice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Connecting to device…')),
    );
  }

  Widget _buildContent() {
    if (_loading || _error) return const SizedBox.shrink();

    switch (_activeIndex) {
      case 0:
        // Schedule tab
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_scheduledDate == null
                  ? 'No schedule yet.'
                  : 'Next schedule: $_scheduledDate'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _onSchedule,
                child: const Text('Create Schedule'),
              ),
            ],
          ),
        );

      case 1:
        // Release Food tab
        return Center(
          child: ElevatedButton(
            onPressed: _dispenseNow,
            child: const Text('Dispense 20g now'),
          ),
        );

      case 2:
        // Connect Device tab
        return Center(
          child: ElevatedButton(
            onPressed: _connectDevice,
            child: const Text('Connect Device'),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DeviceControlView(
      activeIndex: _activeIndex,
      scheduledDate: _scheduledDate,
      loading: _loading,
      error: _error,
      online: _online,
      onLogout: _onLogout,
      onNetworkIconTap: _onNetworkTap,
      onCardSelected: _onSelectTab,
      onSchedulePressed: _onSchedule, // controls FAB on Schedule tab
      content: _buildContent(),
    );
  }
}
