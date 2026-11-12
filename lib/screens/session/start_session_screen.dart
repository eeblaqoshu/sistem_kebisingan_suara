import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';

/// Dialog/Layar Mulai Sesi Baru (FR-6)
class StartSessionDialog extends ConsumerStatefulWidget {
  const StartSessionDialog({super.key});

  @override
  ConsumerState<StartSessionDialog> createState() => _StartSessionDialogState();
}

class _StartSessionDialogState extends ConsumerState<StartSessionDialog> {
  final _nameCtrl = TextEditingController(text: 'Sesi Pengukuran Kebisingan');
  final _purposeCtrl = TextEditingController(text: 'Evaluasi Leq lingkungan dan deteksi anomali akustik');
  String? _selectedNodeId;
  String? _selectedLocationId;

  @override
  Widget build(BuildContext context) {
    final nodes = ref.watch(nodesStreamProvider).value ?? [];
    final locations = ref.watch(locationsStreamProvider).value ?? [];
    final settings = ref.watch(appSettingsProvider);

    if (_selectedNodeId == null && nodes.isNotEmpty) {
      _selectedNodeId = nodes.first.deviceId;
    }
    if (_selectedLocationId == null && locations.isNotEmpty) {
      _selectedLocationId = locations.first.id;
    }

    return AlertDialog(
      title: const Text('Mulai Sesi Pengukuran Baru', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Sesi Pengukuran'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _purposeCtrl,
              decoration: const InputDecoration(labelText: 'Tujuan Pengujian'),
            ),
            const SizedBox(height: 12),
            const Text('Pilih Node ESP32:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            DropdownButton<String>(
              isExpanded: true,
              value: _selectedNodeId,
              items: nodes.map((n) {
                return DropdownMenuItem(value: n.deviceId, child: Text('${n.name} (${n.deviceId})'));
              }).toList(),
              onChanged: (val) => setState(() => _selectedNodeId = val),
            ),
            const SizedBox(height: 8),
            const Text('Pilih Titik Lokasi OSM:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            DropdownButton<String>(
              isExpanded: true,
              value: _selectedLocationId,
              items: locations.map((loc) {
                return DropdownMenuItem(value: loc.id, child: Text(loc.name));
              }).toList(),
              onChanged: (val) => setState(() => _selectedLocationId = val),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.yellowBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Perhatian: Parameter kalibrasi dan ambang batas saat ini akan disimpan sebagai snapshot imutabel untuk laporan sesi.',
                style: TextStyle(fontSize: 11, color: AppTheme.yellowMedium),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_nameCtrl.text.trim().isNotEmpty && _selectedNodeId != null) {
              final activeNode = nodes.firstWhere((n) => n.deviceId == _selectedNodeId);

              // Ambil snapshot kalibrasi & ambang
              final calibSnapshot = {
                activeNode.deviceId: {
                  'gain': activeNode.calibGain,
                  'offset': activeNode.calibOffset,
                }
              };

              final thresholdSnapshot = {
                'yellow': settings.thresholdYellow,
                'red': settings.thresholdRed,
              };

              await ref.read(activeSessionProvider.notifier).startSession(
                name: _nameCtrl.text.trim(),
                purpose: _purposeCtrl.text.trim(),
                nodeIds: [_selectedNodeId!],
                locationPointIds: _selectedLocationId != null ? [_selectedLocationId!] : [],
                calibSnapshot: calibSnapshot,
                thresholdSnapshot: thresholdSnapshot,
              );

              ref.read(sessionReadingsBufferProvider.notifier).clear();
              if (context.mounted) {
                Navigator.pop(context);
              }
            }
          },
          child: const Text('Mulai Sesi'),
        ),
      ],
    );
  }
}
