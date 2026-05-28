import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../camera_manager/camera_manager.dart';
import '../providers.dart';

class CameraProviderState {
  final bool isInitializing;
  final bool isReady;
  final bool isPreviewActive;
  final bool isFlashOn;
  final double aspectRatio;
  final double zoomLevel;
  final String? errorMessage;

  const CameraProviderState({
    this.isInitializing = false,
    this.isReady = false,
    this.isPreviewActive = false,
    this.isFlashOn = false,
    this.aspectRatio = 16 / 9,
    this.zoomLevel = 1.0,
    this.errorMessage,
  });

  CameraProviderState copyWith({
    bool? isInitializing,
    bool? isReady,
    bool? isPreviewActive,
    bool? isFlashOn,
    double? aspectRatio,
    double? zoomLevel,
    String? errorMessage,
  }) {
    return CameraProviderState(
      isInitializing: isInitializing ?? this.isInitializing,
      isReady: isReady ?? this.isReady,
      isPreviewActive: isPreviewActive ?? this.isPreviewActive,
      isFlashOn: isFlashOn ?? this.isFlashOn,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      errorMessage: errorMessage,
    );
  }

  bool get hasError => errorMessage != null;
}

class CameraProviderNotifier extends StateNotifier<CameraProviderState> {
  final CameraManager _cameraManager;

  CameraProviderNotifier(this._cameraManager)
      : super(const CameraProviderState());

  Future<void> initCamera() async {
    if (state.isInitializing) return;

    state = state.copyWith(isInitializing: true, errorMessage: null);

    try {
      await _cameraManager.initBackCamera();
      final aspectRatio = _cameraManager.controller.value.aspectRatio;

      state = state.copyWith(
        isInitializing: false,
        isReady: true,
        isPreviewActive: true,
        aspectRatio: aspectRatio > 0 ? aspectRatio : 16 / 9,
      );
    } catch (e) {
      state = state.copyWith(
        isInitializing: false,
        isReady: false,
        isPreviewActive: false,
        errorMessage: 'Gagal memulai kamera: $e',
      );
    }
  }

  Future<void> toggleFlash() async {
    if (!state.isReady) return;

    final newFlashState = !state.isFlashOn;
    try {
      await _cameraManager.setFlash(newFlashState);
      state = state.copyWith(isFlashOn: newFlashState, errorMessage: null);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Gagal mengubah flash: $e');
    }
  }

  Future<void> setZoom(double zoom) async {
    if (!state.isReady) return;

    try {
      const minZoom = 0.6;
      const maxZoom = 10.0;
      final clampedZoom = zoom.clamp(minZoom, maxZoom);
      await _cameraManager.setZoom(clampedZoom);
      state = state.copyWith(zoomLevel: clampedZoom, errorMessage: null);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Gagal mengatur zoom: $e');
    }
  }

  Future<void> applyZoomPreset(double zoom) async {
    await setZoom(zoom);
  }

  double get physicalZoomFactor => state.zoomLevel;
}

final cameraProvider = StateNotifierProvider<CameraProviderNotifier, CameraProviderState>(
  (ref) => CameraProviderNotifier(ref.watch(cameraManagerProvider)),
);
