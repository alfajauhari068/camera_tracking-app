import '../entities/tracking.dart';
import '../repositories/tracking_repository.dart';

/// Use case untuk mengambil semua tracking data
/// Simple dan straightforward: hanya return list Tracking
class GetTrackings {
  final TrackingRepository _repository;

  GetTrackings({required TrackingRepository repository}) : _repository = repository;

  /// Execute: ambil semua tracking dari repository
  /// Bisa throw exception jika gagal
  Future<List<Tracking>> execute() async {
    return await _repository.getAllTracking();
  }
}
