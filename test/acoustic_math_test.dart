import 'package:flutter_test/flutter_test.dart';
import 'package:geoleq_application/utils/acoustic_math.dart';
import 'package:geoleq_application/utils/auto_conclusion.dart';

void main() {
  group('AcousticMath Tests', () {
    test('computeLeq identical values return exact value', () {
      final values = [60.0, 60.0, 60.0];
      final leq = AcousticMath.computeLeq(values);
      expect(leq, 60.0);
    });

    test('computeLeq calculates true logarithmic aggregation', () {
      // 60 dBA and 63 dBA:
      // P1 = 10^6, P2 = 10^6.3 = 1995262.3
      // Mean P = (1000000 + 1995262.3) / 2 = 1497631.15
      // 10 * log10(1497631.15) = 61.754 dBA -> rounded to 61.8 dBA
      final values = [60.0, 63.0];
      final leq = AcousticMath.computeLeq(values);
      expect(leq, 61.8);
      // Memastikan bukan rata-rata aritmatika (61.5)
      expect(leq, isNot(61.5));
    });

    test('computeLeq handles empty and single item correctly', () {
      expect(AcousticMath.computeLeq([]), 0.0);
      expect(AcousticMath.computeLeq([72.4]), 72.4);
    });

    test('computePercentiles calculates L10, L50, L90 accurately', () {
      // 10 sample terurut: 80, 75, 70, 65, 60, 55, 50, 45, 40, 35
      final values = [35.0, 40.0, 45.0, 50.0, 55.0, 60.0, 65.0, 70.0, 75.0, 80.0];
      final percentiles = AcousticMath.computePercentiles(values);

      // Descending: [80, 75, 70, 65, 60, 55, 50, 45, 40, 35]
      // L10 (puncak) di index (9 * 0.1) = 1 -> 75.0
      // L50 (median) di index (9 * 0.5) = 5 -> 55.0 (atau 60.0 tergantung rounding)
      // L90 (background) di index (9 * 0.9) = 8 -> 40.0
      expect(percentiles['l10'], 75.0);
      expect(percentiles['l50'], 55.0);
      expect(percentiles['l90'], 40.0);
    });

    test('computeDeltaLeq calculates final - baseline', () {
      final delta = AcousticMath.computeDeltaLeq(61.0, 68.1);
      expect(delta, 7.1);
    });

    test('categorizeDb returns correct color categories', () {
      expect(AcousticMath.categorizeDb(50.0), 'green');
      expect(AcousticMath.categorizeDb(55.0), 'yellow');
      expect(AcousticMath.categorizeDb(68.5), 'yellow');
      expect(AcousticMath.categorizeDb(70.0), 'yellow');
      expect(AcousticMath.categorizeDb(70.1), 'red');
      expect(AcousticMath.categorizeDb(85.0), 'red');
    });
  });

  group('AutoConclusionGenerator Tests (FR-9)', () {
    test('generates expected deterministic report conclusion', () {
      final conclusion = AutoConclusionGenerator.generate(
        durationMinutes: 60,
        locationName: 'Gerbang Utama Polines',
        leqPeriod: 66.2,
        baselineLeq: 61.0,
        finalLeq: 68.1,
        deltaLeq: 7.1,
        lmax: 84.3,
        lmaxTs: 1794511825,
        anomalyCount: 3,
        pointAnomalyCount: 2,
        collectiveAnomalyCount: 1,
        pctRed: 18.0,
      );

      expect(conclusion, contains('Selama 60 menit pengukuran di Gerbang Utama Polines'));
      expect(conclusion, contains('Leq periode 66,2 dBA (kategori sedang)'));
      expect(conclusion, contains('Kebisingan naik 7,1 dBA'));
      expect(conclusion, contains('Lmax 84,3 dBA'));
      expect(conclusion, contains('Terdeteksi 3 anomali (2 point, 1 collective)'));
      expect(conclusion, contains('18% waktu berada di kategori tinggi'));
    });
  });
}
