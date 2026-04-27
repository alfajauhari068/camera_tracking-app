import '../../../../core/error/failures.dart';
import '../entities/tracking.dart';
import '../repositories/tracking_repository.dart';

class FakeTrackingRepository implements TrackingRepository {
  final List<Tracking> _trackings = [];
  final bool shouldFailSave;
  final bool shouldFailGet;

  FakeTrackingRepository({
    this.shouldFailSave = false,
    this.shouldFailGet = false,
  });

  @override
  Future<List<Tracking>> getAllTracking() async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (shouldFailGet) {
      throw StorageFailure('Failed to retrieve trackings from storage');
    }

    return _trackings;
  }

  @override
  Future<void> saveTracking(Tracking tracking) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (shouldFailSave) {
      throw StorageFailure('Failed to save tracking to storage');
    }

    _trackings.add(tracking);
  }

  @override
  Future<Tracking?> getTrackingById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      return _trackings.firstWhere((tracking) => tracking.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> deleteTracking(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));

    _trackings.removeWhere((tracking) => tracking.id == id);
  }
}
