import '../../domain/entities/tracking.dart';

/// Data model used by data layer. Bridges domain `Tracking` with
/// JSON serialization and SQLite mapping.
class TrackingModel extends Tracking {
  const TrackingModel({
    required super.id,
    required super.imagePath,
    required super.latitude,
    required super.longitude,
    required super.address,
    required super.accuracy,
    required super.timestamp,
    super.type = TrackingType.photo,
    super.reportInfo,
  });

  /// Convert to map suitable for SQLite insert/update
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imagePath': imagePath,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'reportCategory': reportInfo?.category,
      'reportNote': reportInfo?.note,
    };
  }

  /// Create model from SQLite map
  factory TrackingModel.fromMap(Map<String, dynamic> map) {
    final String typeStr = map['type'] as String? ?? 'photo';
    final TrackingType parsedType = TrackingType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => TrackingType.photo,
    );

    final String? cat = map['reportCategory'] as String?;
    final String? note = map['reportNote'] as String?;

    return TrackingModel(
      id: map['id'] as String,
      imagePath: map['imagePath'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      address: map['address'] as String? ?? '',
      accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      type: parsedType,
      reportInfo: (cat != null || note != null) ? ReportInfo(category: cat ?? '', note: note, severity: null) : null,
    );
  }

  /// JSON serialization used by local JSON datasource
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

  factory TrackingModel.fromJson(Map<String, dynamic> json) {
    final String? typeString = json['type'] as String?;
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

  /// Convert a domain entity to model
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
