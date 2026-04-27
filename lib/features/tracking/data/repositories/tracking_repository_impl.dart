import '../../../../core/error/failures.dart';
import '../../domain/entities/tracking.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../datasources/tracking_local_datasource.dart';
import '../models/tracking_model.dart';

class TrackingRepositoryImpl implements TrackingRepository {
  final TrackingLocalDataSource localDataSource;

  TrackingRepositoryImpl({required this.localDataSource});

  @override
  Future<List<Tracking>> getAllTracking() async {
    try {
      final models = await localDataSource.getAll();
      // Return as List<Tracking> (domain entities)
      return models;
    } on StorageFailure {
      rethrow;
    } catch (e) {
      throw StorageFailure('Repository error retrieving trackings: $e');
    }
  }

  @override
  Future<void> saveTracking(Tracking tracking) async {
    try {
      // Convert domain entity to data model
      final model = TrackingModel.fromEntity(tracking);
      // Save using data source
      await localDataSource.save(model);
    } on StorageFailure {
      rethrow;
    } catch (e) {
      throw StorageFailure('Repository error saving tracking: $e');
    }
  }

  @override
  Future<Tracking?> getTrackingById(String id) async {
    try {
      return await localDataSource.getById(id);
    } on StorageFailure {
      rethrow;
    } catch (e) {
      throw StorageFailure('Repository error retrieving tracking by ID: $e');
    }
  }

  @override
  Future<void> deleteTracking(String id) async {
    try {
      await localDataSource.delete(id);
    } on StorageFailure {
      rethrow;
    } catch (e) {
      throw StorageFailure('Repository error deleting tracking: $e');
    }
  }
}
