class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy;

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
  });
}

abstract class LocationService {
  /// Get current location (latitude, longitude, accuracy)
  Future<LocationData> getLocation();
}
