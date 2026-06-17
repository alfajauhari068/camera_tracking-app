import 'package:geolocator/geolocator.dart';

import '../../../../core/error/failures.dart';
import '../../domain/services/location_service.dart';
import '../../domain/services/logger.dart';

/// Real location service using geolocator package
/// Handles GPS permissions, accuracy settings, and timeout
class RealLocationService implements LocationService {
  final Logger logger;

  const RealLocationService(this.logger);

  @override
  Future<LocationData> getLocation() async {
    try {
      logger.log('Requesting location...');

      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        logger.error('Location services disabled');
        throw LocationFailure('Location services are disabled. Please enable GPS.');
      }

      // NOTE: Permission is already handled at UseCase level (CaptureTracking.execute)
      // This service only gets the location - DO NOT request permission here to avoid race conditions

      // Get current position with high accuracy
      logger.log('Getting current position...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      logger.log('Position obtained: ${position.latitude}, ${position.longitude}');

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );

    } on LocationServiceDisabledException {
      logger.error('Location service disabled exception');
      throw LocationFailure('Location services are disabled. Please enable GPS.');
    } on PermissionDeniedException {
      logger.error('Location permission denied exception');
      throw LocationFailure('Location permission denied. Please enable location in app settings.');
    } catch (e) {
      logger.error('Unexpected location error', e);
      // Check if it's a timeout (timeLimit exceeded)
      if (e.toString().contains('TimeOut') || e.toString().contains('timeout')) {
        throw LocationTimeoutFailure('Location request timed out. Please check GPS signal.');
      }
      throw LocationFailure('Failed to get location: $e');
    }
  }
}