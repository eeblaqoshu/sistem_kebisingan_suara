/// Model data perangkat IoT (ESP32) di Firestore (koleksi nodes/{deviceId})
class NodeDevice {
  final String deviceId;
  final String name;
  final String locationName;
  final double calibGain;
  final double calibOffset;
  final String notes;
  final String locationPointId;
  final int? lastSeenTs;
  final bool isOnline;
  final int? rssi;
  final int? uptimeSec;
  final String? createdAt;
  final String? createdBy;

  NodeDevice({
    required this.deviceId,
    required this.name,
    required this.locationName,
    this.calibGain = 1.0,
    this.calibOffset = 0.0,
    this.notes = '',
    this.locationPointId = '',
    this.lastSeenTs,
    this.isOnline = false,
    this.rssi,
    this.uptimeSec,
    this.createdAt,
    this.createdBy,
  });

  factory NodeDevice.fromFirestore(Map<String, dynamic> map, String id) {
    return NodeDevice(
      deviceId: id,
      name: map['name'] ?? 'Node $id',
      locationName: map['locationName'] ?? '',
      calibGain: (map['calibGain'] is num) ? (map['calibGain'] as num).toDouble() : 1.0,
      calibOffset: (map['calibOffset'] is num) ? (map['calibOffset'] as num).toDouble() : 0.0,
      notes: map['notes'] ?? '',
      locationPointId: map['locationPointId'] ?? '',
      lastSeenTs: (map['lastSeenTs'] is num) ? (map['lastSeenTs'] as num).toInt() : null,
      isOnline: map['isOnline'] == true,
      rssi: (map['rssi'] is num) ? (map['rssi'] as num).toInt() : null,
      uptimeSec: (map['uptimeSec'] is num) ? (map['uptimeSec'] as num).toInt() : null,
      createdAt: map['createdAt'],
      createdBy: map['createdBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'locationName': locationName,
      'calibGain': calibGain,
      'calibOffset': calibOffset,
      'notes': notes,
      'locationPointId': locationPointId,
      'lastSeenTs': lastSeenTs,
      'isOnline': isOnline,
      'rssi': rssi,
      'uptimeSec': uptimeSec,
      'createdAt': createdAt,
      'createdBy': createdBy,
    };
  }

  NodeDevice copyWith({
    String? name,
    String? locationName,
    double? calibGain,
    double? calibOffset,
    String? notes,
    String? locationPointId,
    int? lastSeenTs,
    bool? isOnline,
    int? rssi,
    int? uptimeSec,
  }) {
    return NodeDevice(
      deviceId: deviceId,
      name: name ?? this.name,
      locationName: locationName ?? this.locationName,
      calibGain: calibGain ?? this.calibGain,
      calibOffset: calibOffset ?? this.calibOffset,
      notes: notes ?? this.notes,
      locationPointId: locationPointId ?? this.locationPointId,
      lastSeenTs: lastSeenTs ?? this.lastSeenTs,
      isOnline: isOnline ?? this.isOnline,
      rssi: rssi ?? this.rssi,
      uptimeSec: uptimeSec ?? this.uptimeSec,
      createdAt: createdAt,
      createdBy: createdBy,
    );
  }
}
