enum CameraCaptureMode { photo, reporting, video, locationShare }

enum CameraFlashMode { off, on, auto }

enum CameraAspectRatio { ratio1x1, ratio3x4, ratio9x16, ratio16x9 }

enum CameraGpsMode { real, simulator }

enum CameraZoomPreset { x0_6, x1_0, x2_0 }

extension CameraAspectRatioX on CameraAspectRatio {
  String get label {
    return switch (this) {
      CameraAspectRatio.ratio1x1 => '1:1',
      CameraAspectRatio.ratio3x4 => '3:4',
      CameraAspectRatio.ratio9x16 => '9:16',
      CameraAspectRatio.ratio16x9 => '16:9',
    };
  }

  double get aspectRatio {
    return switch (this) {
      CameraAspectRatio.ratio1x1 => 1.0,
      CameraAspectRatio.ratio3x4 => 3 / 4,
      CameraAspectRatio.ratio9x16 => 9 / 16,
      CameraAspectRatio.ratio16x9 => 16 / 9,
    };
  }
}

extension CameraGpsModeX on CameraGpsMode {
  String get label {
    return switch (this) {
      CameraGpsMode.real => 'REAL',
      CameraGpsMode.simulator => 'SIMULATOR',
    };
  }

  bool get isSimulator => this == CameraGpsMode.simulator;
}

extension CameraZoomPresetX on CameraZoomPreset {
  double get value {
    return switch (this) {
      CameraZoomPreset.x0_6 => 0.6,
      CameraZoomPreset.x1_0 => 1.0,
      CameraZoomPreset.x2_0 => 2.0,
    };
  }

  String get label {
    return '${value.toStringAsFixed(value == 1.0 ? 0 : 1)}x';
  }
}

class CustomLocation {
  final String name;
  final String address;
  final double lat;
  final double lng;
  final double accuracy;

  const CustomLocation({
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.accuracy,
  });
}

class CameraConfigState {
  final String activeTheme; // "Classic Navy", "Pure OLED Black", "Sunset Slate"
  final bool showGrid; // Grid Rule of Thirds (true/false)
  final CameraGpsMode gpsMode; // Real or Simulator GPS mode

  final double watermarkOpacity; // 0.0..1.0
  final CustomLocation?
  customLocation; // nullable custom override for GPS/watermark

  final bool isFlipping; // 3D flip animation state
  final bool showQuickSettings; // quick settings drawer

  final double zoomLevel; // Actual zoom factor (0.6, 1.0, 2.0)
  final CameraZoomPreset selectedZoomPreset; // Preferred zoom preset
  final CameraAspectRatio selectedRatio; // Aspect ratio selector
  final CameraFlashMode flashMode;

  final bool isBackLens; // True untuk lensa belakang, False untuk lensa depan
  final CameraCaptureMode selectedMode;

  const CameraConfigState({
    required this.activeTheme,
    required this.showGrid,
    required this.gpsMode,
    required this.watermarkOpacity,
    required this.customLocation,
    required this.isFlipping,
    required this.showQuickSettings,
    required this.zoomLevel,
    required this.selectedZoomPreset,
    required this.selectedRatio,
    required this.flashMode,
    required this.isBackLens,
    required this.selectedMode,
  });

  bool get isMockGpsActive => gpsMode.isSimulator;

  CameraConfigState copyWith({
    String? activeTheme,
    bool? showGrid,
    CameraGpsMode? gpsMode,
    double? watermarkOpacity,
    CustomLocation? customLocation,
    bool? isFlipping,
    bool? showQuickSettings,
    double? zoomLevel,
    CameraZoomPreset? selectedZoomPreset,
    CameraAspectRatio? selectedRatio,
    CameraFlashMode? flashMode,
    bool? isBackLens,
    CameraCaptureMode? selectedMode,
  }) {
    return CameraConfigState(
      activeTheme: activeTheme ?? this.activeTheme,
      showGrid: showGrid ?? this.showGrid,
      gpsMode: gpsMode ?? this.gpsMode,
      watermarkOpacity: watermarkOpacity ?? this.watermarkOpacity,
      customLocation: customLocation ?? this.customLocation,
      isFlipping: isFlipping ?? this.isFlipping,
      showQuickSettings: showQuickSettings ?? this.showQuickSettings,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      selectedZoomPreset: selectedZoomPreset ?? this.selectedZoomPreset,
      selectedRatio: selectedRatio ?? this.selectedRatio,
      flashMode: flashMode ?? this.flashMode,
      isBackLens: isBackLens ?? this.isBackLens,
      selectedMode: selectedMode ?? this.selectedMode,
    );
  }
}
