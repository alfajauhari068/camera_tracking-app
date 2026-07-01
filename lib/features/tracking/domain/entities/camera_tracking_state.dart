/// State model untuk Camera Tracking Screen
/// Holds: preview state, coordinates, GPS status, tracking status
class CameraTrackingState {
  /// Fase camera preview
  final CameraPreviewPhase previewPhase;

  /// Status GPS
  final GpsInfo gpsInfo;

  /// Status tracking (aktif/nonaktif)
  final bool isTrackingActive;

  /// Apakah flash aktif
  final bool isFlashOn;

  /// Apakah menggunakan front/back camera
  final bool isFrontCamera;

  /// Waktu sekarang (untuk display)
  final DateTime currentTime;

  /// Error message jika ada
  final String? errorMessage;

  const CameraTrackingState({
    this.previewPhase = CameraPreviewPhase.initializing,
    this.gpsInfo = const GpsInfo(),
    this.isTrackingActive = false,
    this.isFlashOn = false,
    this.isFrontCamera = false,
    required this.currentTime,
    this.errorMessage,
  });

  /// Copy with helper
  CameraTrackingState copyWith({
    CameraPreviewPhase? previewPhase,
    GpsInfo? gpsInfo,
    bool? isTrackingActive,
    bool? isFlashOn,
    bool? isFrontCamera,
    DateTime? currentTime,
    String? errorMessage,
  }) {
    return CameraTrackingState(
      previewPhase: previewPhase ?? this.previewPhase,
      gpsInfo: gpsInfo ?? this.gpsInfo,
      isTrackingActive: isTrackingActive ?? this.isTrackingActive,
      isFlashOn: isFlashOn ?? this.isFlashOn,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      currentTime: currentTime ?? this.currentTime,
      errorMessage: errorMessage,
    );
  }

  /// Static factory untuk initial state
  factory CameraTrackingState.initial() => CameraTrackingState(
    currentTime: DateTime.now(),
  );
}

/// Fase camera preview
enum CameraPreviewPhase {
  initializing,  // Camera sedang init
  ready,          // Camera siap, GPS menunggu
  preview,       // Camera preview aktif
  error,         // Error occurred
}

/// Informasi GPS
class GpsInfo {
  /// Apakah GPS aktif/ter koneksi
  final bool isEnabled;

  /// Apakah sudah dapat lock
  final bool hasLock;

  /// Latitude
  final double? latitude;

  /// Longitude
  final double? longitude;

  /// Akurasi dalam meter
  final double? accuracy;

  const GpsInfo({
    this.isEnabled = false,
    this.hasLock = false,
    this.latitude,
    this.longitude,
    this.accuracy,
  });

  /// Copy with helper
  GpsInfo copyWith({
    bool? isEnabled,
    bool? hasLock,
    double? latitude,
    double? longitude,
    double? accuracy,
  }) {
    return GpsInfo(
      isEnabled: isEnabled ?? this.isEnabled,
      hasLock: hasLock ?? this.hasLock,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
    );
  }

  /// Format koordinat untuk display
  String get coordinatesDisplay {
    if (latitude == null || longitude == null) return '--';
    return '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}';
  }

  /// Format akurasi untuk display
  String get accuracyDisplay {
    if (accuracy == null) return '--';
    return '±${accuracy!.toStringAsFixed(0)}m';
  }

  /// Status text Indonesia
  String get statusText {
    if (!isEnabled) return 'GPS Mati';
    if (!hasLock) return 'Mencari...';
    return 'Tergunci';
  }

  /// Static: Default (off)
  static const GpsInfo disconnected = GpsInfo();
}
