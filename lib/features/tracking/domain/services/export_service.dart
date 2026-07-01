import '../entities/tracking.dart';

/// Abstraction for exporting tracking data.
/// Implementasi konkrit berada di data layer.
abstract class ExportService {
  /// Export list of trackings into a file with the chosen format.
  /// Returns the absolute path to the generated export file.
  Future<String> exportTrackings(List<Tracking> trackings, String format);
}
