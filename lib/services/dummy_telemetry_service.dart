import 'dart:async';
import 'dart:math' as math;
import '../models/noise_reading.dart';
import '../utils/acoustic_math.dart';

/// Service simulator telemetri ESP32 untuk pengujian lokal/demo sebelum hardware live
class DummyTelemetryService {
  static final DummyTelemetryService _instance = DummyTelemetryService._internal();
  factory DummyTelemetryService() => _instance;
  DummyTelemetryService._internal();

  Timer? _timer;
  final _controller = StreamController<NoiseReading>.broadcast();
  Stream<NoiseReading> get stream => _controller.stream;

  final math.Random _random = math.Random();
  double _currentLeq = 62.5;
  int _counter = 0;

  // Koordinat acuan (Polines Tembalang)
  final double _baseLat = -7.052012;
  final double _baseLng = 110.435412;

  NoiseReading? _latestReading;
  NoiseReading? get latestReading => _latestReading;

  void start({String deviceId = 'NODE_POLINES_01', int intervalSec = 2}) {
    if (_timer != null) return;

    _timer = Timer.periodic(Duration(seconds: intervalSec), (_) {
      _counter++;

      // Simulasi fluktuasi kebisingan realistis di jalan / kampus
      final double drift = (_random.nextDouble() - 0.48) * 3.5;
      _currentLeq = (_currentLeq + drift).clamp(45.0, 92.0);

      // Simulasi anomali TinyML sesekali (setiap ~15 pembacaan)
      bool isAnomaly = false;
      String anomalyType = 'normal';
      if (_counter % 18 == 0) {
        isAnomaly = true;
        anomalyType = _random.nextBool() ? 'point' : 'collective';
        _currentLeq = 82.0 + (_random.nextDouble() * 8.0); // Lonjakan tajam
      }

      // Simulasi GPS Fix (95% fix, sesekali no fix untuk uji ketahanan)
      final bool gpsFix = _counter % 25 != 0;
      final double lat = gpsFix ? _baseLat + ((_random.nextDouble() - 0.5) * 0.002) : 0.0;
      final double lng = gpsFix ? _baseLng + ((_random.nextDouble() - 0.5) * 0.002) : 0.0;

      final roundedLeq = (math.pow(10, 1) * _currentLeq).round() / 10.0;
      final category = AcousticMath.categorizeDb(roundedLeq);

      final now = DateTime.now();
      final reading = NoiseReading(
        deviceId: deviceId,
        ts: now.millisecondsSinceEpoch ~/ 1000,
        timestampIso: now.toUtc().toIso8601String(),
        leqDba: roundedLeq,
        category: category,
        isAnomaly: isAnomaly,
        anomalyType: anomalyType,
        gpsFix: gpsFix,
        latitude: lat,
        longitude: lng,
      );

      _latestReading = reading;
      _controller.add(reading);
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
