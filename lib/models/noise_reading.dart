/// Model pembacaan telemetri tingkat kebisingan dari RTDB (/latest dan /readings)
class NoiseReading {
  final String deviceId;
  final int ts; // Epoch detik
  final String timestampIso;
  final double leqDba;
  final String category; // 'green', 'yellow', 'red'
  final bool isAnomaly;
  final String anomalyType; // 'normal', 'point', 'collective'
  final bool gpsFix;
  final double latitude;
  final double longitude;

  NoiseReading({
    required this.deviceId,
    required this.ts,
    required this.timestampIso,
    required this.leqDba,
    required this.category,
    required this.isAnomaly,
    required this.anomalyType,
    required this.gpsFix,
    required this.latitude,
    required this.longitude,
  });

  factory NoiseReading.fromMap(Map<dynamic, dynamic> map, {String? deviceId}) {
    return NoiseReading(
      deviceId: deviceId ?? map['device_id']?.toString() ?? '',
      ts: (map['ts'] is num) ? (map['ts'] as num).toInt() : 0,
      timestampIso: map['timestamp']?.toString() ?? '',
      leqDba: (map['leq_dba'] is num) ? (map['leq_dba'] as num).toDouble() : 0.0,
      category: map['category']?.toString() ?? 'green',
      isAnomaly: map['is_anomaly'] == true,
      anomalyType: map['anomaly_type']?.toString() ?? 'normal',
      gpsFix: map['gps_fix'] == true,
      latitude: (map['latitude'] is num) ? (map['latitude'] as num).toDouble() : 0.0,
      longitude: (map['longitude'] is num) ? (map['longitude'] as num).toDouble() : 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ts': ts,
      'timestamp': timestampIso,
      'leq_dba': leqDba,
      'category': category,
      'is_anomaly': isAnomaly,
      'anomaly_type': anomalyType,
      'gps_fix': gpsFix,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
