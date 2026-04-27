import 'package:camera/camera.dart';

import '../../../../core/error/failures.dart';
import '../../domain/services/camera_service.dart';
import '../../domain/services/logger.dart';
import '../../domain/services/permission_service.dart';

/// Real camera service implementation using camera plugin
/// Handles permissions, camera initialization, and proper lifecycle management
/// 
/// ARCHITECTURE: Persistent session pattern
/// - init() → start camera session (once per app lifecycle)
/// - takePicture() → capture within active session
/// - dispose() → cleanup session
class RealCameraService implements CameraService {
  final PermissionService permissionService;
  final Logger logger;

  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  RealCameraService({
    required this.permissionService,
    required this.logger,
  });

  @override
  Future<void> init() async {
    if (_isInitialized) {
      logger.log('[CameraService] Camera already initialized, skipping');
      return;
    }

    try {
      // Step 1: Check/request permission
      logger.log('[CameraService] Requesting camera permission...');
      final permissionStatus = await permissionService.requestCameraPermission();
      
      if (permissionStatus == PermissionStatus.deniedForever) {
        logger.error('[CameraService] Camera permission permanently denied');
        throw CameraFailure(
          'Camera permission permanently denied. Please enable in app settings.',
        );
      }
      
      if (permissionStatus != PermissionStatus.granted) {
        logger.error('[CameraService] Camera permission denied');
        throw CameraFailure('Camera permission denied. Please grant camera access.');
      }

      // Step 2: Get available cameras
      _cameras ??= await availableCameras();
      if (_cameras!.isEmpty) {
        logger.error('[CameraService] No cameras available');
        throw CameraFailure('No camera available on this device');
      }

      // Step 3: Select back camera
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      // Step 4: Create and initialize controller (persistent)
      _controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      logger.log('[CameraService] Initializing camera controller...');
      await _controller!.initialize();
      _isInitialized = true;
      logger.log('[CameraService] Camera session initialized successfully');

    } on CameraException catch (e) {
      logger.error('[CameraService] Camera exception during init: ${e.code} - ${e.description}', e);
      throw _mapCameraException(e);
    } catch (e) {
      logger.error('[CameraService] Unexpected error during init', e);
      throw CameraFailure('Camera initialization failed: $e');
    }
  }

  @override
  CameraController? getController() => _controller;

  @override
  bool isInitialized() => _isInitialized && _controller != null && _controller!.value.isInitialized;

  @override
  Future<String> takePicture() async {
    try {
      if (!isInitialized()) {
        logger.error('[CameraService] Camera not initialized');
        throw CameraFailure('Camera not initialized. Call init() first.');
      }

      logger.log('[CameraService] Taking picture...');
      final image = await _controller!.takePicture();
      logger.log('[CameraService] Picture taken: ${image.path}');

      return image.path;

    } on CameraException catch (e) {
      logger.error('[CameraService] Camera exception during capture: ${e.code} - ${e.description}', e);
      throw _mapCameraException(e);
    } catch (e) {
      logger.error('[CameraService] Unexpected error during capture', e);
      throw CameraFailure('Picture capture failed: $e');
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
    try {
      if (_controller != null) {
        logger.log('[CameraService] Disposing camera controller');
        await _controller!.dispose();
        _controller = null;
      }
      _isInitialized = false;
      logger.log('[CameraService] Camera session disposed');
    } catch (e) {
      logger.error('[CameraService] Error during dispose', e);
    }
  }
}