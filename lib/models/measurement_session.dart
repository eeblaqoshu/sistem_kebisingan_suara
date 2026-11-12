/// Model sesi pengukuran kebisingan (koleksi sessions/{sessionId})
class MeasurementSession {
  final String id;
  final String name;
  final String purpose;
  final List<String> nodeIds;
  final List<String> locationPointIds;
  final String status; // 'active', 'ended'
  final int startTs;
  final int? endTs;
  final String notes;
  final Map<String, dynamic> calibSnapshot;
  final Map<String, dynamic> thresholdSnapshot;
  final String? createdBy;
  final String? createdAt;

  MeasurementSession({
    required this.id,
    required this.name,
    required this.purpose,
    required this.nodeIds,
    required this.locationPointIds,
    required this.status,
    required this.startTs,
    this.endTs,
    this.notes = '',
    required this.calibSnapshot,
    required this.thresholdSnapshot,
    this.createdBy,
    this.createdAt,
  });

  factory MeasurementSession.fromFirestore(Map<String, dynamic> map, String id) {
    return MeasurementSession(
      id: id,
      name: map['name'] ?? '',
      purpose: map['purpose'] ?? '',
      nodeIds: List<String>.from(map['nodeIds'] ?? []),
      locationPointIds: List<String>.from(map['locationPointIds'] ?? []),
      status: map['status'] ?? 'ended',
      startTs: (map['startTs'] is num) ? (map['startTs'] as num).toInt() : 0,
      endTs: (map['endTs'] is num) ? (map['endTs'] as num).toInt() : null,
      notes: map['notes'] ?? '',
      calibSnapshot: Map<String, dynamic>.from(map['calibSnapshot'] ?? {}),
      thresholdSnapshot: Map<String, dynamic>.from(map['thresholdSnapshot'] ?? {}),
      createdBy: map['createdBy'],
      createdAt: map['createdAt'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'purpose': purpose,
      'nodeIds': nodeIds,
      'locationPointIds': locationPointIds,
      'status': status,
      'startTs': startTs,
      'endTs': endTs,
      'notes': notes,
      'calibSnapshot': calibSnapshot,
      'thresholdSnapshot': thresholdSnapshot,
      'createdBy': createdBy,
      'createdAt': createdAt,
    };
  }

  MeasurementSession copyWith({
    String? status,
    int? endTs,
    String? notes,
  }) {
    return MeasurementSession(
      id: id,
      name: name,
      purpose: purpose,
      nodeIds: nodeIds,
      locationPointIds: locationPointIds,
      status: status ?? this.status,
      startTs: startTs,
      endTs: endTs ?? this.endTs,
      notes: notes ?? this.notes,
      calibSnapshot: calibSnapshot,
      thresholdSnapshot: thresholdSnapshot,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }
}
