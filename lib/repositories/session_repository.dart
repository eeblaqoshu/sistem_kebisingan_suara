import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/measurement_session.dart';
import '../models/session_event.dart';
import '../models/session_report.dart';
import '../models/noise_reading.dart';
import '../utils/acoustic_math.dart';
import '../utils/auto_conclusion.dart';

/// Repository manajemen sesi pengukuran, event timeline, dan kalkulasi laporan 9 bagian
class SessionRepository {
  final FirebaseFirestore? firestore;

  MeasurementSession? _activeSession;
  final List<SessionEvent> _activeEvents = [];
  final List<MeasurementSession> _sessionHistory = [];
  final Map<String, SessionReport> _reportsMap = {};

  // Debounce state untuk auto category change
  String? _lastCategory;
  int _lastCategoryChangeTs = 0;
  double _lastRecordedLeq = 0.0;

  SessionRepository({this.firestore});

  MeasurementSession? get activeSession => _activeSession;
  List<SessionEvent> get activeEvents => List.unmodifiable(_activeEvents);

  /// Memulai sesi baru (Dibatasi maksimal 1 sesi aktif per node)
  Future<MeasurementSession> startSession({
    required String name,
    required String purpose,
    required List<String> nodeIds,
    required List<String> locationPointIds,
    required Map<String, dynamic> calibSnapshot,
    required Map<String, dynamic> thresholdSnapshot,
    String? createdBy,
  }) async {
    if (_activeSession != null && _activeSession!.status == 'active') {
      throw Exception('Masih terdapat sesi aktif yang belum diakhiri.');
    }

    final sessionId = 'sess_${DateTime.now().millisecondsSinceEpoch}';
    final nowTs = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final session = MeasurementSession(
      id: sessionId,
      name: name,
      purpose: purpose,
      nodeIds: nodeIds,
      locationPointIds: locationPointIds,
      status: 'active',
      startTs: nowTs,
      calibSnapshot: calibSnapshot,
      thresholdSnapshot: thresholdSnapshot,
      createdBy: createdBy ?? 'researcher',
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );

    _activeSession = session;
    _activeEvents.clear();
    _lastCategory = null;
    _lastCategoryChangeTs = 0;
    _lastRecordedLeq = 0.0;

    // Catat event awal sesi
    final startEvent = SessionEvent(
      id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: sessionId,
      ts: nowTs,
      type: 'auto',
      kind: 'note',
      title: 'Sesi Pengukuran Dimulai',
      notes: 'Tujuan: $purpose',
    );
    _activeEvents.add(startEvent);

    if (Firebase.apps.isNotEmpty && firestore != null) {
      try {
        await firestore!.collection('sessions').doc(sessionId).set(session.toFirestore());
        await firestore!.collection('sessions').doc(sessionId).collection('events').doc(startEvent.id).set(startEvent.toFirestore());
      } catch (_) {}
    }

    return session;
  }

  /// Menambahkan catatan kejadian manual dari peneliti
  Future<void> addManualEvent({
    required String title,
    String notes = '',
    String? deviceId,
  }) async {
    if (_activeSession == null) return;

    final nowTs = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final event = SessionEvent(
      id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: _activeSession!.id,
      ts: nowTs,
      type: 'manual',
      kind: 'note',
      title: title,
      notes: notes,
      deviceId: deviceId,
    );

    _activeEvents.add(event);

    if (Firebase.apps.isNotEmpty && firestore != null) {
      try {
        await firestore!
            .collection('sessions')
            .doc(_activeSession!.id)
            .collection('events')
            .doc(event.id)
            .set(event.toFirestore());
      } catch (_) {}
    }
  }

  /// Memproses pembacaan telemetri untuk auto-event (dengan debouncing dan histeresis 1.5 dBA)
  void processTelemetryForAutoEvents(NoiseReading reading) {
    if (_activeSession == null || _activeSession!.status != 'active') return;
    if (!_activeSession!.nodeIds.contains(reading.deviceId)) return;

    final nowTs = reading.ts;

    // 1. Cek Anomali TinyML
    if (reading.isAnomaly) {
      final anomalyEvent = SessionEvent(
        id: 'evt_anom_${nowTs}_${reading.deviceId}',
        sessionId: _activeSession!.id,
        ts: nowTs,
        type: 'auto',
        kind: 'anomaly',
        title: 'Anomali ${reading.anomalyType.toUpperCase()} Terdeteksi (${reading.leqDba} dBA)',
        notes: 'Terdeteksi oleh model edge LSTM Autoencoder',
        deviceId: reading.deviceId,
        data: {
          'leq': reading.leqDba,
          'anomaly_type': reading.anomalyType,
          'category': reading.category,
        },
      );
      _activeEvents.add(anomalyEvent);
      return;
    }

    // 2. Cek Kategori Change dengan Histeresis 1.5 dBA & Debounce 10 detik
    if (_lastCategory == null) {
      _lastCategory = reading.category;
      _lastCategoryChangeTs = nowTs;
      _lastRecordedLeq = reading.leqDba;
    } else if (_lastCategory != reading.category) {
      final double deltaFromLast = (reading.leqDba - _lastRecordedLeq).abs();
      final int timeDiff = nowTs - _lastCategoryChangeTs;

      if (deltaFromLast >= 1.5 && timeDiff >= 10) {
        final catEvent = SessionEvent(
          id: 'evt_cat_${nowTs}_${reading.deviceId}',
          sessionId: _activeSession!.id,
          ts: nowTs,
          type: 'auto',
          kind: 'category_change',
          title: 'Kategori Berubah ke ${reading.category.toUpperCase()} (${reading.leqDba} dBA)',
          notes: 'Perubahan tingkat kebisingan lingkungan melampaui ambang batas',
          deviceId: reading.deviceId,
          data: {'category': reading.category, 'leq': reading.leqDba},
        );
        _activeEvents.add(catEvent);
        _lastCategory = reading.category;
        _lastCategoryChangeTs = nowTs;
        _lastRecordedLeq = reading.leqDba;
      }
    }
  }

  /// Mengakhiri sesi pengukuran & menghitung otomatis seluruh 9 bagian laporan logaritmik
  Future<SessionReport> endSession({
    required List<NoiseReading> sessionReadings,
    String userConclusion = '',
    String locationName = 'Area Pengukuran',
  }) async {
    if (_activeSession == null) {
      throw Exception('Tidak ada sesi yang sedang aktif.');
    }

    final endTs = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final currentSession = _activeSession!.copyWith(status: 'ended', endTs: endTs);

    // Filter bacaan yang sesuai rentang sesi
    final readings = sessionReadings.where((r) => r.ts >= currentSession.startTs && r.ts <= endTs).toList();

    final int sampleCount = readings.length;
    final int noGpsCount = readings.where((r) => !r.gpsFix).length;

    final List<double> allDbValues = readings.map((r) => r.leqDba).toList();

    // 1. Hitung Leq Periode Secara Logaritmik (ISO 1996)
    final double leqPeriod = AcousticMath.computeLeq(allDbValues);

    // 2. Hitung Lmax, Lmin, dan Lmax Timestamp
    final double lmax = AcousticMath.computeLmax(allDbValues);
    final double lmin = AcousticMath.computeLmin(allDbValues);
    int? lmaxTs;
    if (readings.isNotEmpty) {
      final maxReading = readings.reduce((curr, next) => curr.leqDba > next.leqDba ? curr : next);
      lmaxTs = maxReading.ts;
    }

    // 3. Hitung Persentil Akustik (L10, L50, L90)
    final percentiles = AcousticMath.computePercentiles(allDbValues);
    final double l10 = percentiles['l10'] ?? 0.0;
    final double l50 = percentiles['l50'] ?? 0.0;
    final double l90 = percentiles['l90'] ?? 0.0;

    // 4. Hitung Distribusi Kategori
    final categories = AcousticMath.computeCategoryPercentages(allDbValues);
    final double pctGreen = categories['green'] ?? 0.0;
    final double pctYellow = categories['yellow'] ?? 0.0;
    final double pctRed = categories['red'] ?? 0.0;

    // 5. Hitung Baseline (N menit pertama, default 5 menit)
    final int baselineDurationSec = 5 * 60;
    final baselineReadings = readings.where((r) => r.ts <= (currentSession.startTs + baselineDurationSec)).map((r) => r.leqDba).toList();
    final double baselineLeq = AcousticMath.computeLeq(baselineReadings);

    // 6. Hitung Final Condition (N menit terakhir, default 5 menit)
    final int finalStartBoundary = endTs - (5 * 60);
    final finalReadings = readings.where((r) => r.ts >= finalStartBoundary).map((r) => r.leqDba).toList();
    final double finalLeq = AcousticMath.computeLeq(finalReadings.isNotEmpty ? finalReadings : baselineReadings);

    // 7. Hitung Delta Leq
    final double deltaLeq = AcousticMath.computeDeltaLeq(baselineLeq, finalLeq);

    // 8. Rincian Anomali
    final anomalyReadings = readings.where((r) => r.isAnomaly).toList();
    final int pointCount = anomalyReadings.where((r) => r.anomalyType == 'point').length;
    final int collectiveCount = anomalyReadings.where((r) => r.anomalyType == 'collective').length;

    // 9. Generate Kesimpulan Otomatis Deterministik (FR-9)
    final int durationMinutes = ((endTs - currentSession.startTs) / 60).ceil().clamp(1, 9999);
    final String autoConclusion = AutoConclusionGenerator.generate(
      durationMinutes: durationMinutes,
      locationName: locationName,
      leqPeriod: leqPeriod,
      baselineLeq: baselineLeq,
      finalLeq: finalLeq,
      deltaLeq: deltaLeq,
      lmax: lmax,
      lmaxTs: lmaxTs,
      anomalyCount: anomalyReadings.length,
      pointAnomalyCount: pointCount,
      collectiveAnomalyCount: collectiveCount,
      pctRed: pctRed,
    );

    final report = SessionReport(
      sessionId: currentSession.id,
      nodeIds: currentSession.nodeIds,
      periodStartTs: currentSession.startTs,
      periodEndTs: endTs,
      sampleCount: sampleCount,
      noGpsCount: noGpsCount,
      baselineMinutes: 5,
      finalMinutes: 5,
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
      anomalyCount: anomalyReadings.length,
      anomalyBreakdown: {'point': pointCount, 'collective': collectiveCount},
      autoConclusion: autoConclusion,
      userConclusion: userConclusion,
      thresholdSnapshot: currentSession.thresholdSnapshot,
      calibSnapshot: currentSession.calibSnapshot,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );

    _sessionHistory.insert(0, currentSession);
    _reportsMap[currentSession.id] = report;
    _activeSession = null;

    if (Firebase.apps.isNotEmpty && firestore != null) {
      try {
        await firestore!.collection('sessions').doc(currentSession.id).update({
          'status': 'ended',
          'endTs': endTs,
        });
        await firestore!.collection('reports').doc(currentSession.id).set(report.toFirestore());
      } catch (_) {}
    }

    return report;
  }

  SessionReport? getReport(String sessionId) => _reportsMap[sessionId];
  List<MeasurementSession> getSessionHistory() => List.unmodifiable(_sessionHistory);
}
