/// Type of failure for UI mapping and retry strategy
enum FailureType {
  /// Camera operation failed (permissions, hardware)
  camera,

  /// Location operation failed (GPS timeout, permissions)
  location,

  /// Location operation timed out
  locationTimeout,

  /// Permission denied permanently (user chose "Don't ask again")
  permissionDeniedForever,

  /// Geocoding service failed (API error, network)
  geocoding,

  /// Geocoding operation timed out
  geocodingTimeout,

  /// Storage operation failed (permission, disk full)
  storage,

  /// Network related error
  network,

  /// Unknown/unexpected error
  unknown,
}

/// Extension to get user-friendly message for FailureType
extension FailureTypeMessage on FailureType {
  String get message {
    switch (this) {
      case FailureType.camera:
        return 'Camera failed';
      case FailureType.location:
        return 'Location service unavailable';
      case FailureType.locationTimeout:
        return 'Location request timed out';
      case FailureType.permissionDeniedForever:
        return 'Permission denied. Please enable it in app settings.';
      case FailureType.geocoding:
        return 'Address lookup failed';
      case FailureType.geocodingTimeout:
        return 'Address lookup timed out';
      case FailureType.storage:
        return 'Storage error';
      case FailureType.network:
        return 'Network error';
      case FailureType.unknown:
        return 'Unknown error';
    }
  }

  /// Whether this failure should allow retry
  bool get isRetryable {
    switch (this) {
      case FailureType.camera:
        return false; // Camera permission usually needs user action
      case FailureType.location:
        return true; // GPS can be retried
      case FailureType.locationTimeout:
        return true; // Timeout can be retried
      case FailureType.permissionDeniedForever:
        return false; // Permission denied forever, needs settings
      case FailureType.geocoding:
        return true; // API can be retried
      case FailureType.geocodingTimeout:
        return true; // Timeout can be retried
      case FailureType.storage:
        return false; // Storage issues usually need user action
      case FailureType.network:
        return true; // Network can be retried
      case FailureType.unknown:
        return false; // Unknown errors shouldn't be retried blindly
    }
  }
}

/// Base failure class for error handling (scalable hierarchy)
abstract class Failure {
  final String message;
  final FailureType type;

  const Failure({
    required this.message,
    required this.type,
  });

  @override
  String toString() => message;
}

/// Failure when camera operations fail
class CameraFailure extends Failure {
  const CameraFailure(String message)
      : super(message: message, type: FailureType.camera);
}

/// Failure when GPS operations fail
class LocationFailure extends Failure {
  const LocationFailure(String message)
      : super(message: message, type: FailureType.location);
}

/// Failure when GPS operations timeout
class LocationTimeoutFailure extends Failure {
  const LocationTimeoutFailure(String message)
      : super(message: message, type: FailureType.locationTimeout);
}

/// Failure when geocoding operations fail
class GeocodingFailure extends Failure {
  const GeocodingFailure(String message)
      : super(message: message, type: FailureType.geocoding);
}

/// Failure when geocoding operations timeout
class GeocodingTimeoutFailure extends Failure {
  const GeocodingTimeoutFailure(String message)
      : super(message: message, type: FailureType.geocodingTimeout);
}

/// Failure when storage operations fail
class StorageFailure extends Failure {
  const StorageFailure(String message)
      : super(message: message, type: FailureType.storage);
}

/// Network related failure
class NetworkFailure extends Failure {
  const NetworkFailure(String message)
      : super(message: message, type: FailureType.network);
}

/// Generic failure
class GenericFailure extends Failure {
  const GenericFailure(String message)
      : super(message: message, type: FailureType.unknown);
}

/// Permission denied permanently (user selected "Don't ask again")
class PermissionDeniedForeverFailure extends Failure {
  const PermissionDeniedForeverFailure(String message)
      : super(message: message, type: FailureType.permissionDeniedForever);
}
