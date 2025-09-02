import 'package:flutter/material.dart';

import '../services/FeederService.dart';
import '../services/AuthService.dart';
import '../services/databaseUser.dart';

class UserCatHistoryPage extends StatelessWidget {
  const UserCatHistoryPage({super.key, this.deviceId});

  final String? deviceId;

  @override
  Widget build(BuildContext context) {
    final feeder = FeederService();
    final id = deviceId ?? feeder.defaultDeviceId;

    Future<String> resolveDeviceId() async {
      if (deviceId != null) return deviceId!;
      final uid = AuthService().currentUser?.uid;
      if (uid == null) return id; // fallback
      try {
        final snap = await DatabaseUser().getUser(uid);
        final m = snap.data() as Map<String, dynamic>?;
        return (m?['deviceId'] as String?) ?? id;
      } catch (_) {
        return id;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Cat Detection History')),
      body: FutureBuilder<String>(
        future: resolveDeviceId(),
        builder: (context, idSnap) {
          if (idSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final devId = idSnap.data ?? id;
          return StreamBuilder<List<TelemetryEntry>>(
            stream: feeder.streamTelemetry(devId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
          var items = (snapshot.data ?? const <TelemetryEntry>[]) 
              .where((e) => e.catDetected != null)
              .toList();
          final usingSample = items.isEmpty;
          if (usingSample) {
            final now = DateTime.now();
            items = [
              TelemetryEntry(catDetected: true, timestamp: now.subtract(const Duration(minutes: 20))),
              TelemetryEntry(catDetected: false, timestamp: now.subtract(const Duration(hours: 1, minutes: 5))),
              TelemetryEntry(catDetected: true, timestamp: now.subtract(const Duration(hours: 2, minutes: 40))),
              TelemetryEntry(catDetected: false, timestamp: now.subtract(const Duration(hours: 4))),
            ];
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            itemCount: items.length + (usingSample ? 1 : 0),
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              if (usingSample && i == 0) {
                return const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Showing sample data'),
                  subtitle: Text('Connect a device to see live history.'),
                );
              }
              final e = items[usingSample ? i - 1 : i];
              final status = e.catDetected == true ? 'Detected' : 'Not detected';
              return ListTile(
                leading: Icon(
                  e.catDetected == true ? Icons.pets : Icons.pets_outlined,
                  color: e.catDetected == true ? Colors.green : null,
                ),
                title: Text(status),
                subtitle: Text(e.timestamp.toLocal().toString()),
              );
            },
          );
            },
          );
        },
      ),
    );
  }
}
