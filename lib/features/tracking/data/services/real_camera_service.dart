import 'package:camera/camera.dart';

import '../../../../core/error/failures.dart';
import '../../domain/services/camera_service.dart';
import '../../domain/services/logger.dart';
import '../../domain/services/permission_service.dart';

class RealCameraService implements CameraService {
  final PermissionService permissionService;
  final Logger logger;

  CameraController? _controller;
  List<CameraDescription>? _cameras;
  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;

  RealCameraService({required this.permissionService, required this.logger});

  @override
  Future<void> init() async {
    if (_controller != null && _controller!.value.isInitialized) return;
    logger.log('[CameraService] Initializing camera session...');
    final permissionStatus = await permissionService.requestCameraPermission();
    if (permissionStatus == PermissionStatus.deniedForever) {
      throw CameraFailure('Camera permission permanently denied. Please enable in app settings.');
    }
    if (permissionStatus != PermissionStatus.granted) {
      throw CameraFailure('Camera permission denied. Please grant camera access.');
    }
    _cameras ??= await availableCameras();
    if (_cameras!.isEmpty) {
      throw CameraFailure('No camera available on this device');
    }
    final backCamera = _cameras!.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras!.first,
    );
    final controller = CameraController(backCamera, ResolutionPreset.medium, enableAudio: false);
    await controller.initialize();
    _minZoom = await controller.getMinZoomLevel();
    _maxZoom = await controller.getMaxZoomLevel();
    _currentZoom = 1.0;
    _controller = controller;
  }

  @override
  Future<void> setCamera(CameraDescription camera) async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }
    _cameras ??= await availableCameras();
    final controller = CameraController(camera, ResolutionPreset.medium, enableAudio: false);
    await controller.initialize();
    _minZoom = await controller.getMinZoomLevel();
    _maxZoom = await controller.getMaxZoomLevel();
    _currentZoom = 1.0;
    _controller = controller;
    logger.log('[CameraService] Camera set to: ' + camera.name);
  }

  @override
  CameraController? getController() => _controller;

  @override
  bool isInitialized() => _controller?.value.isInitialized ?? false;

  @override
  Future<String> takePicture({WatermarkConfig? watermark}) async {
    await init();
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw CameraFailure('Camera not initialized');
    }
    try {
      logger.log('[CameraService] Taking picture with zoom: ' + _currentZoom.toString());
      final image = await controller.takePicture();
      if (watermark != null && watermark.enabled) {
        return await _addWatermark(image.path, watermark);
      }
      return image.path;
    } on CameraException catch (e) {
      logger.error('[CameraService] Camera exception: ' + e.code + ' - ' + (e.description ?? ''));
      throw _mapCameraException(e);
    } catch (e) {
      logger.error('[CameraService] Unexpected camera error: ' + e.toString());
      throw CameraFailure('Unexpected camera error: ' + e.toString());
    }
  }

  @override
  Future<void> setZoom(double zoom) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      logger.warning('[CameraService] Cannot set zoom - camera not initialized');
      return;
    }
    final clamped = zoom.clamp(_minZoom, _maxZoom);
    _currentZoom = clamped;
    try {
      await _controller!.setZoomLevel(clamped);
      logger.log('[CameraService] Zoom set to: ' + clamped.toString() + ' (range: ' + _minZoom.toString() + '..' + _maxZoom.toString() + ')');
    } catch (e) {
      logger.error('[CameraService] Failed to set zoom', e);
    }
  }

  @override
  double getZoom() => _currentZoom;

  @override
  Future<void> dispose() async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }
  }

  Future<String> _addWatermark(String path, WatermarkConfig config) async {
    logger.log('[CameraService] Watermark stub called for: ' + path);
    return path;
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
        return CameraFailure('Camera error: ' + e.code);
    }
  }
}

