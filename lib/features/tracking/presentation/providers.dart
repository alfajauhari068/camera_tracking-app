import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failures.dart';
import '../domain/entities/tracking.dart';
import '../domain/repositories/tracking_repository.dart';
import '../domain/services/camera_service.dart';
import '../domain/services/geocoding_service.dart';
import '../domain/services/id_generator.dart';
import '../domain/services/location_service.dart';
import '../domain/services/logger.dart';
import '../domain/services/permission_service.dart';
import '../domain/services/time_provider.dart';
import '../domain/usecases/capture_tracking.dart';
import '../data/datasources/tracking_local_datasource.dart';
import '../data/datasources/tracking_local_datasource_impl.dart';
import '../data/repositories/tracking_repository_impl.dart';
import '../data/services/real_camera_service.dart';
import '../data/services/real_geocoding_service.dart';
import '../data/services/real_location_service.dart';
import '../data/services/real_logger.dart';
import '../data/services/real_permission_service.dart';
import '../data/services/real_time_provider.dart';
import '../data/services/timestamp_id_generator.dart';

// Core services
final loggerProvider = Provider<Logger>((ref) => const RealLogger());

final timeProvider = Provider<TimeProvider>((ref) => RealTimeProvider());

final permissionServiceProvider = Provider<PermissionService>(
  (ref) => RealPermissionService(),
);

// Domain services
final idGeneratorProvider = Provider<IdGenerator>(
  (ref) => TimestampIdGenerator(ref.watch(timeProvider)),
);

final cameraServiceProvider = Provider<CameraService>(
  (ref) => RealCameraService(
    logger: ref.watch(loggerProvider),
  ),
);

final locationServiceProvider = Provider<LocationService>(
  (ref) => RealLocationService(ref.watch(loggerProvider)),
);

final geocodingServiceProvider = Provider<GeocodingService>(
  (ref) => RealGeocodingService(ref.watch(loggerProvider)),
);

// Data sources
final trackingLocalDataSourceProvider = Provider<TrackingLocalDataSource>(
  (ref) => TrackingLocalDataSourceImpl(),
);

// Repository
final trackingRepositoryProvider = Provider<TrackingRepository>(
  (ref) => TrackingRepositoryImpl(
    localDataSource: ref.watch(trackingLocalDataSourceProvider),
  ),
);

// UseCase
final captureTrackingProvider = Provider<CaptureTracking>(
  (ref) => CaptureTracking(
    repository: ref.watch(trackingRepositoryProvider),
    cameraService: ref.watch(cameraServiceProvider),
    locationService: ref.watch(locationServiceProvider),
    geocodingService: ref.watch(geocodingServiceProvider),
    idGenerator: ref.watch(idGeneratorProvider),
    timeProvider: ref.watch(timeProvider),
    logger: ref.watch(loggerProvider),
  ),
);

// State management - Enhanced with camera phase tracking
class CaptureState {
  final CapturePhase phase;  // NEW: track current phase
  final bool isLoading;
  final Tracking? tracking;
  final Failure? error;

  const CaptureState({
    this.phase = CapturePhase.ready,
    this.isLoading = false,
    this.tracking,
    this.error,
  });

  CaptureState copyWith({
    CapturePhase? phase,
    bool? isLoading,
    Tracking? tracking,
    Failure? error,
  }) {
    return CaptureState(
      phase: phase ?? this.phase,
      isLoading: isLoading ?? this.isLoading,
      tracking: tracking ?? this.tracking,
      error: error ?? this.error,
    );
  }
}

/// Phases of the capture flow
enum CapturePhase {
  ready,           // Ready to start capture
  initializingCamera,  // Camera initializing
  previewReady,    // Camera preview visible - user sees live feed
  capturingPhoto,  // Taking photo
  processingData,  // GPS + Geocoding
  complete,        // Capture successful
}

class CaptureNotifier extends StateNotifier<CaptureState> {
  final CaptureTracking _captureTracking;
  final Logger _logger;
  final PermissionService _permissionService;
  final CameraService _cameraService;

  CaptureNotifier(
    this._captureTracking,
    this._logger,
    this._permissionService,
    this._cameraService,
  ) : super(const CaptureState());

  /// Phase 1: Initialize camera and request permissions (shows preview)
  Future<void> initializeCamera() async {
    if (state.phase != CapturePhase.ready) {
      _logger.warning('[CaptureNotifier] Camera already initializing or initialized');
      return;
    }

    state = state.copyWith(phase: CapturePhase.initializingCamera, isLoading: true, error: null);

    try {
      // Check/request permissions
      _logger.log('[CaptureNotifier] Requesting camera permission...');
      final cameraPermission = await _permissionService.requestCameraPermission();
      if (cameraPermission != PermissionStatus.granted) {
        final errorMsg = cameraPermission == PermissionStatus.deniedForever
            ? 'Camera permission permanently denied. Please enable in app settings.'
            : 'Camera permission denied. Please grant camera access.';
        throw CameraFailure(errorMsg);
      }

      _logger.log('[CaptureNotifier] Requesting location permission...');
      final locationPermission = await _permissionService.requestLocationPermission();
      if (locationPermission != PermissionStatus.granted) {
        final errorMsg = locationPermission == PermissionStatus.deniedForever
            ? 'Location permission permanently denied. Please enable in app settings.'
            : 'Location permission denied. Please grant location access.';
        throw LocationFailure(errorMsg);
      }

      // Initialize camera (shows preview)
      _logger.log('[CaptureNotifier] Initializing camera service...');
      await _cameraService.init();

      state = state.copyWith(phase: CapturePhase.previewReady, isLoading: false);
      _logger.log('[CaptureNotifier] Camera ready for preview');

    } catch (e) {
      _logger.error('[CaptureNotifier] Error during camera initialization', e);
      final failure = e is Failure ? e : GenericFailure(e.toString());
      state = state.copyWith(
        phase: CapturePhase.ready,
        isLoading: false,
        error: failure,
      );
    }
  }

  /// Phase 2: Capture photo + GPS + Geocoding (user manually clicks capture in preview)
  Future<void> capturePhoto() async {
    if (state.phase != CapturePhase.previewReady) {
      _logger.warning('[CaptureNotifier] Cannot capture - camera not in preview phase');
      return;
    }

    state = state.copyWith(phase: CapturePhase.capturingPhoto, isLoading: true, error: null);

    try {
      _logger.log('[CaptureNotifier] Photo + GPS + Geocoding capture started');
      final result = await _captureTracking.execute();

      result.when(
        success: (tracking) {
          _logger.log('[CaptureNotifier] Capture successful: ${tracking.id}');
          state = state.copyWith(
            phase: CapturePhase.complete,
            isLoading: false,
            tracking: tracking,
            error: null,
          );
        },
        failure: (error) {
          _logger.error('[CaptureNotifier] Capture failed: ${error.message}', error);
          state = state.copyWith(
            phase: CapturePhase.previewReady,  // Back to preview to retry
            isLoading: false,
            error: error,
          );
        },
      );
    } catch (e) {
      _logger.error('[CaptureNotifier] Unexpected error during photo capture', e);
      state = state.copyWith(
        phase: CapturePhase.previewReady,
        isLoading: false,
        error: GenericFailure('Unexpected error: $e'),
      );
    }
  }

  /// Open app settings so user can manually grant permissions
  Future<void> openAppSettings() async {
    try {
      final opened = await _permissionService.openAppSettings();
      if (!opened) {
        _logger.warning('Failed to open app settings');
      } else {
        _logger.log('App settings opened successfully');
      }
    } catch (e) {
      _logger.error('Error opening app settings', e);
    }
  }

  /// Cleanup and reset to ready
  Future<void> reset() async {
    try {
      if (state.phase != CapturePhase.ready) {
        _logger.log('[CaptureNotifier] Disposing camera...');
        await _cameraService.dispose();
      }
    } catch (e) {
      _logger.error('[CaptureNotifier] Error disposing camera', e);
    }
    state = const CaptureState();
  }
}

final captureNotifierProvider = StateNotifierProvider<CaptureNotifier, CaptureState>(
  (ref) => CaptureNotifier(
    ref.watch(captureTrackingProvider),
    ref.watch(loggerProvider),
    ref.watch(permissionServiceProvider),
    ref.watch(cameraServiceProvider),
  ),
);