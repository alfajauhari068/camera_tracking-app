import '../repositories/tracking_repo.dart';
import '../entities/tracking_log.dart';

/// Use case: retrieve all tracking logs.
class GetLogsUseCase {
  final TrackingRepository repository;

  GetLogsUseCase(this.repository);

  Future<List<TrackingLog>> execute() async {
    return repository.getAllLogs();
  }
}
