import '../../../../core/error/failures.dart';
import '../../../../core/error/result.dart';
import '../entities/tracking.dart';
import '../repositories/tracking_repository.dart';
import '../services/camera_service.dart';
import '../services/geocoding_service.dart';
import '../services/id_generator.dart';
import '../services/location_service.dart';
import '../services/logger.dart';
import '../services/time_provider.dart';

class CaptureTracking {
  final TrackingRepository _repository;
  final CameraService _cameraService;
  final LocationService _locationService;
  final GeocodingService _geocodingService;
  final IdGenerator _idGenerator;
  final TimeProvider _timeProvider;
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
    required Logger logger,
  }) :
    _repository = repository,
    _cameraService = cameraService,
    _locationService = locationService,
    _geocodingService = geocodingService,
    _idGenerator = idGenerator,
    _timeProvider = timeProvider,
    _logger = logger;

  /// Execute the capture phase: camera → GPS → geocode → save
  /// IMPORTANT: Permissions must be granted BEFORE calling this (handled in UI initialization phase)
  /// Returns Result&lt;Tracking&gt; for controlled error flow (not exception-based)
  /// STRICT MODE: All steps must succeed, no partial data saved
  Future<Result<Tracking>> execute() async {
    // Concurrency guard - prevent multiple simultaneous executions
    if (_isRunning) {
      _logger.warning('[CaptureTracking] Capture already in progress, rejecting duplicate request');
      return Result.failure(GenericFailure('Capture already in progress. Please wait.'));
    }

    _isRunning = true;
    _logger.log('[CaptureTracking] Starting photo + GPS + geocoding capture');

    try {
      // ===== STEP 1: Capture Photo + Save to Persistent Storage =====
      _logger.log('[CaptureTracking] Step 1: Capturing and persisting photo...');
      
      final imagePath = await _cameraService.takePicture();
      // NOTE: takePicture() now returns PERSISTENT path, verified to exist
      
      _logger.log('[CaptureTracking] ✅ Photo persisted at: $imagePath');

      // ===== STEP 2: Get Location =====
      _logger.log('[CaptureTracking] Step 2: Getting GPS location...');
      
      final location = await _locationService.getLocation().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          _logger.error('[CaptureTracking] Location timeout after 10 seconds');
          throw LocationTimeoutFailure('Location request timed out after 10 seconds. Please check GPS signal.');
        },
      );
      
      _logger.log('[CaptureTracking] ✅ Location obtained: ${location.latitude}, ${location.longitude}');

      // ===== STEP 3: Geocode Address =====
      _logger.log('[CaptureTracking] Step 3: Geocoding address...');
      
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
      
      _logger.log('[CaptureTracking] ✅ Address geocoded: $address');

      // ===== STEP 4: Create Tracking Entity =====
      // IMPORTANT: imagePath sekarang guaranteed valid (file exists)
      _logger.log('[CaptureTracking] Step 4: Creating Tracking entity...');
      
      final tracking = Tracking(
        id: _idGenerator.generate(),
        imagePath: imagePath,  // 🔑 VALID persistent path, not temp
        latitude: location.latitude,
        longitude: location.longitude,
        address: address,
        accuracy: location.accuracy,
        timestamp: _timeProvider.now(),
      );
      
      _logger.log('[CaptureTracking] Tracking entity created: '
          'id=${tracking.id}, imagePath=${tracking.imagePath}');

      // ===== STEP 5: Save to Repository =====
      _logger.log('[CaptureTracking] Step 5: Saving to repository...');
      
      await _repository.saveTracking(tracking);
      
      _logger.log('[CaptureTracking] ✅ Tracking saved to repository');
      _logger.log('[CaptureTracking] 🎉 Capture pipeline complete!');

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
