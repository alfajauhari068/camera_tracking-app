abstract class GeocodingService {
  /// Get address from latitude and longitude
  Future<String> getAddress(double latitude, double longitude);
}
