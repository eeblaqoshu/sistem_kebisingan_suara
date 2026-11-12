import 'dart:math' as math;

/// Modul perhitungan matematis akustik standar sesuai kaidah ISO 1996 dan PRD GeoLeq
class AcousticMath {
  /// Menghitung Rata-rata Kebisingan Setara Logaritmik (Leq):
  /// Leq = 10 * log10( (1/N) * sum(10^(Li/10)) )
  ///
  /// DILARANG menggunakan rata-rata aritmatika biasa untuk desibel.
  static double computeLeq(List<double> dbValues) {
    if (dbValues.isEmpty) return 0.0;
    if (dbValues.length == 1) return _round1(dbValues.first);

    double sumPower = 0.0;
    int validCount = 0;

    for (final db in dbValues) {
      if (db.isFinite && db >= 0) {
        sumPower += math.pow(10.0, db / 10.0);
        validCount++;
      }
    }

    if (validCount == 0) return 0.0;

    final double meanPower = sumPower / validCount;
    if (meanPower <= 0) return 0.0;

    final double leq = 10.0 * (math.log(meanPower) / math.ln10);
    return _round1(leq);
  }

  /// Menghitung persentil statistik kebisingan (L10, L50, L90):
  /// - L10: Tingkat suara yang dilampaui selama 10% waktu (puncak kebisingan)
  /// - L50: Median tingkat suara (dilampaui selama 50% waktu)
  /// - L90: Background noise level (dilampaui selama 90% waktu)
  ///
  /// Menghasilkan Map dengan key: 'l10', 'l50', 'l90'
  static Map<String, double> computePercentiles(List<double> dbValues) {
    if (dbValues.isEmpty) {
      return {'l10': 0.0, 'l50': 0.0, 'l90': 0.0};
    }

    // Filter nilai valid lalu urutkan dari TERBESAR ke TERKECIL (descending)
    final sorted = dbValues.where((v) => v.isFinite && v >= 0).toList()
      ..sort((a, b) => b.compareTo(a));

    if (sorted.isEmpty) {
      return {'l10': 0.0, 'l50': 0.0, 'l90': 0.0};
    }

    final int n = sorted.length;

    // Index perhitungan
    final int idx10 = ((n - 1) * 0.10).round().clamp(0, n - 1);
    final int idx50 = ((n - 1) * 0.50).round().clamp(0, n - 1);
    final int idx90 = ((n - 1) * 0.90).round().clamp(0, n - 1);

    return {
      'l10': _round1(sorted[idx10]),
      'l50': _round1(sorted[idx50]),
      'l90': _round1(sorted[idx90]),
    };
  }

  /// Menghitung selisih Delta Leq: Leq(akhir) - Leq(awal)
  static double computeDeltaLeq(double baselineLeq, double finalLeq) {
    return _round1(finalLeq - baselineLeq);
  }

  /// Menghitung Lmax (nilai tertinggi)
  static double computeLmax(List<double> dbValues) {
    if (dbValues.isEmpty) return 0.0;
    return _round1(dbValues.reduce(math.max));
  }

  /// Menghitung Lmin (nilai terendah)
  static double computeLmin(List<double> dbValues) {
    if (dbValues.isEmpty) return 0.0;
    return _round1(dbValues.reduce(math.min));
  }

  /// Menghitung distribusi persentase per kategori warna
  static Map<String, double> computeCategoryPercentages(
    List<double> dbValues, {
    double thresholdYellow = 55.0,
    double thresholdRed = 70.0,
  }) {
    if (dbValues.isEmpty) {
      return {'green': 0.0, 'yellow': 0.0, 'red': 0.0};
    }

    int green = 0;
    int yellow = 0;
    int red = 0;

    for (final db in dbValues) {
      if (db < thresholdYellow) {
        green++;
      } else if (db <= thresholdRed) {
        yellow++;
      } else {
        red++;
      }
    }

    final int total = dbValues.length;
    return {
      'green': _round1((green / total) * 100.0),
      'yellow': _round1((yellow / total) * 100.0),
      'red': _round1((red / total) * 100.0),
    };
  }

  /// Menentukan kategori (green / yellow / red) berdasarkan nilai dBA
  static String categorizeDb(
    double db, {
    double thresholdYellow = 55.0,
    double thresholdRed = 70.0,
  }) {
    if (db < thresholdYellow) return 'green';
    if (db <= thresholdRed) return 'yellow';
    return 'red';
  }

  static double _round1(double val) {
    return (val * 10.0).round() / 10.0;
  }
}
