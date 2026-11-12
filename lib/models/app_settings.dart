/// Model pengaturan pengguna/peneliti di Firestore (koleksi settings/{uid})
class AppSettings {
  final double thresholdYellow;
  final double thresholdRed;
  final int offlineIntervalSec;
  final int baselineMinutes;
  final int finalMinutes;
  final String theme; // 'system', 'light', 'dark'
  final bool notifyAnomaly;
  final bool notifyThreshold;
  final bool notifyOffline;

  AppSettings({
    this.thresholdYellow = 55.0,
    this.thresholdRed = 70.0,
    this.offlineIntervalSec = 30,
    this.baselineMinutes = 5,
    this.finalMinutes = 5,
    this.theme = 'system',
    this.notifyAnomaly = true,
    this.notifyThreshold = true,
    this.notifyOffline = true,
  });

  factory AppSettings.fromFirestore(Map<String, dynamic>? map) {
    if (map == null) return AppSettings();
    return AppSettings(
      thresholdYellow: (map['thresholdYellow'] is num) ? (map['thresholdYellow'] as num).toDouble() : 55.0,
      thresholdRed: (map['thresholdRed'] is num) ? (map['thresholdRed'] as num).toDouble() : 70.0,
      offlineIntervalSec: (map['offlineIntervalSec'] is num) ? (map['offlineIntervalSec'] as num).toInt() : 30,
      baselineMinutes: (map['baselineMinutes'] is num) ? (map['baselineMinutes'] as num).toInt() : 5,
      finalMinutes: (map['finalMinutes'] is num) ? (map['finalMinutes'] as num).toInt() : 5,
      theme: map['theme'] ?? 'system',
      notifyAnomaly: map['notifyAnomaly'] ?? true,
      notifyThreshold: map['notifyThreshold'] ?? true,
      notifyOffline: map['notifyOffline'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'thresholdYellow': thresholdYellow,
      'thresholdRed': thresholdRed,
      'offlineIntervalSec': offlineIntervalSec,
      'baselineMinutes': baselineMinutes,
      'finalMinutes': finalMinutes,
      'theme': theme,
      'notifyAnomaly': notifyAnomaly,
      'notifyThreshold': notifyThreshold,
      'notifyOffline': notifyOffline,
    };
  }

  AppSettings copyWith({
    double? thresholdYellow,
    double? thresholdRed,
    int? offlineIntervalSec,
    int? baselineMinutes,
    int? finalMinutes,
    String? theme,
    bool? notifyAnomaly,
    bool? notifyThreshold,
    bool? notifyOffline,
  }) {
    return AppSettings(
      thresholdYellow: thresholdYellow ?? this.thresholdYellow,
      thresholdRed: thresholdRed ?? this.thresholdRed,
      offlineIntervalSec: offlineIntervalSec ?? this.offlineIntervalSec,
      baselineMinutes: baselineMinutes ?? this.baselineMinutes,
      finalMinutes: finalMinutes ?? this.finalMinutes,
      theme: theme ?? this.theme,
      notifyAnomaly: notifyAnomaly ?? this.notifyAnomaly,
      notifyThreshold: notifyThreshold ?? this.notifyThreshold,
      notifyOffline: notifyOffline ?? this.notifyOffline,
    );
  }
}
