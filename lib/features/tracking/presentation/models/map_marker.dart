import 'dart:math' as math;

import '../../domain/entities/tracking.dart';

/// Simple marker model untuk menyimpan informasi marker di map
/// (Nantinya bisa extend dengan LatLng dari google_maps atau flutter_map)
class MapMarker {
  final String id;
  final double latitude;
  final double longitude;
  final String address;
  final String imagePath;
  final DateTime timestamp;
  final Tracking trackingSource;

  const MapMarker({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.imagePath,
    required this.timestamp,
    required this.trackingSource,
  });

  /// Factory constructor untuk membuat MapMarker dari Tracking entity
  factory MapMarker.fromTracking(Tracking tracking) {
    return MapMarker(
      id: tracking.id,
      latitude: tracking.latitude,
      longitude: tracking.longitude,
      address: tracking.address,
      imagePath: tracking.imagePath,
      timestamp: tracking.timestamp,
      trackingSource: tracking,
    );
  }

  /// Hitung jarak dari coordinate lain menggunakan Haversine formula
  /// Berguna untuk mencari marker terdekat
  /// Return: jarak dalam kilometer
  double distanceFrom(double lat, double lon) {
    const R = 6371; // Radius bumi dalam kilometer
    final dLat = math.pi * (lat - latitude) / 180;
    final dLon = math.pi * (lon - longitude) / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(math.pi * latitude / 180) *
            math.cos(math.pi * lat / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }
}
