import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_constants.dart';

/// Layanan reverse geocoding OpenStreetMap Nominatim dengan rate limiter (maks 1 req/s)
class NominatimService {
  static final NominatimService _instance = NominatimService._internal();
  factory NominatimService() => _instance;
  NominatimService._internal();

  DateTime _lastRequestTime = DateTime.fromMillisecondsSinceEpoch(0);

  Future<String> reverseGeocode(double latitude, double longitude) async {
    // Patuhi batasan nominatim: max 1 req / detik
    final now = DateTime.now();
    final elapsed = now.difference(_lastRequestTime);
    if (elapsed.inMilliseconds < 1000) {
      await Future.delayed(Duration(milliseconds: 1000 - elapsed.inMilliseconds));
    }
    _lastRequestTime = DateTime.now();

    try {
      final uri = Uri.parse(
        '${AppConstants.nominatimEndpoint}?format=jsonv2&lat=$latitude&lon=$longitude',
      );

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': AppConstants.osmUserAgent,
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final displayName = data['display_name'];
        if (displayName != null && displayName.toString().isNotEmpty) {
          return displayName.toString();
        }
      }
    } catch (_) {
      // Fallback jika offline atau timeout
    }

    return 'Lat: ${latitude.toStringAsFixed(5)}, Lng: ${longitude.toStringAsFixed(5)}';
  }
}
