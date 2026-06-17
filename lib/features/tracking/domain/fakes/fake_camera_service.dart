import 'package:camera/camera.dart';

import '../../../../core/error/failures.dart';
import '../services/camera_service.dart';

class FakeCameraService implements CameraService {
  final bool shouldFail;
  final String? failureMessage;

  FakeCameraService({
    this.shouldFail = false,
    this.failureMessage,
  });

  bool _isInitialized = false;
  double _currentZoom = 1.0;

  @override
  Future<void> init() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (shouldFail) {
      throw CameraFailure(failureMessage ?? 'Failed to initialize camera');
    }
    _isInitialized = true;
  }

  @override
  Future<void> setCamera(CameraDescription camera) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _isInitialized = true;
  }

  @override
  CameraController? getController() => null;

  @override
  bool isInitialized() => _isInitialized;

  @override
  Future<String> takePicture({WatermarkConfig? watermark}) async {
    if (!isInitialized()) {
      throw CameraFailure('Camera not initialized');
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (shouldFail) {
      throw CameraFailure(failureMessage ?? 'Camera failed to capture image');
    }
    return '/storage/emulated/0/DCIM/IMG_20260420_120000.jpg';
  }

  @override
  Future<void> setZoom(double zoom) async {
    _currentZoom = zoom.clamp(1.0, 10.0);
  }

  @override
  double getZoom() => _currentZoom;

  @override
  Future<void> dispose() async {
    _isInitialized = false;
  }
}

