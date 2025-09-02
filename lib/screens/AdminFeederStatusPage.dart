import 'package:flutter/material.dart';

import '../services/FeederService.dart';
import 'TelemetryHistoryPage.dart';

class AdminFeederStatusPage extends StatelessWidget {
  const AdminFeederStatusPage({super.key, this.deviceId});

  final String? deviceId;

  @override
  Widget build(BuildContext context) {
    final feeder = FeederService();
    final id = deviceId ?? feeder.defaultDeviceId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feeder Status (Admin)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Telemetry History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TelemetryHistoryPage(deviceId: id),
                ),
              );
            },
          )
        ],
      ),
      body: StreamBuilder<FeederStatus>(
        stream: feeder.streamStatus(id),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final s = snap.data;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.scale),
                    title: const Text('Food Weight'),
                    subtitle: Text(
                      s?.foodWeightGrams != null
                          ? '${s!.foodWeightGrams} g'
                          : '-',
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: Icon(
                      s?.catDetected == true
                          ? Icons.pets
                          : Icons.pets_outlined,
                      color: s?.catDetected == true ? Colors.green : null,
                    ),
                    title: const Text('Cat Detection'),
                    subtitle:
                        Text(s?.catDetected == true ? 'Detected' : 'Not detected'),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await feeder.dispense(grams: 20, byRole: 'admin');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Dispensing 20g…')),
                        );
                      }
                    },
                    icon: const Icon(Icons.restaurant),
                    label: const Text('Dispense 20g'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

