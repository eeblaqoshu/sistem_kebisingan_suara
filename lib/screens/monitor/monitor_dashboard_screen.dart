import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../models/noise_reading.dart';
import '../../models/node_device.dart';
import '../../widgets/acoustic_metric_card.dart';
import '../../widgets/sparkline_widget.dart';
import '../../theme/app_theme.dart';

/// Layar Tab 1: Dashboard Monitoring Real-Time (FR-2)
class MonitorDashboardScreen extends ConsumerStatefulWidget {
  const MonitorDashboardScreen({super.key});

  @override
  ConsumerState<MonitorDashboardScreen> createState() => _MonitorDashboardScreenState();
}

class _MonitorDashboardScreenState extends ConsumerState<MonitorDashboardScreen> {
  final List<NoiseReading> _recentReadings = [];
  double? _previousLeq;

  @override
  Widget build(BuildContext context) {
    final selectedNode = ref.watch(selectedNodeIdProvider);
    final nodesAsync = ref.watch(nodesStreamProvider);
    final readingAsync = ref.watch(latestReadingStreamProvider);

    // Dapatkan data node
    final nodes = nodesAsync.value ?? [];
    final NodeDevice? currentNode = nodes.any((n) => n.deviceId == selectedNode)
        ? nodes.firstWhere((n) => n.deviceId == selectedNode)
        : (nodes.isNotEmpty ? nodes.first : null);

    readingAsync.whenData((reading) {
      if (_recentReadings.isEmpty || _recentReadings.last.ts != reading.ts) {
        if (_recentReadings.isNotEmpty) {
          _previousLeq = _recentReadings.last.leqDba;
        }
        _recentReadings.add(reading);
        if (_recentReadings.length > 50) {
          _recentReadings.removeAt(0);
        }
        // Rekam juga ke buffer sesi aktif
        ref.read(sessionReadingsBufferProvider.notifier).addReading(reading);
      }
    });

    final currentReading = readingAsync.value;
    final isOnline = currentNode?.isOnline ?? true;

    // Hitung Lmax sesi/hari ini
    final double lmaxToday = _recentReadings.isNotEmpty
        ? _recentReadings.map((r) => r.leqDba).reduce((a, b) => a > b ? a : b)
        : 0.0;
    final int anomalyCount = _recentReadings.where((r) => r.isAnomaly).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring Real-Time', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // Selector Node Perangkat
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedNode,
                icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryBlue),
                items: nodes.map((n) {
                  return DropdownMenuItem<String>(
                    value: n.deviceId,
                    child: Text(
                      n.deviceId,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(selectedNodeIdProvider.notifier).setNode(val);
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(latestReadingStreamProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kartu Leq Utama
              AcousticMetricCard(
                reading: currentReading,
                isOnline: isOnline,
                previousLeq: _previousLeq,
              ),
              const SizedBox(height: 16),

              // Kartu Ringkasan Metrik Cepat
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Lmax Periode', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                            const SizedBox(height: 4),
                            Text(
                              lmaxToday > 0 ? '${lmaxToday.toStringAsFixed(1)} dBA' : '--',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.redHigh,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Anomali TinyML', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                            const SizedBox(height: 4),
                            Text(
                              '$anomalyCount Terdeteksi',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: anomalyCount > 0 ? AppTheme.purpleAnomaly : AppTheme.greenNormal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Sparkline Deret Waktu
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tren Cepat (Sparkline)',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${_recentReadings.length} Titik Data',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SparklineWidget(readings: _recentReadings, height: 80),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Informasi Lokasi Node
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.greenBg,
                    child: Icon(Icons.location_on, color: AppTheme.greenNormal),
                  ),
                  title: Text(
                    currentNode?.locationName ?? 'Lokasi Belum Ditentukan',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    currentNode?.notes ?? 'ESP32 Node Standby',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
