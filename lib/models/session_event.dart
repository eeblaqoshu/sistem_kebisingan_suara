/// Model kronologi kejadian sesi (sub-koleksi sessions/{sessionId}/events/{eventId})
class SessionEvent {
  final String id;
  final String sessionId;
  final int ts; // Epoch detik
  final String type; // 'auto' | 'manual'
  final String kind; // 'note' | 'category_change' | 'anomaly' | 'node_offline' | 'node_online'
  final String title;
  final String notes;
  final String? deviceId;
  final Map<String, dynamic>? data;

  SessionEvent({
    required this.id,
    required this.sessionId,
    required this.ts,
    required this.type,
    required this.kind,
    required this.title,
    this.notes = '',
    this.deviceId,
    this.data,
  });

  factory SessionEvent.fromFirestore(Map<String, dynamic> map, String id, String sessionId) {
    return SessionEvent(
      id: id,
      sessionId: sessionId,
      ts: (map['ts'] is num) ? (map['ts'] as num).toInt() : 0,
      type: map['type'] ?? 'auto',
      kind: map['kind'] ?? 'note',
      title: map['title'] ?? '',
      notes: map['notes'] ?? '',
      deviceId: map['deviceId'],
      data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ts': ts,
      'type': type,
      'kind': kind,
      'title': title,
      'notes': notes,
      if (deviceId != null) 'deviceId': deviceId,
      if (data != null) 'data': data,
    };
  }
}
