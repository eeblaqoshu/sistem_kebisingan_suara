/// Model titik lokasi spasial OpenStreetMap (koleksi locationPoints/{pointId})
class LocationPoint {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String category; // 'kampus', 'jalan', 'pemukiman', 'industri', dll
  final String notes;
  final String address;
  final String? createdAt;
  final String? createdBy;

  LocationPoint({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.category = 'umum',
    this.notes = '',
    this.address = '',
    this.createdAt,
    this.createdBy,
  });

  factory LocationPoint.fromFirestore(Map<String, dynamic> map, String id) {
    return LocationPoint(
      id: id,
      name: map['name'] ?? '',
      latitude: (map['latitude'] is num) ? (map['latitude'] as num).toDouble() : 0.0,
      longitude: (map['longitude'] is num) ? (map['longitude'] as num).toDouble() : 0.0,
      category: map['category'] ?? 'umum',
      notes: map['notes'] ?? '',
      address: map['address'] ?? '',
      createdAt: map['createdAt'],
      createdBy: map['createdBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'category': category,
      'notes': notes,
      'address': address,
      'createdAt': createdAt,
      'createdBy': createdBy,
    };
  }
}
