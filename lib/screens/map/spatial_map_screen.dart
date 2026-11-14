import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../config/app_constants.dart';
import '../../providers/app_providers.dart';
import '../../models/location_point.dart';
import '../../services/nominatim_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/category_badge.dart';
import '../../widgets/osm_attribution.dart';

/// Layar Tab 2: Peta Spasial OpenStreetMap (FR-3)
class SpatialMapScreen extends ConsumerStatefulWidget {
  const SpatialMapScreen({super.key});

  @override
  ConsumerState<SpatialMapScreen> createState() => _SpatialMapScreenState();
}

class _SpatialMapScreenState extends ConsumerState<SpatialMapScreen> {
  final MapController _mapController = MapController();
  final List<LatLng> _polylineTrack = [];

  @override
  Widget build(BuildContext context) {
    final readingAsync = ref.watch(latestReadingStreamProvider);
    final locationsAsync = ref.watch(locationsStreamProvider);
    final locations = locationsAsync.value ?? [];

    readingAsync.whenData((reading) {
      if (reading.gpsFix && reading.latitude != 0 && reading.longitude != 0) {
        final point = LatLng(reading.latitude, reading.longitude);
        if (_polylineTrack.isEmpty || _polylineTrack.last != point) {
          _polylineTrack.add(point);
          if (_polylineTrack.length > 200) {
            _polylineTrack.removeAt(0);
          }
        }
      }
    });

    final currentReading = readingAsync.value;
    final currentPos = (currentReading != null && currentReading.gpsFix && currentReading.latitude != 0)
        ? LatLng(currentReading.latitude, currentReading.longitude)
        : const LatLng(AppConstants.defaultLatitude, AppConstants.defaultLongitude);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Spasial Kebisingan', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Pusatkan ke Node',
            onPressed: () {
              _mapController.move(currentPos, 16.5);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: currentPos,
              initialZoom: 16.5,
              onLongPress: (tapPosition, point) {
                _showAddLocationDialog(context, point);
              },
            ),
            children: [
              // OpenStreetMap Tile Layer dengan User-Agent Kepatuhan
              TileLayer(
                urlTemplate: AppConstants.osmTileUrl,
                userAgentPackageName: AppConstants.osmUserAgent,
              ),

              // Polyline Lintasan Mobile Survey
              if (_polylineTrack.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _polylineTrack,
                      strokeWidth: 4.0,
                      color: AppTheme.primaryBlue.withValues(alpha: 0.7),
                    ),
                  ],
                ),

              // Marker Lokasi Tersimpan (LocationPoint)
              MarkerLayer(
                markers: [
                  ...locations.map((loc) {
                    return Marker(
                      point: LatLng(loc.latitude, loc.longitude),
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () => _showLocationDetail(context, loc),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
                            ],
                          ),
                          child: const Icon(Icons.place, color: AppTheme.darkBlue, size: 30),
                        ),
                      ),
                    );
                  }),

                  // Marker Node Aktif Real-Time
                  if (currentReading != null && currentReading.gpsFix && currentReading.latitude != 0)
                    Marker(
                      point: currentPos,
                      width: 56,
                      height: 56,
                      child: GestureDetector(
                        onTap: () => _showNodeReadingDetail(context, currentReading),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.colorForCategory(currentReading.category),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6),
                            ],
                          ),
                          child: Center(
                            child: currentReading.isAnomaly
                                ? const Icon(Icons.bolt, color: Colors.white, size: 28)
                                : Text(
                                    currentReading.leqDba.toStringAsFixed(0),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Legenda Kategori
          Positioned(
            top: 12,
            left: 12,
            child: Card(
              color: Colors.white.withValues(alpha: 0.92),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(radius: 5, backgroundColor: AppTheme.greenNormal),
                    SizedBox(width: 4),
                    Text('<55', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    CircleAvatar(radius: 5, backgroundColor: AppTheme.yellowMedium),
                    SizedBox(width: 4),
                    Text('55-70', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    CircleAvatar(radius: 5, backgroundColor: AppTheme.redHigh),
                    SizedBox(width: 4),
                    Text('>70', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),

          // Atribusi Wajib OpenStreetMap
          const Positioned(
            bottom: 8,
            right: 8,
            child: OsmAttribution(),
          ),
        ],
      ),
    );
  }

  void _showNodeReadingDetail(BuildContext context, dynamic reading) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Node: ${reading.deviceId}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CategoryBadge(category: reading.category),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Tingkat Kebisingan: ${Formatters.formatDb(reading.leqDba)} dBA',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text('Waktu: ${Formatters.formatDateTime(reading.ts)}', style: const TextStyle(color: AppTheme.textMuted)),
              Text('Koordinat: ${reading.latitude.toStringAsFixed(5)}, ${reading.longitude.toStringAsFixed(5)}'),
              if (reading.isAnomaly) ...[
                const SizedBox(height: 8),
                Text(
                  'STATUS: Terdeteksi Anomali (${reading.anomalyType})',
                  style: const TextStyle(color: AppTheme.purpleAnomaly, fontWeight: FontWeight.bold),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showLocationDetail(BuildContext context, LocationPoint loc) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(loc.address, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
              const SizedBox(height: 8),
              Text('Kategori: ${loc.category.toUpperCase()}'),
              if (loc.notes.isNotEmpty) Text('Catatan: ${loc.notes}'),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showAddLocationDialog(BuildContext context, LatLng point) async {
    final nameCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final addressCtrl = TextEditingController(text: 'Mencari alamat via Nominatim...');

    // Ambil alamat dari Nominatim Service
    NominatimService().reverseGeocode(point.latitude, point.longitude).then((addr) {
      addressCtrl.text = addr;
    });

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Tambah Titik Lokasi OSM'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Titik (e.g. Gerbang Polines)'),
                ),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Catatan Pengukuran'),
                ),
                TextField(
                  controller: addressCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Alamat (Nominatim)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isNotEmpty) {
                  final newLoc = LocationPoint(
                    id: 'loc_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameCtrl.text.trim(),
                    latitude: point.latitude,
                    longitude: point.longitude,
                    notes: notesCtrl.text.trim(),
                    address: addressCtrl.text.trim(),
                  );
                  await ref.read(locationRepoProvider).addLocation(newLoc);
                  ref.invalidate(locationsStreamProvider);
                  if (dialogCtx.mounted) {
                    Navigator.pop(dialogCtx);
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
}
