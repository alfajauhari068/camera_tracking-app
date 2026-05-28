import '../repositories/tracking_repo.dart';
import '../entities/tracking_log.dart';

/// Use case: save a tracking log via repository.
class SaveLogUseCase {
  final TrackingRepository repository;

  SaveLogUseCase(this.repository);

  Future<void> execute(TrackingLog log) async {
    await repository.saveLog(log);
  }
}
