import 'package:intl/intl.dart';

class Formatters {
  static String formatDb(double? db) {
    if (db == null) return '--';
    return db.toStringAsFixed(1);
  }

  static String formatRelativeTime(int epochSec) {
    if (epochSec <= 0) return 'Belum ada data';
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final diff = now - epochSec;

    if (diff < 5) return 'Baru saja';
    if (diff < 60) return '$diff detik lalu';
    if (diff < 3600) return '${diff ~/ 60} menit lalu';
    return '${diff ~/ 3600} jam lalu';
  }

  static String formatDateTime(int epochSec) {
    if (epochSec <= 0) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(epochSec * 1000);
    return DateFormat('dd MMM yyyy, HH:mm:ss').format(dt);
  }

  static String formatTimeOnly(int epochSec) {
    if (epochSec <= 0) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(epochSec * 1000);
    return DateFormat('HH:mm:ss').format(dt);
  }

  static String formatDurationSec(int durationSec) {
    final hours = durationSec ~/ 3600;
    final minutes = (durationSec % 3600) ~/ 60;
    final seconds = durationSec % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
