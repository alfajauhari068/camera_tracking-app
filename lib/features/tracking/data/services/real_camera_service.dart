import 'dart:io';

import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/error/failures.dart';
import '../../domain/services/camera_service.dart';
import '../../domain/services/logger.dart';

/// Real camera service implementation using camera plugin
/// Supports persistent camera session with preview for manual capture
/// IMPORTANT: takePicture() now persists photo to app-controlled storage
class RealCameraService implements CameraService {
  final Logger logger;

  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  
  // Directory untuk menyimpan foto tracking
  static const String _photoDirName = 'tracking_photos';

  RealCameraService({
    required this.logger,
  });

  /// Initialize camera for preview session (persistent)
  /// Must be called before accessing preview or taking pictures
  @override
  Future<void> init() async {
    if (_isInitialized) {
      logger.log('[CameraService] Camera already initialized');
      return;
    }

    try {
      logger.log('[CameraService] Initializing camera session...');

      // Get available cameras
      _cameras ??= await availableCameras();
      if (_cameras!.isEmpty) {
        logger.error('[CameraService] No cameras available');
        throw CameraFailure('No camera available on this device');
      }

      // Select back camera
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      // Create and initialize controller (persistent for preview)
      _controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      _isInitialized = true;
      logger.log('[CameraService] Camera initialized successfully');

    } on CameraException catch (e) {
      logger.error('[CameraService] Camera exception during init: ${e.code}', e);
      throw _mapCameraException(e);
    } catch (e) {
      logger.error('[CameraService] Unexpected error during init', e);
      throw CameraFailure('Failed to initialize camera: $e');
    }
  }

  /// Get camera controller for UI preview
  @override
  CameraController? getController() {
    if (!_isInitialized) {
      logger.warning('[CameraService] getController called but camera not initialized');
      return null;
    }
    return _controller;
  }

  /// Check if camera is initialized
  @override
  bool isInitialized() => _isInitialized;

  /// Take picture dan SIMPAN ke persistent storage dengan path yang valid
  /// 
  /// Flow:
  /// 1. takePicture() dari camera → XFile (temporary)
  /// 2. Buat target directory: /app/documents/tracking_photos/
  /// 3. Generate filename: {timestamp}.jpg
  /// 4. Copy XFile ke target path
  /// 5. Return persistent path & verify file exists
  /// 
  /// Returns: Persistent file path yang GUARANTEED ada di device storage
  @override
  Future<String> takePicture() async {
    try {
      if (!_isInitialized || _controller == null) {
        logger.error('[CameraService] Camera not initialized for capture');
        throw CameraFailure('Camera not initialized. Call init() first.');
      }

      logger.log('[CameraService] Taking picture...');
      
      // Step 1: Capture foto (returns XFile with temp path)
      final xfile = await _controller!.takePicture();
      logger.log('[CameraService] Picture captured (temp): ${xfile.path}');

      // Step 2: Get atau create tracking_photos directory
      final photoDirectory = await _getOrCreatePhotoDirectory();
      logger.log('[CameraService] Photo directory: ${photoDirectory.path}');

      // Step 3: Generate persistent filename dengan timestamp
      final fileName = _generatePhotoFileName();
      final persistentPath = '${photoDirectory.path}/$fileName';
      logger.log('[CameraService] Target persistent path: $persistentPath');

      // Step 4: Copy file dari temp ke persistent location
      await xfile.saveTo(persistentPath);
      logger.log('[CameraService] File saved successfully: $persistentPath');

      // Step 5: Verify file exists
      final fileExists = await File(persistentPath).exists();
      if (!fileExists) {
        logger.error('[CameraService] File save verification failed!');
        throw CameraFailure('Photo save verification failed - file not found');
      }

      logger.log('[CameraService] ✅ Photo persisted and verified at: $persistentPath');
      return persistentPath;

    } on CameraException catch (e) {
      logger.error('[CameraService] Camera exception during capture: ${e.code}', e);
      throw _mapCameraException(e);
    } catch (e) {
      logger.error('[CameraService] Unexpected error during capture', e);
      throw CameraFailure('Failed to capture and save image: $e');
    }
  }

  /// Get atau create folder untuk tracking photos
  /// Path: /app/documents/tracking_photos/
  /// 
  /// Jika folder belum ada, dibuat otomatis
  Future<Directory> _getOrCreatePhotoDirectory() async {
    try {
      // Get app documents directory
      final appDocDir = await getApplicationDocumentsDirectory();
      logger.log('[CameraService] App docs directory: ${appDocDir.path}');

      // Create tracking_photos subdirectory
      final photoDir = Directory('${appDocDir.path}/$_photoDirName');
      
      // Check if directory exists, if not create it
      if (!await photoDir.exists()) {
        logger.log('[CameraService] Creating photo directory: ${photoDir.path}');
        await photoDir.create(recursive: true);
        logger.log('[CameraService] Photo directory created');
      }

      return photoDir;
    } catch (e) {
      logger.error('[CameraService] Failed to get/create photo directory', e);
      throw CameraFailure('Cannot access storage: $e');
    }
  }

  /// Generate unique filename untuk foto baru
  /// Format: {timestamp_milliseconds}.jpg
  /// 
  /// Contoh: 1714461234567.jpg
  String _generatePhotoFileName() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$timestamp.jpg';
  }

  /// Map camera plugin exceptions to domain failures
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

  /// Dispose resources
  @override
  Future<void> dispose() async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
      _isInitialized = false;
    }
  }
}