import 'package:camera/camera.dart';

abstract class CameraService {
  /// Initialize camera session (persistent)
  Future<void> init();

  /// Get camera controller for preview
  CameraController? getController();

  /// Check if camera is initialized
  bool isInitialized();

  /// Take a picture within active session and return the image path
  Future<String> takePicture();

  /// Dispose camera session
  Future<void> dispose();
}
