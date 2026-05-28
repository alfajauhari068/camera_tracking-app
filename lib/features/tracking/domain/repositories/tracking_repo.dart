import '../entities/tracking_log.dart';

/// Abstract contract for tracking data persistence.
abstract class TrackingRepository {
  Future<void> saveLog(TrackingLog log);

  Future<List<TrackingLog>> getAllLogs();

  Future<void> deleteLog(String id);
}
