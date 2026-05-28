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
import '../domain/usecases/get_tracking_by_id.dart';
import '../domain/usecases/export_trackings.dart';
import '../domain/services/export_service.dart';
import '../data/services/real_export_service.dart';

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
import 'camera_manager/camera_manager.dart';

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
    permissionService: ref.watch(permissionServiceProvider),
    logger: ref.watch(loggerProvider),
  ),
);

final locationServiceProvider = Provider<LocationService>(
  (ref) => RealLocationService(ref.watch(loggerProvider)),
);

final geocodingServiceProvider = Provider<GeocodingService>(
  (ref) => RealGeocodingService(ref.watch(loggerProvider)),
);

final cameraManagerProvider = Provider<CameraManager>(
  (ref) {
    final manager = CameraManager();
    ref.onDispose(() => manager.dispose());
    return manager;
  },
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
    permissionService: ref.watch(permissionServiceProvider),
    logger: ref.watch(loggerProvider),
  ),
);

// ------------------------------
// Missing providers (used by pages)
// ------------------------------

final getTrackingByIdProvider = Provider<GetTrackingById>(
  (ref) => GetTrackingById(
    repository: ref.watch(trackingRepositoryProvider),
  ),
);

final exportServiceProvider = Provider<ExportService>(
  (ref) => RealExportService(ref.watch(loggerProvider)),
);

final exportTrackingsProvider = Provider<ExportTrackings>(
  (ref) => ExportTrackings(
    repository: ref.watch(trackingRepositoryProvider),
    exportService: ref.watch(exportServiceProvider),
  ),
);


// State management
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