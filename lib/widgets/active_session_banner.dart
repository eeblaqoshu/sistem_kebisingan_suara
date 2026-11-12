import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/measurement_session.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Banner sesi pengukuran aktif persisten di layar
class ActiveSessionBanner extends ConsumerStatefulWidget {
  final MeasurementSession session;
  final VoidCallback onEndSessionPressed;
  final VoidCallback onAddEventPressed;

  const ActiveSessionBanner({
    super.key,
    required this.session,
    required this.onEndSessionPressed,
    required this.onAddEventPressed,
  });

  @override
  ConsumerState<ActiveSessionBanner> createState() => _ActiveSessionBannerState();
}

class _ActiveSessionBannerState extends ConsumerState<ActiveSessionBanner> {
  Timer? _timer;
  int _elapsedSec = 0;

  @override
  void initState() {
    super.initState();
    _updateElapsed();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateElapsed());
  }

  void _updateElapsed() {
    final nowTs = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    setState(() {
      _elapsedSec = (nowTs - widget.session.startTs).clamp(0, 999999);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.darkBlue,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.fiber_manual_record, color: Colors.white, size: 12),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.session.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Durasi: ${Formatters.formatDurationSec(_elapsedSec)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Tombol Cepat Tambah Catatan
            ElevatedButton.icon(
              onPressed: widget.onAddEventPressed,
              icon: const Icon(Icons.note_add, size: 16),
              label: const Text('Catat', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.darkBlue,
                minimumSize: const Size(40, 36),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
            ),
            const SizedBox(width: 6),
            // Tombol Akhiri Sesi
            ElevatedButton(
              onPressed: widget.onEndSessionPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.redHigh,
                foregroundColor: Colors.white,
                minimumSize: const Size(40, 36),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              child: const Text('Akhiri', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
