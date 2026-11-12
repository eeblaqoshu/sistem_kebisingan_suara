/// Model Laporan Akhir Sesi 9 Bagian Wajib (koleksi reports/{sessionId})
class SessionReport {
  final String sessionId;
  final List<String> nodeIds;
  final int periodStartTs;
  final int periodEndTs;
  final int sampleCount;
  final int noGpsCount;
  final int baselineMinutes;
  final int finalMinutes;
  final double baselineLeq;
  final double finalLeq;
  final double deltaLeq;
  final double leqPeriod;
  final double lmax;
  final int? lmaxTs;
  final double lmin;
  final double l10;
  final double l50;
  final double l90;
  final double pctGreen;
  final double pctYellow;
  final double pctRed;
  final int anomalyCount;
  final Map<String, int> anomalyBreakdown; // {'point': x, 'collective': y}
  final String autoConclusion;
  final String userConclusion;
  final Map<String, dynamic> thresholdSnapshot;
  final Map<String, dynamic> calibSnapshot;
  final String? createdAt;
  final String? updatedAt;
  final String? createdBy;

  SessionReport({
    required this.sessionId,
    required this.nodeIds,
    required this.periodStartTs,
    required this.periodEndTs,
    required this.sampleCount,
    required this.noGpsCount,
    this.baselineMinutes = 5,
    this.finalMinutes = 5,
    required this.baselineLeq,
    required this.finalLeq,
    required this.deltaLeq,
    required this.leqPeriod,
    required this.lmax,
    this.lmaxTs,
    required this.lmin,
    required this.l10,
    required this.l50,
    required this.l90,
    required this.pctGreen,
    required this.pctYellow,
    required this.pctRed,
    required this.anomalyCount,
    required this.anomalyBreakdown,
    required this.autoConclusion,
    this.userConclusion = '',
    required this.thresholdSnapshot,
    required this.calibSnapshot,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  factory SessionReport.fromFirestore(Map<String, dynamic> map, String id) {
    return SessionReport(
      sessionId: id,
      nodeIds: List<String>.from(map['nodeIds'] ?? []),
      periodStartTs: (map['periodStartTs'] is num) ? (map['periodStartTs'] as num).toInt() : 0,
      periodEndTs: (map['periodEndTs'] is num) ? (map['periodEndTs'] as num).toInt() : 0,
      sampleCount: (map['sampleCount'] is num) ? (map['sampleCount'] as num).toInt() : 0,
      noGpsCount: (map['noGpsCount'] is num) ? (map['noGpsCount'] as num).toInt() : 0,
      baselineMinutes: (map['baselineMinutes'] is num) ? (map['baselineMinutes'] as num).toInt() : 5,
      finalMinutes: (map['finalMinutes'] is num) ? (map['finalMinutes'] as num).toInt() : 5,
      baselineLeq: (map['baselineLeq'] is num) ? (map['baselineLeq'] as num).toDouble() : 0.0,
      finalLeq: (map['finalLeq'] is num) ? (map['finalLeq'] as num).toDouble() : 0.0,
      deltaLeq: (map['deltaLeq'] is num) ? (map['deltaLeq'] as num).toDouble() : 0.0,
      leqPeriod: (map['leqPeriod'] is num) ? (map['leqPeriod'] as num).toDouble() : 0.0,
      lmax: (map['lmax'] is num) ? (map['lmax'] as num).toDouble() : 0.0,
      lmaxTs: (map['lmaxTs'] is num) ? (map['lmaxTs'] as num).toInt() : null,
      lmin: (map['lmin'] is num) ? (map['lmin'] as num).toDouble() : 0.0,
      l10: (map['l10'] is num) ? (map['l10'] as num).toDouble() : 0.0,
      l50: (map['l50'] is num) ? (map['l50'] as num).toDouble() : 0.0,
      l90: (map['l90'] is num) ? (map['l90'] as num).toDouble() : 0.0,
      pctGreen: (map['pctGreen'] is num) ? (map['pctGreen'] as num).toDouble() : 0.0,
      pctYellow: (map['pctYellow'] is num) ? (map['pctYellow'] as num).toDouble() : 0.0,
      pctRed: (map['pctRed'] is num) ? (map['pctRed'] as num).toDouble() : 0.0,
      anomalyCount: (map['anomalyCount'] is num) ? (map['anomalyCount'] as num).toInt() : 0,
      anomalyBreakdown: Map<String, int>.from(map['anomalyBreakdown'] ?? {}),
      autoConclusion: map['autoConclusion'] ?? '',
      userConclusion: map['userConclusion'] ?? '',
      thresholdSnapshot: Map<String, dynamic>.from(map['thresholdSnapshot'] ?? {}),
      calibSnapshot: Map<String, dynamic>.from(map['calibSnapshot'] ?? {}),
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
      createdBy: map['createdBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sessionId': sessionId,
      'nodeIds': nodeIds,
      'periodStartTs': periodStartTs,
      'periodEndTs': periodEndTs,
      'sampleCount': sampleCount,
      'noGpsCount': noGpsCount,
      'baselineMinutes': baselineMinutes,
      'finalMinutes': finalMinutes,
      'baselineLeq': baselineLeq,
      'finalLeq': finalLeq,
      'deltaLeq': deltaLeq,
      'leqPeriod': leqPeriod,
      'lmax': lmax,
      'lmaxTs': lmaxTs,
      'lmin': lmin,
      'l10': l10,
      'l50': l50,
      'l90': l90,
      'pctGreen': pctGreen,
      'pctYellow': pctYellow,
      'pctRed': pctRed,
      'anomalyCount': anomalyCount,
      'anomalyBreakdown': anomalyBreakdown,
      'autoConclusion': autoConclusion,
      'userConclusion': userConclusion,
      'thresholdSnapshot': thresholdSnapshot,
      'calibSnapshot': calibSnapshot,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
    };
  }

  SessionReport copyWith({
    String? userConclusion,
    String? updatedAt,
  }) {
    return SessionReport(
      sessionId: sessionId,
      nodeIds: nodeIds,
      periodStartTs: periodStartTs,
      periodEndTs: periodEndTs,
      sampleCount: sampleCount,
      noGpsCount: noGpsCount,
      baselineMinutes: baselineMinutes,
      finalMinutes: finalMinutes,
      baselineLeq: baselineLeq,
      finalLeq: finalLeq,
      deltaLeq: deltaLeq,
      leqPeriod: leqPeriod,
      lmax: lmax,
      lmaxTs: lmaxTs,
      lmin: lmin,
      l10: l10,
      l50: l50,
      l90: l90,
      pctGreen: pctGreen,
      pctYellow: pctYellow,
      pctRed: pctRed,
      anomalyCount: anomalyCount,
      anomalyBreakdown: anomalyBreakdown,
      autoConclusion: autoConclusion,
      userConclusion: userConclusion ?? this.userConclusion,
      thresholdSnapshot: thresholdSnapshot,
      calibSnapshot: calibSnapshot,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy,
    );
  }
}
