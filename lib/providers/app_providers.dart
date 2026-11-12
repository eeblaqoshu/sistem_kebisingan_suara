import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/noise_reading.dart';
import '../models/node_device.dart';
import '../models/location_point.dart';
import '../models/measurement_session.dart';
import '../models/session_event.dart';
import '../models/app_settings.dart';
import '../repositories/telemetry_repository.dart';
import '../repositories/node_repository.dart';
import '../repositories/location_repository.dart';
import '../repositories/session_repository.dart';

// Repositories
final telemetryRepoProvider = Provider<TelemetryRepository>((ref) => TelemetryRepository());
final nodeRepoProvider = Provider<NodeRepository>((ref) => NodeRepository());
final locationRepoProvider = Provider<LocationRepository>((ref) => LocationRepository());
final sessionRepoProvider = Provider<SessionRepository>((ref) => SessionRepository());

// Selected Node Notifier
class SelectedNodeNotifier extends Notifier<String> {
  @override
  String build() => 'NODE_POLINES_01';

  void setNode(String id) => state = id;
}

final selectedNodeIdProvider =
    NotifierProvider<SelectedNodeNotifier, String>(SelectedNodeNotifier.new);

// Settings Notifier
class AppSettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => AppSettings();

  void updateSettings(AppSettings newSettings) => state = newSettings;
}

final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettings>(AppSettingsNotifier.new);

// Nodes Stream Provider
final nodesStreamProvider = StreamProvider<List<NodeDevice>>((ref) {
  final repo = ref.watch(nodeRepoProvider);
  return repo.streamNodes();
});

// Locations Stream Provider
final locationsStreamProvider = StreamProvider<List<LocationPoint>>((ref) {
  final repo = ref.watch(locationRepoProvider);
  return repo.streamLocations();
});

// Real-time Telemetry Stream Provider untuk Node Terpilih
final latestReadingStreamProvider = StreamProvider.autoDispose<NoiseReading>((ref) {
  final selectedNode = ref.watch(selectedNodeIdProvider);
  final repo = ref.watch(telemetryRepoProvider);
  final sessionRepo = ref.watch(sessionRepoProvider);

  final stream = repo.streamLatestReading(selectedNode);

  // Sambungkan pembacaan ke session repo untuk auto event debouncing
  final sub = stream.listen((reading) {
    sessionRepo.processTelemetryForAutoEvents(reading);
  });

  ref.onDispose(() {
    sub.cancel();
  });

  return stream;
});

// Riwayat pembacaan sesi aktif (in-memory buffer untuk grafik dan kalkulasi laporan)
class SessionReadingsBufferNotifier extends Notifier<List<NoiseReading>> {
  @override
  List<NoiseReading> build() => [];

  void addReading(NoiseReading reading) {
    state = [...state, reading];
  }

  void clear() {
    state = [];
  }
}

final sessionReadingsBufferProvider =
    NotifierProvider<SessionReadingsBufferNotifier, List<NoiseReading>>(
  SessionReadingsBufferNotifier.new,
);

// Active Session Notifier
class ActiveSessionNotifier extends Notifier<MeasurementSession?> {
  @override
  MeasurementSession? build() {
    final sessionRepo = ref.watch(sessionRepoProvider);
    return sessionRepo.activeSession;
  }

  void refresh() {
    final sessionRepo = ref.read(sessionRepoProvider);
    state = sessionRepo.activeSession;
  }

  Future<MeasurementSession> startSession({
    required String name,
    required String purpose,
    required List<String> nodeIds,
    required List<String> locationPointIds,
    required Map<String, dynamic> calibSnapshot,
    required Map<String, dynamic> thresholdSnapshot,
  }) async {
    final sessionRepo = ref.read(sessionRepoProvider);
    final sess = await sessionRepo.startSession(
      name: name,
      purpose: purpose,
      nodeIds: nodeIds,
      locationPointIds: locationPointIds,
      calibSnapshot: calibSnapshot,
      thresholdSnapshot: thresholdSnapshot,
    );
    state = sess;
    return sess;
  }

  Future<void> endSession() async {
    state = null;
  }
}

final activeSessionProvider =
    NotifierProvider<ActiveSessionNotifier, MeasurementSession?>(ActiveSessionNotifier.new);

// Active Events Provider
final activeEventsProvider = Provider<List<SessionEvent>>((ref) {
  final repo = ref.watch(sessionRepoProvider);
  return repo.activeEvents;
});
