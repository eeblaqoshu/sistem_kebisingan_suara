/// Konstanta global aplikasi GeoLeq
class AppConstants {
  // Nama aplikasi
  static const String appName = 'GeoLeq';
  static const String appSubtitle = 'Sistem Pemetaan Polusi Suara';
  static const String institution = 'Politeknik Negeri Semarang (Polines)';
  static const String projectGroup = 'Kelompok 2 - Tubes IoT IK 2026B';

  // Default Threshold Kebisingan (dBA)
  static const double defaultThresholdYellow = 55.0;
  static const double defaultThresholdRed = 70.0;

  // Histeresis auto-event debouncing
  static const double categoryHysteresisDba = 1.5;
  static const int categoryDebounceSec = 10;

  // Offline detection interval (default 30 detik / 2x update interval)
  static const int defaultOfflineIntervalSec = 30;

  // Baseline & Final minutes
  static const int defaultBaselineMinutes = 5;
  static const int defaultFinalMinutes = 5;

  // OpenStreetMap Compliance
  static const String osmUserAgent = 'geoleq.polines.tubes_iot/1.0.0';
  static const String osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String osmAttribution = '© OpenStreetMap contributors';
  static const String nominatimEndpoint = 'https://nominatim.openstreetmap.org/reverse';

  // Default coordinate (Kampus Polines Tembalang)
  static const double defaultLatitude = -7.052012;
  static const double defaultLongitude = 110.435412;
}
