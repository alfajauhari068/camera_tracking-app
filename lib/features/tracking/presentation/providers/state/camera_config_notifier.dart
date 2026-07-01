import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'camera_config_state.dart';
import 'package:camera_tracking_gps/core/services/gps_service.dart';

class CameraConfigNotifier extends StateNotifier<CameraConfigState> {
  CameraConfigNotifier()
    : super(
        const CameraConfigState(
          activeTheme: 'Classic Navy',
          showGrid: false,
          gpsMode: CameraGpsMode.real,
          watermarkOpacity: 1.0,
          customLocation: null,
          isFlipping: false,
          showQuickSettings: false,
          zoomLevel: 1.0,
          selectedZoomPreset: CameraZoomPreset.x1_0,
          selectedRatio: CameraAspectRatio.ratio9x16,
          flashMode: CameraFlashMode.off,
          isBackLens: true,
          selectedMode: CameraCaptureMode.photo,
        ),
      );

  void cycleWatermarkTheme() {
    // navy -> oled -> sunset -> navy (as requested)
    final themes = const ['Classic Navy', 'Pure OLED Black', 'Sunset Slate'];
    final nextIndex = (themes.indexOf(state.activeTheme) + 1) % themes.length;
    state = state.copyWith(activeTheme: themes[nextIndex]);
  }

  void cycleFlashMode() {
    const modes = [
      CameraFlashMode.off,
      CameraFlashMode.on,
      CameraFlashMode.auto,
    ];

    final nextIndex = (modes.indexOf(state.flashMode) + 1) % modes.length;
    state = state.copyWith(flashMode: modes[nextIndex]);
  }

  void toggleGrid() {
    state = state.copyWith(showGrid: !state.showGrid);
  }

  void toggleMockGps() {
    final newMode = state.gpsMode == CameraGpsMode.real
        ? CameraGpsMode.simulator
        : CameraGpsMode.real;
    state = state.copyWith(gpsMode: newMode);

    // Propagate to core GpsService so location lookups can return mock data quickly.
    try {
      // Enable or disable mock mode globally. Uses default mock coords unless overridden.
      // Importing GpsService directly avoids creating a provider circular dependency.
      // ignore: avoid_print
      // (Don't use print in production; logger not available here without extra wiring.)
      // Set mock mode
      // Use GpsService.setMockMode to reflect the new state
      // Note: This import is relative to avoid circular provider dependencies.
      // We import within file header.
      GpsService.setMockMode(newMode == CameraGpsMode.simulator);
    } catch (_) {
      // If anything fails, don't crash; state change already applied.
    }
  }

  void toggleQuickSettings() {
    state = state.copyWith(showQuickSettings: !state.showQuickSettings);
  }

  void setWatermarkOpacity(double value) {
    state = state.copyWith(watermarkOpacity: value.clamp(0.0, 1.0));
  }

  void toggleWatermark() {
    // Toggle watermark visibility: empty string = disabled, non-empty = enabled
    final isCurrentlyEnabled = state.activeTheme.isNotEmpty;
    if (isCurrentlyEnabled) {
      // Disable: set theme to empty string
      state = state.copyWith(activeTheme: '');
    } else {
      // Enable: restore to Classic Navy theme
      state = state.copyWith(activeTheme: 'Classic Navy');
    }
  }

  void setCustomLocation(CustomLocation? location) {
    state = state.copyWith(customLocation: location);
  }

  void setAspectRatio(CameraAspectRatio ratio) {
    state = state.copyWith(selectedRatio: ratio);
  }

  void setZoom(double value) {
    final preset = CameraZoomPreset.values.firstWhere(
      (preset) => (preset.value - value).abs() < 0.05,
      orElse: () => state.selectedZoomPreset,
    );

    state = state.copyWith(zoomLevel: value, selectedZoomPreset: preset);
  }

  void setZoomPreset(CameraZoomPreset preset) {
    state = state.copyWith(selectedZoomPreset: preset, zoomLevel: preset.value);
  }

  void toggleLensDirection() {
    // isBackLens -> false/true toggles which lens we want to use in camera manager.
    state = state.copyWith(isBackLens: !state.isBackLens);
  }

  void setLensDirection(bool isBackLens) {
    state = state.copyWith(isBackLens: isBackLens);
  }

  void triggerFlipAnimation() {
    // flip animation is purely visual; the actual lens switching must happen in the camera layer.
    state = state.copyWith(isFlipping: !state.isFlipping);
  }

  /// Mode cycle (PHOTO -> REPORTING -> VIDEO -> GPS SHARE).
  void cycleModes() {
    final modes = const [
      CameraCaptureMode.photo,
      CameraCaptureMode.reporting,
      CameraCaptureMode.video,
      CameraCaptureMode.locationShare,
    ];

    final nextIndex = (modes.indexOf(state.selectedMode) + 1) % modes.length;
    state = state.copyWith(selectedMode: modes[nextIndex]);
  }
}
