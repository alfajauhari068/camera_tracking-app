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

  @override
  Future<void> init() async {
    // Simulate camera init delay
    await Future.delayed(const Duration(milliseconds: 300));

    if (shouldFail) {
      throw CameraFailure(failureMessage ?? 'Failed to initialize camera');
    }

    _isInitialized = true;
  }

  @override
  CameraController? getController() => null;

  @override
  bool isInitialized() => _isInitialized;

  @override
  Future<String> takePicture() async {
    if (!isInitialized()) {
      throw CameraFailure('Camera not initialized');
    }

    // Simulate camera delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (shouldFail) {
      throw CameraFailure(failureMessage ?? 'Camera failed to capture image');
    }

    // Return a fake image path
    return '/storage/emulated/0/DCIM/IMG_20260420_120000.jpg';
  }

  @override
  Future<void> dispose() async {
    _isInitialized = false;
  }
}
