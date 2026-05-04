/// UI Model untuk Tracking Detail Page
/// Dipisahkan dari domain entity agar tampilan bisa format data sesuai kebutuhan UI
class TrackingDetailUiModel {
  final String id;
  final DateTime timestamp;
  final EventType eventType;
  final double latitude;
  final double longitude;
  final String? address;
  final double? accuracy;
  final String? imagePath;
  final Duration? duration;    // Untuk tracking session
  final double? distance;     // Untuk tracking session (dalam meter)

  const TrackingDetailUiModel({
    required this.id,
    required this.timestamp,
    required this.eventType,
    required this.latitude,
    required this.longitude,
    this.address,
    this.accuracy,
    this.imagePath,
    this.duration,
    this.distance,
  });

  /// Format waktu untuk display
  String get formattedDate {
    final d = timestamp.day.toString().padLeft(2, '0');
    final mo = _monthName(timestamp.month);
    final y = timestamp.year;
    return '$d $mo $y';
  }

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get formattedDateTime => '$formattedDate • $formattedTime';

  /// Format coordinates
  String get coordinatesDisplay {
    return '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
  }

  /// Format accuracy
  String get accuracyDisplay {
    if (accuracy == null) return '--';
    return '±${accuracy!.toStringAsFixed(0)}m';
  }

  /// Format duration (jika tracking session)
  String get durationDisplay {
    if (duration == null) return '--';
    final d = duration!;
    if (d.inHours > 0) {
      return '${d.inHours}j ${d.inMinutes % 60}m';
    } else if (d.inMinutes > 0) {
      return '${d.inMinutes}m ${d.inSeconds % 60}d';
    } else {
      return '${d.inSeconds}d';
    }
  }

  /// Format distance (jika tracking session)
  String get distanceDisplay {
    if (distance == null) return '--';
    if (distance! >= 1000) {
      return '${(distance! / 1000).toStringAsFixed(1)} km';
    } else {
      return '${distance!.toStringAsFixed(0)} m';
    }
  }

  /// Apakah ada foto
  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;

  /// Apakah tracking session (vs snapshot)
  bool get isTrackingSession => eventType == EventType.trackingSession;

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}

/// Jenis event tracking
enum EventType {
  trackingSession,
  snapshot,
}

/// =============================================================================
/// DUMMY DATA
/// =============================================================================
class TrackingDetailDummy {
  static TrackingDetailUiModel getDummy() {
    return TrackingDetailUiModel(
      id: '1',
      timestamp: DateTime(2025, 1, 15, 10, 30),
      eventType: EventType.trackingSession,
      latitude: -6.2000,
      longitude: 106.8161,
      address: 'Jl. Sudirman No.123, Jakarta Pusat',
      accuracy: 5.0,
      imagePath: null,  // Ganti dengan URL contoh jika ada
      duration: const Duration(minutes: 45, seconds: 30),
      distance: 1250.0,
    );
  }

  static TrackingDetailUiModel getDummyWithPhoto() {
    return TrackingDetailUiModel(
      id: '2',
      timestamp: DateTime(2025, 1, 15, 09, 15),
      eventType: EventType.snapshot,
      latitude: -6.1751,
      longitude: 106.8650,
      address: 'Mall Grand Indonesia, Jakarta',
      accuracy: 3.5,
      imagePath: 'https://example.com/photo.jpg',
      duration: null,
      distance: null,
    );
  }
}
