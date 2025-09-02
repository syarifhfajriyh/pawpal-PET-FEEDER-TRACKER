import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for interacting with a PawFeeder device in Firestore.
///
/// Firestore layout (proposed):
/// devices/{deviceId}
///   online: bool
///   name: string
///   current: {
///     foodWeightGrams: number
///     catDetected: bool
///     updatedAt: Timestamp
///   }
///   nextFeedTime: Timestamp?
///   feeds (collection)
///     autoId: { grams, byUid, byRole, timestamp, scheduledAt? }
///   commands (collection)
///     autoId: { type: 'dispense'|'schedule', amount?, feedAt?, createdAt }
///   telemetry (collection)
///     autoId: { foodWeightGrams?, catDetected?, timestamp }
class FeederService {
  FeederService({this.defaultDeviceId = 'demo-device'});

  final String defaultDeviceId;
  final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> deviceRef([String? deviceId]) =>
      _db.collection('devices').doc(deviceId ?? defaultDeviceId);

  CollectionReference<Map<String, dynamic>> _feeds(String deviceId) =>
      deviceRef(deviceId).collection('feeds');

  CollectionReference<Map<String, dynamic>> _commands(String deviceId) =>
      deviceRef(deviceId).collection('commands');

  CollectionReference<Map<String, dynamic>> _telemetry(String deviceId) =>
      deviceRef(deviceId).collection('telemetry');

  /// Stream latest status from device doc's `current` field.
  Stream<FeederStatus> streamStatus([String? deviceId]) {
    return deviceRef(deviceId)
        .snapshots()
        .map((snap) => FeederStatus.fromDeviceDoc(snap.data()));
  }

  /// Stream recent telemetry entries (descending by time).
  Stream<List<TelemetryEntry>> streamTelemetry(
    String deviceId, {
    int limit = 50,
  }) {
    return _telemetry(deviceId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((q) => q.docs.map((d) => TelemetryEntry.fromMap(d.data())).toList());
  }

  /// Stream recent feed (dispense/schedule) events (descending by time).
  Stream<List<FeedEvent>> streamFeeds(String deviceId, {int limit = 50}) {
    return _feeds(deviceId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((q) => q.docs.map((d) => FeedEvent.fromMap(d.data())).toList());
  }

  /// Dispense immediately. Also logs into `feeds` history.
  Future<void> dispense({
    String? deviceId,
    required int grams,
    String? byUid,
    String byRole = 'user', // or 'admin'
  }) async {
    final id = deviceId ?? defaultDeviceId;
    await _commands(id).add({
      'type': 'dispense',
      'amount': grams,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _feeds(id).add({
      'grams': grams,
      'byUid': byUid,
      'byRole': byRole,
      'timestamp': FieldValue.serverTimestamp(),
      'note': 'dispense',
    });
  }

  /// Schedule a feed at [when]. Also logs into `feeds`.
  Future<void> schedule({
    String? deviceId,
    required DateTime when,
    int? grams,
    String? byUid,
    String byRole = 'user',
  }) async {
    final id = deviceId ?? defaultDeviceId;
    await deviceRef(id).set({
      'nextFeedTime': Timestamp.fromDate(when),
    }, SetOptions(merge: true));
    await _commands(id).add({
      'type': 'schedule',
      'feedAt': Timestamp.fromDate(when),
      if (grams != null) 'amount': grams,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _feeds(id).add({
      if (grams != null) 'grams': grams,
      'scheduledAt': Timestamp.fromDate(when),
      'byUid': byUid,
      'byRole': byRole,
      'timestamp': FieldValue.serverTimestamp(),
      'note': 'schedule',
    });
  }

  /// Helper to write telemetry entries (e.g., from device emulator).
  Future<void> addTelemetry({
    String? deviceId,
    int? foodWeightGrams,
    bool? catDetected,
    DateTime? at,
  }) async {
    final id = deviceId ?? defaultDeviceId;
    final now = at ?? DateTime.now();
    await _telemetry(id).add({
      if (foodWeightGrams != null) 'foodWeightGrams': foodWeightGrams,
      if (catDetected != null) 'catDetected': catDetected,
      'timestamp': Timestamp.fromDate(now),
    });
    // update device.current snapshot
    await deviceRef(id).set({
      'current': {
        if (foodWeightGrams != null) 'foodWeightGrams': foodWeightGrams,
        if (catDetected != null) 'catDetected': catDetected,
        'updatedAt': FieldValue.serverTimestamp(),
      }
    }, SetOptions(merge: true));
  }
}

class FeederStatus {
  final int? foodWeightGrams;
  final bool catDetected;
  final DateTime? updatedAt;

  FeederStatus({this.foodWeightGrams, this.catDetected = false, this.updatedAt});

  factory FeederStatus.fromDeviceDoc(Map<String, dynamic>? data) {
    final c = (data?['current'] as Map<String, dynamic>?) ?? const {};
    final ts = c['updatedAt'] as Timestamp?;
    return FeederStatus(
      foodWeightGrams: (c['foodWeightGrams'] as num?)?.toInt(),
      catDetected: c['catDetected'] == true,
      updatedAt: ts?.toDate(),
    );
  }
}

class TelemetryEntry {
  final int? foodWeightGrams;
  final bool? catDetected;
  final DateTime timestamp;

  TelemetryEntry({this.foodWeightGrams, this.catDetected, required this.timestamp});

  factory TelemetryEntry.fromMap(Map<String, dynamic> m) {
    final ts = (m['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    return TelemetryEntry(
      foodWeightGrams: (m['foodWeightGrams'] as num?)?.toInt(),
      catDetected: m['catDetected'] is bool ? m['catDetected'] as bool : null,
      timestamp: ts,
    );
  }
}

class FeedEvent {
  final int? grams;
  final String? byUid;
  final String? byRole;
  final String? note;
  final DateTime? scheduledAt;
  final DateTime timestamp;

  FeedEvent({
    this.grams,
    this.byUid,
    this.byRole,
    this.note,
    this.scheduledAt,
    required this.timestamp,
  });

  factory FeedEvent.fromMap(Map<String, dynamic> m) {
    return FeedEvent(
      grams: (m['grams'] as num?)?.toInt(),
      byUid: m['byUid'] as String?,
      byRole: m['byRole'] as String?,
      note: m['note'] as String?,
      scheduledAt: (m['scheduledAt'] as Timestamp?)?.toDate(),
      timestamp: (m['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

