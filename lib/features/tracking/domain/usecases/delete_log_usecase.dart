import '../repositories/tracking_repo.dart';

/// Use case: delete tracking log by id.
class DeleteLogUseCase {
  final TrackingRepository repository;

  DeleteLogUseCase(this.repository);

  Future<void> execute(String id) async {
    await repository.deleteLog(id);
  }
}
