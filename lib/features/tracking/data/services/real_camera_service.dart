import 'package:camera/camera.dart';

import '../../../../core/error/failures.dart';
import '../../domain/services/camera_service.dart';
import '../../domain/services/logger.dart';

/// Real camera service implementation using camera plugin
/// Supports persistent camera session with preview for manual capture
class RealCameraService implements CameraService {
  final Logger logger;

  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  RealCameraService({
    required this.logger,
  });

  /// Initialize camera for preview session (persistent)
  /// Must be called before accessing preview or taking pictures
  @override
  Future<void> init() async {
    if (_isInitialized) {
      logger.log('[CameraService] Camera already initialized');
      return;
    }

    try {
      logger.log('[CameraService] Initializing camera session...');

      // Get available cameras
      _cameras ??= await availableCameras();
      if (_cameras!.isEmpty) {
        logger.error('[CameraService] No cameras available');
        throw CameraFailure('No camera available on this device');
      }

      // Select back camera
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      // Create and initialize controller (persistent for preview)
      _controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      _isInitialized = true;
      logger.log('[CameraService] Camera initialized successfully');

    } on CameraException catch (e) {
      logger.error('[CameraService] Camera exception during init: ${e.code}', e);
      throw _mapCameraException(e);
    } catch (e) {
      logger.error('[CameraService] Unexpected error during init', e);
      throw CameraFailure('Failed to initialize camera: $e');
    }
  }

  /// Get camera controller for UI preview
  @override
  CameraController? getController() {
    if (!_isInitialized) {
      logger.warning('[CameraService] getController called but camera not initialized');
      return null;
    }
    return _controller;
  }

  /// Check if camera is initialized
  @override
  bool isInitialized() => _isInitialized;

  /// Take picture within active session (must call init() first)
  @override
  Future<String> takePicture() async {
    try {
      if (!_isInitialized || _controller == null) {
        logger.error('[CameraService] Camera not initialized for capture');
        throw CameraFailure('Camera not initialized. Call init() first.');
      }

      logger.log('[CameraService] Taking picture...');
      final image = await _controller!.takePicture();
      logger.log('[CameraService] Picture captured: ${image.path}');

      return image.path;

    } on CameraException catch (e) {
      logger.error('[CameraService] Camera exception during capture: ${e.code}', e);
      throw _mapCameraException(e);
    } catch (e) {
      logger.error('[CameraService] Unexpected error during capture', e);
      throw CameraFailure('Failed to capture image: $e');
    }
  }

  /// Map camera plugin exceptions to domain failures
  CameraFailure _mapCameraException(CameraException e) {
    switch (e.code) {
      case 'CameraAccessDenied':
        return CameraFailure('Camera access denied. Please check permissions.');
      case 'CameraAccessDeniedWithoutPrompt':
        return CameraFailure('Camera access denied without prompt.');
      case 'CameraAccessRestricted':
        return CameraFailure('Camera access restricted.');
      case 'AudioAccessDenied':
        return CameraFailure('Audio access denied (though audio disabled).');
      case 'AudioAccessDeniedWithoutPrompt':
        return CameraFailure('Audio access denied without prompt.');
      case 'AudioAccessRestricted':
        return CameraFailure('Audio access restricted.');
      case 'CameraNotAvailable':
        return CameraFailure('Camera not available.');
      case 'CameraNotInitialized':
        return CameraFailure('Camera not initialized.');
      case 'CameraNotReady':
        return CameraFailure('Camera not ready.');
      case 'CameraPermissionNotGranted':
        return CameraFailure('Camera permission not granted.');
      default:
        return CameraFailure('Camera error: ${e.description ?? e.code}');
    }
  }

  /// Dispose resources
  @override
  Future<void> dispose() async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
      _isInitialized = false;
    }
  }
}