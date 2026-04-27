import '../models/tracking_model.dart';

abstract class TrackingLocalDataSource {
  /// Save a tracking model to local storage
  Future<void> save(TrackingModel model);

  /// Get all tracking models from local storage
  Future<List<TrackingModel>> getAll();

  /// Get tracking model by ID
  Future<TrackingModel?> getById(String id);

  /// Delete tracking model by ID
  Future<void> delete(String id);
}
