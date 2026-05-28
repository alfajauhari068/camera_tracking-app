import 'report_info.dart';

/// Pure domain entity representing a tracking log entry.
class TrackingLog {
  final String id;
  final String imagePath;
  final double latitude;
  final double longitude;
  final String address;
  final double accuracy;
  final String timestamp;
  final String type; // 'photo' or 'reporting'
  final ReportInfo? reportInfo;

  const TrackingLog({
    required this.id,
    required this.imagePath,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.accuracy,
    required this.timestamp,
    required this.type,
    this.reportInfo,
  });
}
