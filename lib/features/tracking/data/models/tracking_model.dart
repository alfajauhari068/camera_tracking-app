import '../../domain/entities/tracking.dart';

class TrackingModel extends Tracking {
  const TrackingModel({
    required super.id,
    required super.imagePath,
    required super.latitude,
    required super.longitude,
    required super.address,
    required super.accuracy,
    required super.timestamp,
    required super.type,
    super.reportInfo,
  });

  /// Convert model to JSON (only in data layer)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'reportInfo': reportInfo?.toJson(),
    };
  }

  /// Create model from JSON (only in data layer)
  factory TrackingModel.fromJson(Map<String, dynamic> json) {
    final typeString = json['type'] as String?;
    final rawReportInfo = json['reportInfo'];

    return TrackingModel(
      id: json['id'] as String,
      imagePath: json['imagePath'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String,
      accuracy: (json['accuracy'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: TrackingType.values.firstWhere(
        (e) => e.name == typeString,
        orElse: () => TrackingType.photo,
      ),
      reportInfo: rawReportInfo is Map<String, dynamic>
          ? ReportInfo.fromJson(rawReportInfo)
          : null,
    );
  }

  /// Convert entity to model
  factory TrackingModel.fromEntity(Tracking tracking) {
    return TrackingModel(
      id: tracking.id,
      imagePath: tracking.imagePath,
      latitude: tracking.latitude,
      longitude: tracking.longitude,
      address: tracking.address,
      accuracy: tracking.accuracy,
      timestamp: tracking.timestamp,
      type: tracking.type,
      reportInfo: tracking.reportInfo,
    );
  }
}
