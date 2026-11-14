import 'package:flutter/material.dart';
import '../models/noise_reading.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'category_badge.dart';

/// Kartu metriks utama tingkat kebisingan Leq real-time dengan tipografi besar
class AcousticMetricCard extends StatelessWidget {
  final NoiseReading? reading;
  final bool isOnline;
  final double? previousLeq;

  const AcousticMetricCard({
    super.key,
    required this.reading,
    this.isOnline = true,
    this.previousLeq,
  });

  @override
  Widget build(BuildContext context) {
    final leq = reading?.leqDba;
    final category = reading?.category ?? 'gray';
    final color = AppTheme.colorForCategory(category);

    // Hitung arah tren
    Widget trendIcon = const SizedBox.shrink();
    if (previousLeq != null && leq != null) {
      final diff = leq - previousLeq!;
      if (diff > 0.5) {
        trendIcon = const Icon(Icons.arrow_upward_rounded, color: AppTheme.redHigh, size: 28);
      } else if (diff < -0.5) {
        trendIcon = const Icon(Icons.arrow_downward_rounded, color: AppTheme.greenNormal, size: 28);
      } else {
        trendIcon = const Icon(Icons.horizontal_rule_rounded, color: AppTheme.yellowMedium, size: 24);
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status bar atas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isOnline ? AppTheme.greenNormal : AppTheme.grayOffline,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOnline ? 'Node Online' : 'Node Offline',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isOnline ? AppTheme.greenNormal : AppTheme.grayOffline,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      reading?.gpsFix == true ? Icons.gps_fixed : Icons.gps_not_fixed,
                      size: 14,
                      color: reading?.gpsFix == true ? AppTheme.primaryBlue : AppTheme.grayOffline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      reading?.gpsFix == true ? 'GPS Fix' : 'No GPS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: reading?.gpsFix == true ? AppTheme.primaryBlue : AppTheme.grayOffline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Angka Leq Utama tipografi besar tabular (FittedBox mencegah overflow pada layar sempit)
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    Formatters.formatDb(leq),
                    style: TextStyle(
                      fontSize: 54,
                      fontWeight: FontWeight.w900,
                      color: color,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'dBA',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  trendIcon,
                  const SizedBox(width: 16),
                  CategoryBadge(category: category, fontSize: 14),
                ],
              ),
            ),

            if (reading?.isAnomaly == true) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.purpleBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.purpleAnomaly.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt, color: AppTheme.purpleAnomaly, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'ANOMALI TINYML: ${reading!.anomalyType.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.purpleAnomaly,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pembaruan: ${Formatters.formatRelativeTime(reading?.ts ?? 0)}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                Text(
                  'ID: ${reading?.deviceId ?? '-'}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
