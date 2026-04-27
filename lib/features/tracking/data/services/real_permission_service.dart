import 'package:permission_handler/permission_handler.dart' as permission_handler;

import '../../domain/services/permission_service.dart';

/// Real permission service using permission_handler package
class RealPermissionService implements PermissionService {
  /// Convert permission_handler PermissionStatus to our PermissionStatus
  PermissionStatus _convertStatus(
      permission_handler.PermissionStatus permissionStatus) {
    switch (permissionStatus) {
      case permission_handler.PermissionStatus.granted:
        return PermissionStatus.granted;
      case permission_handler.PermissionStatus.denied:
        return PermissionStatus.denied;
      case permission_handler.PermissionStatus.restricted:
        return PermissionStatus.deniedForever;
      case permission_handler.PermissionStatus.limited:
        return PermissionStatus.denied;
      case permission_handler.PermissionStatus.provisional:
        return PermissionStatus.granted;
      case permission_handler.PermissionStatus.permanentlyDenied:
        return PermissionStatus.deniedForever;
    }
  }

  @override
  Future<PermissionStatus> checkCameraPermission() async {
    final status = await permission_handler.Permission.camera.status;
    return _convertStatus(status);
  }

  @override
  Future<PermissionStatus> checkLocationPermission() async {
    final status = await permission_handler.Permission.location.status;
    return _convertStatus(status);
  }

  @override
  Future<PermissionStatus> requestCameraPermission() async {
    final status = await permission_handler.Permission.camera.request();
    return _convertStatus(status);
  }

  @override
  Future<PermissionStatus> requestLocationPermission() async {
    final status = await permission_handler.Permission.location.request();
    return _convertStatus(status);
  }

  @override
  Future<bool> openAppSettings() async {
    return await permission_handler.openAppSettings();
  }
}