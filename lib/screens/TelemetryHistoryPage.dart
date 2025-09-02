import 'package:flutter/material.dart';

import '../services/FeederService.dart';

class TelemetryHistoryPage extends StatelessWidget {
  const TelemetryHistoryPage({super.key, this.deviceId});

  final String? deviceId;

  @override
  Widget build(BuildContext context) {
    final feeder = FeederService();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Telemetry History'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Food Weight'),
            Tab(text: 'Cat Detection'),
          ]),
        ),
        body: StreamBuilder<List<TelemetryEntry>>(
          stream: feeder.streamTelemetry(deviceId ?? feeder.defaultDeviceId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final items = snapshot.data ?? const <TelemetryEntry>[];
            return TabBarView(
              children: [
                // Food Weight list
                ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final e = items[i];
                    return ListTile(
                      leading: const Icon(Icons.scale),
                      title: Text(
                        e.foodWeightGrams != null
                            ? '${e.foodWeightGrams} g'
                            : '-',
                      ),
                      subtitle: Text(e.timestamp.toLocal().toString()),
                    );
                  },
                ),
                // Cat Detection list
                ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final e = items[i];
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
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

