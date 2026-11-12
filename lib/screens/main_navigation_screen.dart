import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../models/measurement_session.dart';
import '../widgets/active_session_banner.dart';
import 'monitor/monitor_dashboard_screen.dart';
import 'map/spatial_map_screen.dart';
import 'chart/noise_trend_screen.dart';
import 'nodes/nodes_screen.dart';
import 'session/start_session_screen.dart';
import 'report/report_detail_screen.dart';
import '../theme/app_theme.dart';

/// Layar Navigasi Utama dengan Persistent ActiveSessionBanner
class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    MonitorDashboardScreen(),
    SpatialMapScreen(),
    NoiseTrendScreen(),
    NodesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final activeSession = ref.watch(activeSessionProvider);

    return Scaffold(
      body: Column(
        children: [
          // Banner sesi aktif persisten di paling atas
          if (activeSession != null)
            ActiveSessionBanner(
              session: activeSession,
              onEndSessionPressed: () => _confirmEndSession(context, activeSession),
              onAddEventPressed: () => _showAddEventDialog(context),
            ),
          Expanded(child: _screens[_currentIndex]),
        ],
      ),
      floatingActionButton: activeSession == null
          ? FloatingActionButton.extended(
              onPressed: () => _showStartSessionDialog(context),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Mulai Sesi', style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.speed_outlined),
            selectedIcon: Icon(Icons.speed),
            label: 'Monitor',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Peta OSM',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart),
            label: 'Grafik',
          ),
          NavigationDestination(
            icon: Icon(Icons.devices_outlined),
            selectedIcon: Icon(Icons.devices),
            label: 'Perangkat',
          ),
        ],
      ),
    );
  }

  void _showStartSessionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const StartSessionDialog(),
    );
  }

  void _showAddEventDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Tambah Catatan Kejadian'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Kejadian (e.g. Bus Trans Semarang melintas)',
                ),
              ),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Keterangan Tambahan',
                ),
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
                if (titleCtrl.text.trim().isNotEmpty) {
                  await ref.read(sessionRepoProvider).addManualEvent(
                        title: titleCtrl.text.trim(),
                        notes: noteCtrl.text.trim(),
                      );
                  ref.invalidate(activeEventsProvider);
                  if (dialogCtx.mounted) {
                    Navigator.pop(dialogCtx);
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Catatan kejadian berhasil direkam')),
                    );
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _confirmEndSession(BuildContext context, MeasurementSession session) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Akhiri Sesi Pengukuran?'),
          content: const Text(
            'Sesi akan diakhiri dan seluruh 9 bagian laporan logaritmik beserta kesimpulan otomatis akan segera dihitung.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Lanjutkan Sesi'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.redHigh, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                final readings = ref.read(sessionReadingsBufferProvider);
                final events = ref.read(sessionRepoProvider).activeEvents;

                final report = await ref.read(sessionRepoProvider).endSession(
                      sessionReadings: readings,
                      locationName: 'Kampus Polines Tembalang',
                    );

                await ref.read(activeSessionProvider.notifier).endSession();

                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReportDetailScreen(
                      session: session,
                      report: report,
                      events: events,
                      readings: readings,
                    ),
                  ),
                );
              },
              child: const Text('Akhiri & Bentuk Laporan'),
            ),
          ],
        );
      },
    );
  }
}
