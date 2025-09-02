import 'package:flutter/material.dart';

import '../services/FeederService.dart';
import '../services/AuthService.dart';
import '../services/databaseUser.dart';

class UserWeightHistoryPage extends StatelessWidget {
  const UserWeightHistoryPage({super.key, this.deviceId});

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
      appBar: AppBar(title: const Text('Food Weight History')),
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
              .where((e) => e.foodWeightGrams != null)
              .toList();
          final usingSample = items.isEmpty;
          if (usingSample) {
            final now = DateTime.now();
            items = [
              TelemetryEntry(foodWeightGrams: 480, timestamp: now.subtract(const Duration(hours: 1))),
              TelemetryEntry(foodWeightGrams: 470, timestamp: now.subtract(const Duration(hours: 3))),
              TelemetryEntry(foodWeightGrams: 455, timestamp: now.subtract(const Duration(hours: 6))),
              TelemetryEntry(foodWeightGrams: 440, timestamp: now.subtract(const Duration(hours: 9))),
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
              return ListTile(
                leading: const Icon(Icons.scale),
                title: Text('${e.foodWeightGrams} g'),
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
