import 'package:flutter/material.dart';

/// Tema aplikasi GeoLeq yang dioptimalkan untuk visibilitas lapangan outdoor
/// Memenuhi standar kontras visual minimal 4.5:1 dan area sentuh min 48x48 dp.
class AppTheme {
  // Palet Warna Kategori Kebisingan & Status
  static const Color greenNormal = Color(0xFF1E8E3E);   // Hijau kontras tinggi (< 55 dBA)
  static const Color yellowMedium = Color(0xFFB06000);  // Kuning/Amber kontras tinggi (55-70 dBA)
  static const Color redHigh = Color(0xFFD93025);       // Merah kontras tinggi (> 70 dBA)
  static const Color purpleAnomaly = Color(0xFF7B1FA2); // Ungu untuk Point Anomaly
  static const Color orangeAnomaly = Color(0xFFE65100); // Oranye untuk Collective Anomaly
  static const Color grayOffline = Color(0xFF5F6368);   // Abu-abu untuk Offline / No Data

  // Warna Background Kategori (Pastel lembut untuk grafik dan kartu)
  static const Color greenBg = Color(0xFFE6F4EA);
  static const Color yellowBg = Color(0xFFFEF7E0);
  static const Color redBg = Color(0xFFFCE8E6);
  static const Color purpleBg = Color(0xFFF3E5F5);

  // Palet Utama Aplikasi
  static const Color primaryBlue = Color(0xFF1A73E8);
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color surfaceLight = Color(0xFFF8F9FA);
  static const Color cardLight = Colors.white;
  static const Color textDark = Color(0xFF202124);
  static const Color textMuted = Color(0xFF5F6368);

  // Helper mendapatkan warna berdasarkan kategori
  static Color colorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'green':
        return greenNormal;
      case 'yellow':
        return yellowMedium;
      case 'red':
        return redHigh;
      default:
        return grayOffline;
    }
  }

  // Helper mendapatkan warna latar belakang lembut
  static Color bgColorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'green':
        return greenBg;
      case 'yellow':
        return yellowBg;
      case 'red':
        return redBg;
      default:
        return const Color(0xFFF1F3F4);
    }
  }

  // Helper label teks bahasa Indonesia
  static String labelForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'green':
        return 'Normal';
      case 'yellow':
        return 'Sedang';
      case 'red':
        return 'Tinggi';
      default:
        return 'Tidak Diketahui';
    }
  }

  // Helper icon untuk tri-faktor status visual
  static IconData iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'green':
        return Icons.check_circle_outline;
      case 'yellow':
        return Icons.warning_amber_rounded;
      case 'red':
        return Icons.error_outline;
      default:
        return Icons.help_outline;
    }
  }

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
        primary: primaryBlue,
        surface: surfaceLight,
      ),
      scaffoldBackgroundColor: surfaceLight,
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 1.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textDark,
        elevation: 0.5,
        centerTitle: false,
      ),
      // Memastikan touch target minimal 48x48 dp
      materialTapTargetSize: MaterialTapTargetSize.padded,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      // Tipografi tabular figures untuk desibel dan angka terukur
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 52,
          fontWeight: FontWeight.bold,
          fontFeatures: [FontFeature.tabularFigures()],
          color: textDark,
        ),
        displayMedium: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          fontFeatures: [FontFeature.tabularFigures()],
          color: textDark,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textDark,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textDark,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textMuted,
        ),
      ),
    );
  }
}
