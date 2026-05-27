enum TrackingType { photo, reporting }

class ReportInfo {
  final String category;
  final String? note;
  final String? severity;

  const ReportInfo({
    required this.category,
    this.note,
    this.severity,
  });

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'note': note,
      'severity': severity,
    };
  }

  factory ReportInfo.fromJson(Map<String, dynamic> json) {
    return ReportInfo(
      category: json['category'] as String,
      note: json['note'] as String?,
      severity: json['severity'] as String?,
    );
  }
}

class Tracking {
  final String id;
  final String imagePath;
  final double latitude;
  final double longitude;
  final String address;
  final double accuracy;
  final DateTime timestamp;
  final TrackingType type;
  final ReportInfo? reportInfo;

  const Tracking({
    required this.id,
    required this.imagePath,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.accuracy,
    required this.timestamp,
    this.type = TrackingType.photo,
    this.reportInfo,
  });

  Tracking copyWith({
    String? id,
    String? imagePath,
    double? latitude,
    double? longitude,
    String? address,
    double? accuracy,
    DateTime? timestamp,
    TrackingType? type,
    ReportInfo? reportInfo,
  }) {
    return Tracking(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      reportInfo: reportInfo ?? this.reportInfo,
    );
  }
}
