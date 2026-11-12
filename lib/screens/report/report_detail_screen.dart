import 'package:flutter/material.dart';
import '../../models/measurement_session.dart';
import '../../models/session_report.dart';
import '../../models/session_event.dart';
import '../../models/noise_reading.dart';
import '../../services/export_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

/// Layar Tampilan Lengkap Laporan Akhir Sesi 9 Bagian Wajib (FR-8)
class ReportDetailScreen extends StatefulWidget {
  final MeasurementSession session;
  final SessionReport report;
  final List<SessionEvent> events;
  final List<NoiseReading> readings;

  const ReportDetailScreen({
    super.key,
    required this.session,
    required this.report,
    required this.events,
    required this.readings,
  });

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  late TextEditingController _userConclusionCtrl;

  @override
  void initState() {
    super.initState();
    _userConclusionCtrl = TextEditingController(text: widget.report.userConclusion);
  }

  @override
  Widget build(BuildContext context) {
    final rep = widget.report;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Akhir Sesi', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Ekspor PDF 9 Bagian',
            onPressed: () {
              ExportService.exportReportPdf(
                session: widget.session,
                report: rep.copyWith(userConclusion: _userConclusionCtrl.text.trim()),
                events: widget.events,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.table_chart),
            tooltip: 'Ekspor Data CSV',
            onPressed: () {
              ExportService.exportReadingsCsv(
                session: widget.session,
                readings: widget.readings,
                events: widget.events,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Identitas Sesi
            _buildSectionCard(
              title: '1. Identitas Sesi',
              child: Column(
                children: [
                  _buildRow('Nama Sesi', widget.session.name),
                  _buildRow('Tujuan Pengujian', widget.session.purpose),
                  _buildRow('Waktu Mulai', Formatters.formatDateTime(widget.session.startTs)),
                  _buildRow('Waktu Selesai', Formatters.formatDateTime(widget.session.endTs ?? widget.session.startTs)),
                  _buildRow('Node Terkait', widget.session.nodeIds.join(', ')),
                  _buildRow('Snapshot Ambang', 'Kuning: ${rep.thresholdSnapshot['yellow']} dBA, Merah: ${rep.thresholdSnapshot['red']} dBA'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2. Kondisi Awal Baseline
            _buildSectionCard(
              title: '2. Kondisi Awal (Baseline)',
              child: Column(
                children: [
                  _buildRow('Durasi Baseline', '${rep.baselineMinutes} Menit pertama'),
                  _buildRow('Leq Baseline (Logaritmik)', '${rep.baselineLeq} dBA', isBold: true),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 3. Kronologi Kejadian
            _buildSectionCard(
              title: '3. Kronologi Kejadian (${widget.events.length} Peristiwa)',
              child: widget.events.isEmpty
                  ? const Text('Tidak ada kejadian yang tercatat.', style: TextStyle(fontSize: 12, color: AppTheme.textMuted))
                  : Column(
                      children: widget.events.map((e) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(Formatters.formatTimeOnly(e.ts), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('${e.title} ${e.notes.isNotEmpty ? "(${e.notes})" : ""}', style: const TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 12),

            // 4. Statistik Keseluruhan
            _buildSectionCard(
              title: '4. Statistik Keseluruhan',
              child: Column(
                children: [
                  _buildRow('Leq Periode (Logaritmik ISO)', '${rep.leqPeriod} dBA', isBold: true, highlightColor: AppTheme.primaryBlue),
                  _buildRow('Lmax (Maksimum)', '${rep.lmax} dBA', highlightColor: AppTheme.redHigh),
                  _buildRow('Lmin (Minimum)', '${rep.lmin} dBA'),
                  _buildRow('Persentil Puncak (L10)', '${rep.l10} dBA'),
                  _buildRow('Median Suara (L50)', '${rep.l50} dBA'),
                  _buildRow('Background Noise (L90)', '${rep.l90} dBA'),
                  _buildRow('Distribusi Kategori', 'Hijau: ${rep.pctGreen}% | Kuning: ${rep.pctYellow}% | Merah: ${rep.pctRed}%'),
                  _buildRow('Total Sampel Data', '${rep.sampleCount} titik (No GPS Fix: ${rep.noGpsCount})'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 5. Analisis Anomali
            _buildSectionCard(
              title: '5. Analisis Anomali TinyML',
              child: Column(
                children: [
                  _buildRow('Total Anomali', '${rep.anomalyCount} kejadian', highlightColor: AppTheme.purpleAnomaly),
                  _buildRow('Point Anomaly', '${rep.anomalyBreakdown['point'] ?? 0} kejadian'),
                  _buildRow('Collective Anomaly', '${rep.anomalyBreakdown['collective'] ?? 0} kejadian'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 6. Kondisi Akhir & Perbandingan
            _buildSectionCard(
              title: '6. Kondisi Akhir & Perbandingan (Delta Leq)',
              child: Column(
                children: [
                  _buildRow('Leq Kondisi Akhir', '${rep.finalLeq} dBA', isBold: true),
                  _buildRow('Delta Leq (Akhir - Awal)', '${rep.deltaLeq >= 0 ? "+" : ""}${rep.deltaLeq} dBA',
                      isBold: true, highlightColor: rep.deltaLeq > 0 ? AppTheme.redHigh : AppTheme.greenNormal),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 7. Peta & 8. Grafik Tren
            _buildSectionCard(
              title: '7 & 8. Spasial OSM & Grafik Tren',
              child: const Text(
                'Data spasial dan jejak koordinat GPS tersinkronisasi dalam basis data Firestore & RTDB.',
                style: TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),

            // 9. Kesimpulan & Rekomendasi
            _buildSectionCard(
              title: '9. Kesimpulan & Rekomendasi',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Kesimpulan Otomatis Berbasis Aturan (FR-9):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.darkBlue)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Text(rep.autoConclusion, style: const TextStyle(fontSize: 12, height: 1.4)),
                  ),
                  const SizedBox(height: 12),
                  const Text('Catatan/Kesimpulan Tambahan Peneliti (Dapat Diedit):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _userConclusionCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Tuliskan catatan analisis tambahan di sini...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tombol Ekspor Bawah
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ExportService.exportReportPdf(
                        session: widget.session,
                        report: rep.copyWith(userConclusion: _userConclusionCtrl.text.trim()),
                        events: widget.events,
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Unduh PDF 9 Bagian'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ExportService.exportReadingsCsv(
                        session: widget.session,
                        readings: widget.readings,
                        events: widget.events,
                      );
                    },
                    icon: const Icon(Icons.table_chart),
                    label: const Text('Unduh CSV'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.darkBlue)),
            const Divider(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, Color? highlightColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: highlightColor ?? AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
