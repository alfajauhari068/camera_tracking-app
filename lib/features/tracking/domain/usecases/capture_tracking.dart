import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../entities/tracking.dart';
import '../repositories/tracking_repository.dart';
import '../services/camera_service.dart';
import '../services/geocoding_service.dart';
import '../services/id_generator.dart';
import '../services/location_service.dart';
import '../services/logger.dart';
import '../services/permission_service.dart';
import '../services/time_provider.dart';

class CaptureTracking {
  final TrackingRepository _repository;
  final CameraService _cameraService;
  final LocationService _locationService;
  final GeocodingService _geocodingService;
  final IdGenerator _idGenerator;
  final TimeProvider _timeProvider;
  final PermissionService _permissionService;
  final Logger _logger;

  // Concurrency guard - prevents multiple simultaneous executions
  bool _isRunning = false;

  CaptureTracking({
    required TrackingRepository repository,
    required CameraService cameraService,
    required LocationService locationService,
    required GeocodingService geocodingService,
    required IdGenerator idGenerator,
    required TimeProvider timeProvider,
    required PermissionService permissionService,
    required Logger logger,
  }) :
    _repository = repository,
    _cameraService = cameraService,
    _locationService = locationService,
    _geocodingService = geocodingService,
    _idGenerator = idGenerator,
    _timeProvider = timeProvider,
    _permissionService = permissionService,
    _logger = logger;

  /// Execute the complete capture flow: permissions → camera → GPS → geocode → save
  /// Returns Result&lt;Tracking&gt; for controlled error flow (not exception-based)
  /// STRICT MODE: All steps must succeed, no partial data saved
  Future<Result<Tracking>> execute() async {
    // Concurrency guard - prevent multiple simultaneous executions
    if (_isRunning) {
      _logger.warning('[CaptureTracking] Execution already in progress, rejecting duplicate request');
      return Result.failure(GenericFailure('Capture already in progress. Please wait.'));
    }

    _isRunning = true;
    _logger.log('[CaptureTracking] Starting capture tracking flow');

    try {
      // Step 1: Check permissions
      _logger.log('[CaptureTracking] Checking permissions...');
      
      // Check camera permission
      final cameraPermission = await _permissionService.requestCameraPermission();
      if (cameraPermission == PermissionStatus.deniedForever) {
        _logger.error('[CaptureTracking] Camera permission permanently denied');
        return Result.failure(
          PermissionDeniedForeverFailure('Camera permission denied permanently. Please enable it in app settings.')
        );
      }
      if (cameraPermission != PermissionStatus.granted) {
        _logger.error('[CaptureTracking] Camera permission denied');
        return Result.failure(CameraFailure('Camera permission denied. Please grant camera access.'));
      }

      // Check location permission
      final locationPermission = await _permissionService.requestLocationPermission();
      if (locationPermission == PermissionStatus.deniedForever) {
        _logger.error('[CaptureTracking] Location permission permanently denied');
        return Result.failure(
          PermissionDeniedForeverFailure('Location permission denied permanently. Please enable it in app settings.')
        );
      }
      if (locationPermission != PermissionStatus.granted) {
        _logger.error('[CaptureTracking] Location permission denied');
        return Result.failure(LocationFailure('Location permission denied. Please grant location access.'));
      }

      // Step 2: Capture image
      _logger.log('[CaptureTracking] Capturing image...');
      final imagePath = await _cameraService.takePicture();
      _logger.log('[CaptureTracking] Image captured: $imagePath');

      // Step 3: Get location with timeout
      _logger.log('[CaptureTracking] Getting location...');
      final location = await _locationService.getLocation().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          _logger.error('[CaptureTracking] Location timeout after 10 seconds');
          throw LocationTimeoutFailure('Location request timed out after 10 seconds. Please check GPS signal.');
        },
      );
      _logger.log('[CaptureTracking] Location obtained: ${location.latitude}, ${location.longitude}');

      // Step 4: Geocode address with STRICT MODE (no fallback)
      _logger.log('[CaptureTracking] Geocoding address...');
      final address = await _geocodingService.getAddress(
        location.latitude,
        location.longitude,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          // STRICT MODE: No fallback, fail completely
          _logger.warning('[CaptureTracking] Geocoding timeout - failing STRICT mode');
          throw GeocodingTimeoutFailure('Address lookup timed out after 5 seconds. STRICT mode enforced - no partial data.');
        },
      );
      _logger.log('[CaptureTracking] Address geocoded: $address');

      // Step 5: Create and save tracking
      final tracking = Tracking(
        id: _idGenerator.generate(),
        imagePath: imagePath,
        latitude: location.latitude,
        longitude: location.longitude,
        address: address,
        accuracy: location.accuracy,
        timestamp: _timeProvider.now(),
      );

      await _repository.saveTracking(tracking);
      _logger.log('[CaptureTracking] Tracking saved successfully');

      return Result.success(tracking);
    } on PermissionDeniedForeverFailure catch (failure) {
      _logger.error('[CaptureTracking] Permission denied forever: ${failure.message}', failure);
      return Result.failure(failure);
    } on CameraFailure catch (failure) {
      _logger.error('[CaptureTracking] Camera failure: ${failure.message}', failure);
      return Result.failure(failure);
    } on LocationFailure catch (failure) {
      _logger.error('[CaptureTracking] Location failure: ${failure.message}', failure);
      return Result.failure(failure);
    } on LocationTimeoutFailure catch (failure) {
      _logger.error('[CaptureTracking] Location timeout: ${failure.message}', failure);
      return Result.failure(failure);
    } on GeocodingFailure catch (failure) {
      _logger.error('[CaptureTracking] Geocoding failure: ${failure.message}', failure);
      return Result.failure(failure);
    } on GeocodingTimeoutFailure catch (failure) {
      _logger.error('[CaptureTracking] Geocoding timeout: ${failure.message}', failure);
      return Result.failure(failure);
    } on StorageFailure catch (failure) {
      _logger.error('[CaptureTracking] Storage failure: ${failure.message}', failure);
      return Result.failure(failure);
    } catch (e) {
      _logger.error('[CaptureTracking] Unexpected error during capture', e);
      return Result.failure(GenericFailure('Unexpected error during capture: $e'));
    } finally {
      // Always reset concurrency flag
      _isRunning = false;
    }
  }
}
