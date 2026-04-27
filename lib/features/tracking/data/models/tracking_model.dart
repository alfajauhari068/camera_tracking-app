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
    };
  }

  /// Create model from JSON (only in data layer)
  factory TrackingModel.fromJson(Map<String, dynamic> json) {
    return TrackingModel(
      id: json['id'] as String,
      imagePath: json['imagePath'] as String,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      address: json['address'] as String,
      accuracy: json['accuracy'] as double,
      timestamp: DateTime.parse(json['timestamp'] as String),
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
    );
  }
}
