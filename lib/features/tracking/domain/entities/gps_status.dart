/// Data class untuk merepresentasikan status GPS
/// Ini di-bind ke UI untuk menampilkan status GPS secara real-time
class GpsStatus {
  /// Apakah layanan GPS aktif/aktif
  final bool isEnabled;

  /// Apakah GPS sudah mendapatkan lock/lokasi akurat
  final bool hasLock;

  /// Akurasi lokasi dalam meter (null jika belum ada lock)
  final double? accuracy;

  /// Latitude terkini (null jika belum ada lock)
  final double? latitude;

  /// Longitude terkini (null jika belum ada lock)
  final double? longitude;

  /// Konstruktor
  const GpsStatus({
    this.isEnabled = false,
    this.hasLock = false,
    this.accuracy,
    this.latitude,
    this.longitude,
  });

  /// Copy with helper untuk immutability
  GpsStatus copyWith({
    bool? isEnabled,
    bool? hasLock,
    double? accuracy,
    double? latitude,
    double? longitude,
  }) {
    return GpsStatus(
      isEnabled: isEnabled ?? this.isEnabled,
      hasLock: hasLock ?? this.hasLock,
      accuracy: accuracy ?? this.accuracy,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  /// Helper: Apakah GPSready untuk tracking
  bool get isReady => isEnabled && hasLock;

  /// Helper: Format accuracy untuk display
  String get accuracyDisplay {
    if (accuracy == null) return '--';
    return '±${accuracy!.toStringAsFixed(0)}m';
  }

  /// Helper: Format koordinat untuk display
  String get coordinatesDisplay {
    if (latitude == null || longitude == null) return '--';
    return '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}';
  }

  /// Static: Default/off state
  static const GpsStatus off = GpsStatus(isEnabled: false, hasLock: false);
}

/// Data class untuk merepresentasikan status Tracking
class TrackingStatus {
  /// Apakah tracking sedang aktif
  final bool isActive;

  /// Apakah sedang dalam proses pengambilan foto
  final bool isCapturing;

  /// Jumlah foto yang sudah diambil
  final int photoCount;

  /// Konstruktor
  const TrackingStatus({
    this.isActive = false,
    this.isCapturing = false,
    this.photoCount = 0,
  });

  /// Copy with helper untuk immutability
  TrackingStatus copyWith({
    bool? isActive,
    bool? isCapturing,
    int? photoCount,
  }) {
    return TrackingStatus(
      isActive: isActive ?? this.isActive,
      isCapturing: isCapturing ?? this.isCapturing,
      photoCount: photoCount ?? this.photoCount,
    );
  }

  /// Static: Default state
  static const TrackingStatus off = TrackingStatus();
}
