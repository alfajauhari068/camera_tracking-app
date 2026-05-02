import '../entities/tracking.dart';
import '../repositories/tracking_repository.dart';

/// Use case untuk mengambil satu tracking berdasarkan ID
/// 
/// Digunakan ketika Detail page menerima hanya trackingId
/// dan perlu load full tracking object dari repository
class GetTrackingById {
  final TrackingRepository _repository;

  GetTrackingById({required TrackingRepository repository})
    : _repository = repository;

  /// Execute: ambil tracking dengan ID tertentu
  /// Returns: Tracking object atau null jika tidak ditemukan
  Future<Tracking?> execute(String id) async {
    return await _repository.getTrackingById(id);
  }
}
