import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

/// Layar Tab 3: Grafik Tren Kebisingan fl_chart (FR-4)
class NoiseTrendScreen extends ConsumerStatefulWidget {
  const NoiseTrendScreen({super.key});

  @override
  ConsumerState<NoiseTrendScreen> createState() => _NoiseTrendScreenState();
}

class _NoiseTrendScreenState extends ConsumerState<NoiseTrendScreen> {
  String _selectedRange = '1 Jam'; // '1 Jam', '24 Jam', '7 Hari'

  @override
  Widget build(BuildContext context) {
    final bufferReadings = ref.watch(sessionReadingsBufferProvider);
    final events = ref.watch(activeEventsProvider);
    final settings = ref.watch(appSettingsProvider);

    final spots = <FlSpot>[];
    for (int i = 0; i < bufferReadings.length; i++) {
      spots.add(FlSpot(i.toDouble(), bufferReadings[i].leqDba));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tren & Ambang Batas', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: '1 Jam', label: Text('1 Jam', style: TextStyle(fontSize: 11))),
                ButtonSegment(value: '24 Jam', label: Text('24 Jam', style: TextStyle(fontSize: 11))),
                ButtonSegment(value: '7 Hari', label: Text('7 Hari', style: TextStyle(fontSize: 11))),
              ],
              selected: {_selectedRange},
              onSelectionChanged: (set) {
                setState(() => _selectedRange = set.first);
              },
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Legenda Ambang Batas
            Row(
              children: [
                _buildLegendItem('Normal (<55 dBA)', AppTheme.greenNormal),
                const SizedBox(width: 12),
                _buildLegendItem('Sedang (55-70 dBA)', AppTheme.yellowMedium),
                const SizedBox(width: 12),
                _buildLegendItem('Tinggi (>70 dBA)', AppTheme.redHigh),
              ],
            ),
            const SizedBox(height: 16),

            // Grafik fl_chart
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
                  child: spots.isEmpty
                      ? const Center(
                          child: Text(
                            'Mengumpulkan data telemetri...',
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                        )
                      : LineChart(
                          LineChartData(
                            minY: 40,
                            maxY: 95,
                            gridData: FlGridData(
                              show: true,
                              horizontalInterval: 10,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: Colors.grey.withValues(alpha: 0.2),
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 36,
                                  interval: 10,
                                  getTitlesWidget: (val, meta) => Text(
                                    val.toInt().toString(),
                                    style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 24,
                                  getTitlesWidget: (val, meta) => Text(
                                    '#${val.toInt()}',
                                    style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                  ),
                                ),
                              ),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            // Garis Ambang Batas Horizontal (55 dBA & 70 dBA)
                            extraLinesData: ExtraLinesData(
                              horizontalLines: [
                                HorizontalLine(
                                  y: settings.thresholdYellow,
                                  color: AppTheme.yellowMedium.withValues(alpha: 0.8),
                                  strokeWidth: 2,
                                  dashArray: [6, 4],
                                  label: HorizontalLineLabel(
                                    show: true,
                                    labelResolver: (line) => 'Ambang Kuning (55 dBA)',
                                    style: const TextStyle(fontSize: 10, color: AppTheme.yellowMedium, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                HorizontalLine(
                                  y: settings.thresholdRed,
                                  color: AppTheme.redHigh.withValues(alpha: 0.8),
                                  strokeWidth: 2,
                                  dashArray: [6, 4],
                                  label: HorizontalLineLabel(
                                    show: true,
                                    labelResolver: (line) => 'Ambang Merah (70 dBA)',
                                    style: const TextStyle(fontSize: 10, color: AppTheme.redHigh, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                curveSmoothness: 0.2,
                                color: AppTheme.primaryBlue,
                                barWidth: 2.5,
                                dotData: FlDotData(
                                  show: true,
                                  checkToShowDot: (spot, barData) {
                                    final index = spot.x.toInt();
                                    if (index < bufferReadings.length) {
                                      return bufferReadings[index].isAnomaly;
                                    }
                                    return false;
                                  },
                                  getDotPainter: (spot, percent, barData, index) {
                                    return FlDotCirclePainter(
                                      radius: 6,
                                      color: AppTheme.purpleAnomaly,
                                      strokeWidth: 2,
                                      strokeColor: Colors.white,
                                    );
                                  },
                                ),
                              ),
                            ],
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((touched) {
                                    final index = touched.spotIndex;
                                    final r = bufferReadings[index];
                                    return LineTooltipItem(
                                      '${r.leqDba} dBA\n${Formatters.formatTimeOnly(r.ts)}',
                                      const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Indikator Titik Anomali & Catatan
            if (events.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.history, size: 16, color: AppTheme.primaryBlue),
                      const SizedBox(width: 8),
                      Text(
                        'Kejadian Terakhir: ${events.last.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
