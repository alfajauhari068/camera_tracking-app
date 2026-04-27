import 'package:camera/camera.dart';
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

// ============================================================================
// CORE SERVICES
// ============================================================================

final loggerProvider = Provider<Logger>((ref) => const RealLogger());

final timeProvider = Provider<TimeProvider>((ref) => RealTimeProvider());

final permissionServiceProvider = Provider<PermissionService>(
  (ref) => RealPermissionService(),
);

// ============================================================================
// CAMERA SERVICE WITH PERSISTENT LIFECYCLE
// ============================================================================

final cameraServiceProvider = Provider<CameraService>(
  (ref) => RealCameraService(
    permissionService: ref.watch(permissionServiceProvider),
    logger: ref.watch(loggerProvider),
  ),
);

/// Camera controller state notifier - manages camera lifecycle
class CameraControllerState {
  final CameraController? controller;
  final bool isInitializing;
  final Failure? error;

  const CameraControllerState({
    this.controller,
    this.isInitializing = false,
    this.error,
  });

  bool get isInitialized => controller != null && controller!.value.isInitialized;

  CameraControllerState copyWith({
    CameraController? controller,
    bool? isInitializing,
    Failure? error,
  }) {
    return CameraControllerState(
      controller: controller ?? this.controller,
      isInitializing: isInitializing ?? this.isInitializing,
      error: error ?? this.error,
    );
  }
}

class CameraControllerNotifier extends StateNotifier<CameraControllerState> {
  final CameraService _cameraService;
  final Logger _logger;

  CameraControllerNotifier(this._cameraService, this._logger)
      : super(const CameraControllerState());

  /// Initialize camera session (call once at app start)
  Future<void> initializeCamera() async {
    if (state.isInitialized) {
      _logger.log('[CameraNotifier] Camera already initialized, skipping');
      return;
    }

    state = state.copyWith(isInitializing: true, error: null);

    try {
      await _cameraService.init();
      final controller = _cameraService.getController();

      state = state.copyWith(
        controller: controller,
        isInitializing: false,
        error: null,
      );

      _logger.log('[CameraNotifier] Camera initialized successfully');
    } catch (e) {
      _logger.error('[CameraNotifier] Failed to initialize camera', e);
      state = state.copyWith(
        isInitializing: false,
        error: e is Failure ? e : GenericFailure('Camera initialization failed: $e'),
      );
    }
  }

  /// Dispose camera session
  Future<void> disposeCamera() async {
    try {
      await _cameraService.dispose();
      state = const CameraControllerState();
      _logger.log('[CameraNotifier] Camera disposed');
    } catch (e) {
      _logger.error('[CameraNotifier] Error disposing camera', e);
    }
  }
}

final cameraControllerProvider =
    StateNotifierProvider<CameraControllerNotifier, CameraControllerState>((ref) {
  return CameraControllerNotifier(
    ref.watch(cameraServiceProvider),
    ref.watch(loggerProvider),
  );
});

// ============================================================================
// DOMAIN SERVICES
// ============================================================================

final idGeneratorProvider = Provider<IdGenerator>(
  (ref) => TimestampIdGenerator(ref.watch(timeProvider)),
);

final locationServiceProvider = Provider<LocationService>(
  (ref) => RealLocationService(ref.watch(loggerProvider)),
);

final geocodingServiceProvider = Provider<GeocodingService>(
  (ref) => RealGeocodingService(ref.watch(loggerProvider)),
);

// ============================================================================
// DATA SOURCES & REPOSITORIES
// ============================================================================

final trackingLocalDataSourceProvider = Provider<TrackingLocalDataSource>(
  (ref) => TrackingLocalDataSourceImpl(),
);

final trackingRepositoryProvider = Provider<TrackingRepository>(
  (ref) => TrackingRepositoryImpl(
    localDataSource: ref.watch(trackingLocalDataSourceProvider),
  ),
);

// ============================================================================
// USE CASES
// ============================================================================

final captureTrackingProvider = Provider<CaptureTracking>(
  (ref) => CaptureTracking(
    repository: ref.watch(trackingRepositoryProvider),
    cameraService: ref.watch(cameraServiceProvider),
    locationService: ref.watch(locationServiceProvider),
    geocodingService: ref.watch(geocodingServiceProvider),
    idGenerator: ref.watch(idGeneratorProvider),
    timeProvider: ref.watch(timeProvider),
    permissionService: ref.watch(permissionServiceProvider),
    logger: ref.watch(loggerProvider),
  ),
);

// ============================================================================
// STATE MANAGEMENT - CAPTURE FLOW
// ============================================================================

class CaptureState {
  final bool isLoading;
  final Tracking? tracking;
  final Failure? error;

  const CaptureState({
    this.isLoading = false,
    this.tracking,
    this.error,
  });

  CaptureState copyWith({
    bool? isLoading,
    Tracking? tracking,
    Failure? error,
  }) {
    return CaptureState(
      isLoading: isLoading ?? this.isLoading,
      tracking: tracking ?? this.tracking,
      error: error ?? this.error,
    );
  }
}

class CaptureNotifier extends StateNotifier<CaptureState> {
  final CaptureTracking _captureTracking;
  final Logger _logger;
  final PermissionService _permissionService;

  CaptureNotifier(
    this._captureTracking,
    this._logger,
    this._permissionService,
  ) : super(const CaptureState());

  Future<void> capture() async {
    if (state.isLoading) {
      _logger.warning('Capture already in progress, ignoring duplicate request');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _captureTracking.execute();

      result.when(
        success: (tracking) {
          _logger.log('Capture successful: ${tracking.id}');
          state = state.copyWith(
            isLoading: false,
            tracking: tracking,
            error: null,
          );
        },
        failure: (error) {
          _logger.error('Capture failed: ${error.message}', error);
          state = state.copyWith(
            isLoading: false,
            error: error,
          );
        },
      );
    } catch (e) {
      _logger.error('Unexpected error in capture notifier', e);
      state = state.copyWith(
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

  void reset() {
    state = const CaptureState();
  }
}

final captureNotifierProvider = StateNotifierProvider<CaptureNotifier, CaptureState>(
  (ref) => CaptureNotifier(
    ref.watch(captureTrackingProvider),
    ref.watch(loggerProvider),
    ref.watch(permissionServiceProvider),
  ),
);
