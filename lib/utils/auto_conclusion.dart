import 'package:intl/intl.dart';

/// Generator kesimpulan otomatis deterministik berbasis aturan (FR-9 PRD GeoLeq)
class AutoConclusionGenerator {
  /// Membentuk teks kesimpulan deterministik dari parameter sesi
  static String generate({
    required int durationMinutes,
    required String locationName,
    required double leqPeriod,
    required double baselineLeq,
    required double finalLeq,
    required double deltaLeq,
    required double lmax,
    required int? lmaxTs,
    required int anomalyCount,
    required int pointAnomalyCount,
    required int collectiveAnomalyCount,
    required double pctRed,
  }) {
    // 1. Kategori Leq Periode
    String categoryLabel;
    if (leqPeriod < 55.0) {
      categoryLabel = 'kategori normal/rendah';
    } else if (leqPeriod <= 70.0) {
      categoryLabel = 'kategori sedang';
    } else {
      categoryLabel = 'kategori tinggi/bising';
    }

    // 2. Analisis Tren Delta Leq (ambang batas +/- 3 dBA)
    String trendSentence;
    final String baselineStr = baselineLeq.toStringAsFixed(1).replaceAll('.', ',');
    final String finalStr = finalLeq.toStringAsFixed(1).replaceAll('.', ',');
    final String deltaStr = deltaLeq.abs().toStringAsFixed(1).replaceAll('.', ',');

    if (deltaLeq >= 3.0) {
      trendSentence =
          'Kebisingan naik $deltaStr dBA dari kondisi awal ($baselineStr dBA) ke kondisi akhir ($finalStr dBA).';
    } else if (deltaLeq <= -3.0) {
      trendSentence =
          'Kebisingan turun $deltaStr dBA dari kondisi awal ($baselineStr dBA) ke kondisi akhir ($finalStr dBA).';
    } else {
      trendSentence =
          'Tingkat kebisingan relatif stabil dengan fluktuasi $deltaStr dBA antara kondisi awal ($baselineStr dBA) dan akhir ($finalStr dBA).';
    }

    // 3. Waktu Lmax
    String lmaxTimeStr = '';
    if (lmaxTs != null && lmaxTs > 0) {
      final date = DateTime.fromMillisecondsSinceEpoch(lmaxTs * 1000);
      lmaxTimeStr = ' tercatat pukul ${DateFormat('HH:mm').format(date)}';
    }
    final String lmaxSentence =
        'Lmax ${lmax.toStringAsFixed(1).replaceAll('.', ',')} dBA$lmaxTimeStr.';

    // 4. Anomali & Zona Merah
    final String pctRedStr = pctRed.toStringAsFixed(0);
    String anomalySentence;
    if (anomalyCount > 0) {
      anomalySentence =
          'Terdeteksi $anomalyCount anomali ($pointAnomalyCount point, $collectiveAnomalyCount collective); $pctRedStr% waktu berada di kategori tinggi.';
    } else {
      anomalySentence =
          'Tidak terdeteksi anomali akustik; $pctRedStr% waktu berada di kategori tinggi.';
    }

    final String leqPeriodStr = leqPeriod.toStringAsFixed(1).replaceAll('.', ',');

    return 'Selama $durationMinutes menit pengukuran di $locationName, '
        'Leq periode $leqPeriodStr dBA ($categoryLabel). '
        '$trendSentence '
        '$lmaxSentence '
        '$anomalySentence';
  }
}
