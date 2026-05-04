import '../../../../core/error/failures.dart';
import '../entities/tracking.dart';
import '../repositories/tracking_repository.dart';
import '../services/export_service.dart';

class ExportTrackings {
  final TrackingRepository _repository;
  final ExportService _exportService;

  ExportTrackings({
    required TrackingRepository repository,
    required ExportService exportService,
  })  : _repository = repository,
        _exportService = exportService;

  /// Export trackings filtered by optional date range or specific tracking ID.
  /// Returns the generated file path.
  Future<String> execute({
    DateTime? startDate,
    DateTime? endDate,
    String format = 'CSV',
    String? trackingId,
  }) async {
    final List<Tracking> allTrackings = await _repository.getAllTracking();

    final filtered = allTrackings.where((tracking) {
      if (trackingId != null) {
        return tracking.id == trackingId;
      }

      if (startDate != null && tracking.timestamp.isBefore(startDate)) {
        return false;
      }

      if (endDate != null) {
        final endOfDay = endDate.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
        if (tracking.timestamp.isAfter(endOfDay)) {
          return false;
        }
      }

      return true;
    }).toList();

    if (filtered.isEmpty) {
      throw GenericFailure('No tracking data found for the selected export filter.');
    }

    return await _exportService.exportTrackings(filtered, format);
  }
}
