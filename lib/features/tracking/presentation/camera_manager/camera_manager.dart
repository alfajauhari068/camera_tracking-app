
import 'package:camera/camera.dart';

/// Platform-agnostic camera lifecycle manager.
///
/// Catatan:
/// - Class ini menahan satu [CameraController] (reuse) untuk mencegah re-init mahal.
/// - UI hanya memanggil metode manager, bukan mengatur lifecycle secara langsung.
/// - Manager tidak bergantung Riverpod, sehingga mudah diuji.
class CameraManager {
  CameraController? _controller;
  List<CameraDescription> _available = const [];
  bool _isInitializing = false;

  bool get isReady => _controller != null && _controller!.value.isInitialized;

  CameraController get controller {
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      throw CameraException('CameraNotReady', 'Camera controller not initialized');
    }
    return c;
  }

  /// Inisialisasi kamera belakang.
  Future<void> initBackCamera({
    ResolutionPreset resolutionPreset = ResolutionPreset.high,
    bool enableAudio = false,
  }) async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      // Discover cameras
      _available = await availableCameras();
      if (_available.isEmpty) {
        throw CameraException('NoCamera', 'No camera devices found');
      }

      final backIndex = _available.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      final chosenIndex = (backIndex != -1) ? backIndex : 0;
      final cam = _available[chosenIndex];

      // Dispose old controller
      await _controller?.dispose();
      _controller = null;

      final controller = CameraController(
        cam,
        resolutionPreset,
        enableAudio: enableAudio,
      );

      _controller = controller;
      await controller.initialize();
    } finally {
      _isInitializing = false;
    }
  }

  /// Foto single.
  Future<XFile> capturePhoto() async {
    final c = controller;
    return c.takePicture();
  }

  bool _isRecording = false;

  Future<void> startRecording() async {
    final c = controller;
    if (_isRecording) return;
    await c.startVideoRecording();
    _isRecording = true;
  }

  Future<XFile?> stopRecording() async {
    final c = controller;
    if (!_isRecording) return null;
    final file = await c.stopVideoRecording();
    _isRecording = false;
    return file;
  }

  Future<void> setFlash(bool on) async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;

    await c.setFlashMode(on ? FlashMode.torch : FlashMode.off);
  }

  Future<void> setZoom(double zoom) async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;

    await c.setZoomLevel(zoom);
  }

  Future<void> setFocusAuto() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;

    try {
      await c.setFocusMode(FocusMode.auto);
    } catch (_) {
      // best-effort
    }
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
    _available = const [];
    _isRecording = false;
  }
}

