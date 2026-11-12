import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/noise_reading.dart';
import '../services/dummy_telemetry_service.dart';

/// Repository telemetri RTDB dengan fallback transparan ke simulator dummy
class TelemetryRepository {
  final FirebaseDatabase? rtdb;
  final DummyTelemetryService _dummyService = DummyTelemetryService();

  TelemetryRepository({this.rtdb});

  /// Stream pembacaan terkini dari RTDB (/latest/{deviceId})
  Stream<NoiseReading> streamLatestReading(String deviceId) {
    if (Firebase.apps.isNotEmpty && rtdb != null) {
      try {
        final ref = rtdb!.ref('latest/$deviceId');
        return ref.onValue.map((event) {
          final val = event.snapshot.value;
          if (val is Map) {
            return NoiseReading.fromMap(val, deviceId: deviceId);
          }
          throw Exception('Data format invalid');
        });
      } catch (_) {
        // Fallback jika terjadi kegagalan koneksi
      }
    }

    // Jika belum ada koneksi Firebase, gunakan DummyTelemetryService
    _dummyService.start(deviceId: deviceId);
    return _dummyService.stream;
  }

  /// Mengambil data historis readings dalam rentang epoch startTs..endTs
  Future<List<NoiseReading>> fetchReadingsInRange({
    required String deviceId,
    required int startTs,
    required int endTs,
  }) async {
    if (Firebase.apps.isNotEmpty && rtdb != null) {
      try {
        final ref = rtdb!.ref('readings/$deviceId');
        final query = ref.orderByKey().startAt('$startTs').endAt('$endTs');
        final snapshot = await query.get();

        if (snapshot.exists && snapshot.value is Map) {
          final map = snapshot.value as Map;
          final List<NoiseReading> list = [];
          map.forEach((k, v) {
            if (v is Map) {
              list.add(NoiseReading.fromMap(v, deviceId: deviceId));
            }
          });
          list.sort((a, b) => a.ts.compareTo(b.ts));
          return list;
        }
      } catch (_) {}
    }

    // Fallback: generate data realistis pada rentang waktu tersebut untuk preview
    final List<NoiseReading> mockList = [];
    final int duration = endTs - startTs;
    final int step = (duration / 60).clamp(2, 10).toInt();

    for (int t = startTs; t <= endTs; t += step) {
      mockList.add(
        NoiseReading(
          deviceId: deviceId,
          ts: t,
          timestampIso: DateTime.fromMillisecondsSinceEpoch(t * 1000).toIso8601String(),
          leqDba: 58.0 + ((t % 17) * 0.9),
          category: (58.0 + ((t % 17) * 0.9)) > 70 ? 'red' : 'yellow',
          isAnomaly: (t % 120 == 0),
          anomalyType: (t % 120 == 0) ? 'point' : 'normal',
          gpsFix: true,
          latitude: -7.052012,
          longitude: 110.435412,
        ),
      );
    }
    return mockList;
  }
}
