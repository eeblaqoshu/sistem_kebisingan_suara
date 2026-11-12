import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/measurement_session.dart';
import '../models/session_report.dart';
import '../models/session_event.dart';
import '../models/noise_reading.dart';
import '../utils/formatters.dart';

/// Layanan ekspor Laporan Sesi ke PDF (9 bagian wajib) dan CSV
class ExportService {
  /// Generate dan bagikan dokumen PDF Laporan Sesi (9 Bagian Wajib)
  static Future<void> exportReportPdf({
    required MeasurementSession session,
    required SessionReport report,
    required List<SessionEvent> events,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'LAPORAN AKHIR SESI PENGUKURAN KEBISINGAN',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Sistem Pemetaan Polusi Suara - Tubes IoT Polines Kelompok 2',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Text(
                    'SESI: ${session.id}',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // 1. Identitas Sesi
            _buildSectionHeader('1. Identitas Sesi'),
            _buildKeyValue('Nama Sesi', session.name),
            _buildKeyValue('Tujuan Pengujian', session.purpose),
            _buildKeyValue('Waktu Mulai', Formatters.formatDateTime(session.startTs)),
            _buildKeyValue('Waktu Selesai', Formatters.formatDateTime(session.endTs ?? session.startTs)),
            _buildKeyValue('Daftar Node ID', session.nodeIds.join(', ')),
            _buildKeyValue('Titik Lokasi ID', session.locationPointIds.join(', ')),
            _buildKeyValue('Snapshot Ambang', 'Kuning: ${report.thresholdSnapshot['yellow']} dBA, Merah: ${report.thresholdSnapshot['red']} dBA'),
            pw.SizedBox(height: 8),

            // 2. Kondisi Awal (Baseline)
            _buildSectionHeader('2. Kondisi Awal (Baseline)'),
            _buildKeyValue('Durasi Baseline', '${report.baselineMinutes} Menit pertama'),
            _buildKeyValue('Leq Baseline (Logaritmik)', '${report.baselineLeq} dBA'),
            pw.SizedBox(height: 8),

            // 3. Kronologi Kejadian
            _buildSectionHeader('3. Kronologi Kejadian (${events.length} Terdata)'),
            if (events.isEmpty)
              pw.Text('Tidak ada catatan kejadian selama sesi berlangsung.', style: const pw.TextStyle(fontSize: 10))
            else
              pw.TableHelper.fromTextArray(
                headers: ['Waktu', 'Tipe', 'Jenis', 'Keterangan'],
                data: events.take(15).map((e) => [
                  Formatters.formatTimeOnly(e.ts),
                  e.type.toUpperCase(),
                  e.kind,
                  e.title,
                ]).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                cellStyle: const pw.TextStyle(fontSize: 8),
              ),
            pw.SizedBox(height: 8),

            // 4. Statistik Keseluruhan
            _buildSectionHeader('4. Statistik Keseluruhan'),
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildKeyValue('Leq Periode (Logaritmik)', '${report.leqPeriod} dBA'),
                      _buildKeyValue('Lmax (Maksimum)', '${report.lmax} dBA'),
                      _buildKeyValue('Lmin (Minimum)', '${report.lmin} dBA'),
                      _buildKeyValue('Total Sampel Data', '${report.sampleCount} titik'),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildKeyValue('L10 (Puncak)', '${report.l10} dBA'),
                      _buildKeyValue('L50 (Median)', '${report.l50} dBA'),
                      _buildKeyValue('L90 (Background)', '${report.l90} dBA'),
                      _buildKeyValue('Data Tanpa GPS Fix', '${report.noGpsCount} titik'),
                    ],
                  ),
                ),
              ],
            ),
            _buildKeyValue('Distribusi Kategori', 'Hijau (Normal): ${report.pctGreen}%, Kuning (Sedang): ${report.pctYellow}%, Merah (Tinggi): ${report.pctRed}%'),
            pw.SizedBox(height: 8),

            // 5. Analisis Anomali TinyML
            _buildSectionHeader('5. Analisis Anomali TinyML'),
            _buildKeyValue('Total Anomali Terdeteksi', '${report.anomalyCount} kejadian'),
            _buildKeyValue('Rincian Anomali', 'Point Anomaly: ${report.anomalyBreakdown['point'] ?? 0}, Collective Anomaly: ${report.anomalyBreakdown['collective'] ?? 0}'),
            pw.SizedBox(height: 8),

            // 6. Kondisi Akhir & Perbandingan
            _buildSectionHeader('6. Kondisi Akhir & Perbandingan (Delta Leq)'),
            _buildKeyValue('Durasi Kondisi Akhir', '${report.finalMinutes} Menit terakhir'),
            _buildKeyValue('Leq Kondisi Akhir', '${report.finalLeq} dBA'),
            _buildKeyValue('Delta Leq (Akhir - Awal)', '${report.deltaLeq >= 0 ? "+" : ""}${report.deltaLeq} dBA'),
            pw.SizedBox(height: 8),

            // 7. Peta Titik Pengukuran
            _buildSectionHeader('7. Peta Titik Pengukuran'),
            pw.Text(
              'Titik pengukuran terekam pada koordinat node terkait di area kampus/lapangan dengan kepatuhan spasial OpenStreetMap.',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 8),

            // 8. Grafik Tren Sesi
            _buildSectionHeader('8. Grafik Tren Sesi'),
            pw.Text(
              'Grafik fluktuasi Leq terhadap waktu tersimpan secara digital pada aplikasi, memuat garis batas 55 dBA dan 70 dBA.',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 8),

            // 9. Kesimpulan & Rekomendasi
            _buildSectionHeader('9. Kesimpulan & Rekomendasi'),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Kesimpulan Otomatis (Rule-Based FR-9):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  pw.Text(report.autoConclusion, style: const pw.TextStyle(fontSize: 9)),
                  if (report.userConclusion.isNotEmpty) ...[
                    pw.SizedBox(height: 6),
                    pw.Text('Catatan Tambahan Peneliti:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    pw.Text(report.userConclusion, style: const pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic)),
                  ],
                ],
              ),
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Laporan_Sesi_${session.id}.pdf',
    );
  }

  /// Ekspor seluruh data mentah bacaan sensor ke file CSV
  static Future<void> exportReadingsCsv({
    required MeasurementSession session,
    required List<NoiseReading> readings,
    required List<SessionEvent> events,
  }) async {
    final List<List<dynamic>> rows = [
      ['Timestamp (Epoch)', 'Timestamp (ISO)', 'Device ID', 'Leq (dBA)', 'Kategori', 'Is Anomaly', 'Anomaly Type', 'GPS Fix', 'Latitude', 'Longitude'],
      ...readings.map((r) => [
        r.ts,
        r.timestampIso,
        r.deviceId,
        r.leqDba,
        r.category,
        r.isAnomaly,
        r.anomalyType,
        r.gpsFix,
        r.latitude,
        r.longitude,
      ]),
    ];

    final String csvData = csv.encode(rows);

    await SharePlus.instance.share(
      ShareParams(
        text: csvData,
        subject: 'Data_Sensor_${session.id}.csv',
      ),
    );
  }

  static pw.Widget _buildSectionHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue800,
        ),
      ),
    );
  }

  static pw.Widget _buildKeyValue(String key, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 160,
            child: pw.Text(key, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text(': ', style: const pw.TextStyle(fontSize: 9)),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
          ),
        ],
      ),
    );
  }
}
