import '../entities/tracking.dart';

abstract class TrackingRepository {
  /// Save a tracking data
  Future<void> saveTracking(Tracking tracking);

  /// Get all tracking data
  Future<List<Tracking>> getAllTracking();

  /// Get tracking by ID
  Future<Tracking?> getTrackingById(String id);

  /// Delete tracking by ID
  Future<void> deleteTracking(String id);
}
