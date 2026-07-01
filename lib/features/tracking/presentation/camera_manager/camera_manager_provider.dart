import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'camera_manager.dart';

/// Provider untuk lifecycle kamera.
///
/// Catatan desain:
/// - CameraManager menyimpan state non-serializable (CameraController),
///   jadi tipe provider yang cocok adalah [Provider] (bukan AsyncNotifier state).
/// - Saat widget kamera dispose, idealnya panggil `ref.read(...).dispose()`.
final cameraManagerProvider = Provider<CameraManager>((ref) {
  return CameraManager();
});

