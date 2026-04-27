/// Result of permission check with detail about denial type
enum PermissionStatus {
  /// Permission is granted
  granted,

  /// Permission is denied, but can be requested again
  denied,

  /// Permission is permanently denied (user selected "Don't ask again")
  deniedForever,
}

/// Service for handling device permissions (camera, location)
/// Critical for real device integration - permissions can change at runtime
abstract class PermissionService {
  /// Check camera permission status with detail
  Future<PermissionStatus> checkCameraPermission();

  /// Check location permission status with detail
  Future<PermissionStatus> checkLocationPermission();

  /// Request camera permission from user
  /// Returns [PermissionStatus] indicating the result
  Future<PermissionStatus> requestCameraPermission();

  /// Request location permission from user
  /// Returns [PermissionStatus] indicating the result
  Future<PermissionStatus> requestLocationPermission();

  /// Open app settings so user can manually grant permission
  Future<bool> openAppSettings();
}