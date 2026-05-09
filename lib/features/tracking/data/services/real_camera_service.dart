import 'package:camera/camera.dart';

import '../../../../core/error/failures.dart';
import '../../domain/services/camera_service.dart';
import '../../domain/services/logger.dart';
import '../../domain/services/permission_service.dart';

/// Real camera service implementation using camera plugin.
///
/// Implements the full `CameraService` contract from `domain/services/camera_service.dart`.
class RealCameraService implements CameraService {
  final PermissionService permissionService;
  final Logger logger;

  CameraController? _controller;
  List<CameraDescription>? _cameras;

  RealCameraService({
    required this.permissionService,
    required this.logger,
  });

  @override
  Future<void> init() async {
    if (_controller != null && _controller!.value.isInitialized) return;

    logger.log('[CameraService] Initializing camera session...');

    // Permission
    final permissionStatus = await permissionService.requestCameraPermission();
    if (permissionStatus == PermissionStatus.deniedForever) {
      throw CameraFailure(
        'Camera permission permanently denied. Please enable in app settings.',
      );
    }
    if (permissionStatus != PermissionStatus.granted) {
      throw CameraFailure('Camera permission denied. Please grant camera access.');
    }

    // Cameras
    _cameras ??= await availableCameras();
    if (_cameras!.isEmpty) {
      throw CameraFailure('No camera available on this device');
    }

    final backCamera = _cameras!.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras!.first,
    );

    final controller = CameraController(
      backCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await controller.initialize();
    _controller = controller;
  }

  @override
  CameraController? getController() => _controller;

  @override
  bool isInitialized() => _controller?.value.isInitialized ?? false;

  @override
  Future<String> takePicture() async {
    await init();

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw CameraFailure('Camera not initialized');
    }

    try {
      logger.log('[CameraService] Taking picture...');
      final image = await controller.takePicture();
      return image.path;
    } on CameraException catch (e) {
      logger.error('[CameraService] Camera exception: ${e.code} - ${e.description}', e);
      throw _mapCameraException(e);
    } catch (e) {
      logger.error('[CameraService] Unexpected camera error', e);
      throw CameraFailure('Unexpected camera error: $e');
    }
  }

  @override
  Future<void> dispose() async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }
  }

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
}

