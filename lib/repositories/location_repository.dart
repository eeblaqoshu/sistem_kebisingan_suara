import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/location_point.dart';

/// Repository untuk manajemen titik lokasi OSM di Firestore (locationPoints/{pointId})
class LocationRepository {
  final FirebaseFirestore? firestore;

  final List<LocationPoint> _mockPoints = [
    LocationPoint(
      id: 'loc_polines_gate',
      name: 'Gerbang Utama Polines',
      latitude: -7.052012,
      longitude: 110.435412,
      category: 'kampus',
      notes: 'Titik pengukuran 3 meter dari bahu jalan',
      address: 'Jl. Prof. Soedarto, Tembalang, Kota Semarang',
    ),
    LocationPoint(
      id: 'loc_polines_lab',
      name: 'Gedung AB Elektro Polines',
      latitude: -7.053100,
      longitude: 110.436200,
      category: 'laboratorium',
      notes: 'Dekat laboratorium IoT & Jaringan',
      address: 'Kawasan Dalam Kampus Polines Tembalang',
    ),
  ];

  LocationRepository({this.firestore});

  Stream<List<LocationPoint>> streamLocations() {
    if (Firebase.apps.isNotEmpty && firestore != null) {
      try {
        return firestore!
            .collection('locationPoints')
            .snapshots()
            .map((snapshot) => snapshot.docs.map((doc) => LocationPoint.fromFirestore(doc.data(), doc.id)).toList());
      } catch (_) {}
    }
    return Stream.value(_mockPoints);
  }

  Future<void> addLocation(LocationPoint point) async {
    if (Firebase.apps.isNotEmpty && firestore != null) {
      try {
        await firestore!.collection('locationPoints').doc(point.id).set(point.toFirestore());
        return;
      } catch (_) {}
    }
    _mockPoints.add(point);
  }
}
