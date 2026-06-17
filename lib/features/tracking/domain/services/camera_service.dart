import 'package:camera/camera.dart';

/// Watermark configuration for captured images
class WatermarkConfig {
  final bool enabled;
  final String? locationName;
  final String? address;
  final double? latitude;
  final double? longitude;
  final DateTime? timestamp;

  const WatermarkConfig({
    this.enabled = true,
    this.locationName,
    this.address,
    this.latitude,
    this.longitude,
    this.timestamp,
  });
}

abstract class CameraService {
  /// Initialize camera session (persistent)
  Future<void> init();

  /// Set active camera for capture (called when user switches camera)
  Future<void> setCamera(CameraDescription camera);

  /// Get camera controller for preview
  CameraController? getController();

  /// Check if camera is initialized
  bool isInitialized();

  /// Take a picture with optional watermark
  Future<String> takePicture({WatermarkConfig? watermark});

  /// Set zoom level before capture (called when user changes zoom)
  Future<void> setZoom(double zoom);

  /// Get current zoom level
  double getZoom();

  /// Dispose camera session
  Future<void> dispose();
}
