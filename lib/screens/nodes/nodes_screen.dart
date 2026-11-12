import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../models/node_device.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

/// Layar Tab 4: Manajemen Node Perangkat & Pengaturan Sistem (FR-5)
class NodesScreen extends ConsumerWidget {
  const NodesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodesAsync = ref.watch(nodesStreamProvider);
    final settings = ref.watch(appSettingsProvider);
    final selectedNode = ref.watch(selectedNodeIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Node & Pengaturan', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: nodesAsync.when(
        data: (nodes) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Daftar Node ESP32 Terdaftar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              ...nodes.map((node) {
                final isSelected = node.deviceId == selectedNode;
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 6,
                              backgroundColor: node.isOnline ? AppTheme.greenNormal : AppTheme.grayOffline,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                node.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                            if (isSelected)
                              const Chip(
                                label: Text('Aktif Dipantau', style: TextStyle(fontSize: 10, color: Colors.white)),
                                backgroundColor: AppTheme.primaryBlue,
                                padding: EdgeInsets.zero,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('ID Perangkat: ${node.deviceId}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        Text('Lokasi: ${node.locationName}', style: const TextStyle(fontSize: 12)),
                        Text('Kalibrasi: Gain ${node.calibGain}x, Offset ${node.calibOffset > 0 ? "+" : ""}${node.calibOffset} dBA',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        if (node.rssi != null)
                          Text('Sinyal Wi-Fi: ${node.rssi} dBm | Uptime: ${Formatters.formatDurationSec(node.uptimeSec ?? 0)}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                ref.read(selectedNodeIdProvider.notifier).setNode(node.deviceId);
                              },
                              child: const Text('Pilih Node', style: TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _showEditCalibrationDialog(context, ref, node),
                              child: const Text('Kalibrasi', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 24),
              const Text(
                'Pengaturan Ambang Batas Kebisingan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Ambang Kuning (Sedang)', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text('${settings.thresholdYellow.toStringAsFixed(1)} dBA',
                              style: const TextStyle(color: AppTheme.yellowMedium, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Slider(
                        value: settings.thresholdYellow,
                        min: 40.0,
                        max: 65.0,
                        divisions: 25,
                        activeColor: AppTheme.yellowMedium,
                        onChanged: (val) {
                          ref.read(appSettingsProvider.notifier).updateSettings(settings.copyWith(thresholdYellow: val));
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Ambang Merah (Tinggi)', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text('${settings.thresholdRed.toStringAsFixed(1)} dBA',
                              style: const TextStyle(color: AppTheme.redHigh, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Slider(
                        value: settings.thresholdRed,
                        min: 65.0,
                        max: 90.0,
                        divisions: 25,
                        activeColor: AppTheme.redHigh,
                        onChanged: (val) {
                          ref.read(appSettingsProvider.notifier).updateSettings(settings.copyWith(thresholdRed: val));
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Gagal memuat node: $err')),
      ),
    );
  }

  void _showEditCalibrationDialog(BuildContext context, WidgetRef ref, NodeDevice node) {
    final gainCtrl = TextEditingController(text: node.calibGain.toString());
    final offsetCtrl = TextEditingController(text: node.calibOffset.toString());

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text('Kalibrasi ${node.deviceId}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: gainCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Calib Gain (Faktor Pengali)'),
              ),
              TextField(
                controller: offsetCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Calib Offset (dBA)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final double? gain = double.tryParse(gainCtrl.text);
                final double? offset = double.tryParse(offsetCtrl.text);
                if (gain != null && offset != null) {
                  final updated = node.copyWith(calibGain: gain, calibOffset: offset);
                  await ref.read(nodeRepoProvider).saveNode(updated);
                  ref.invalidate(nodesStreamProvider);
                  if (dialogCtx.mounted) {
                    Navigator.pop(dialogCtx);
                  }
                }
              },
              child: const Text('Simpan Kalibrasi'),
            ),
          ],
        );
      },
    );
  }
}
