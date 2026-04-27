import 'package:geocoding/geocoding.dart';

import '../../../../core/error/failures.dart';
import '../../domain/services/geocoding_service.dart';
import '../../domain/services/logger.dart';

/// Real geocoding service using geocoding package
/// Converts coordinates to human-readable addresses
class RealGeocodingService implements GeocodingService {
  final Logger logger;

  const RealGeocodingService(this.logger);

  @override
  Future<String> getAddress(double latitude, double longitude) async {
    try {
      logger.log('Geocoding coordinates: $latitude, $longitude');

      // Get placemarks from coordinates
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isEmpty) {
        logger.warning('No placemarks found for coordinates');
        return _formatCoordinates(latitude, longitude);
      }

      final placemark = placemarks.first;
      final address = _buildAddressString(placemark);

      logger.log('Address geocoded: $address');
      return address;

    } catch (e) {
      logger.error('Geocoding failed', e);
      throw GeocodingFailure('Failed to get address: $e');
    }
  }

  /// Build human-readable address string from placemark
  String _buildAddressString(Placemark placemark) {
    final components = <String>[];

    // Street address
    if (placemark.street != null && placemark.street!.isNotEmpty) {
      components.add(placemark.street!);
    }

    // City/Locality
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      components.add(placemark.locality!);
    }

    // Administrative area (state/province)
    if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
      components.add(placemark.administrativeArea!);
    }

    // Country
    if (placemark.country != null && placemark.country!.isNotEmpty) {
      components.add(placemark.country!);
    }

    // Postal code
    if (placemark.postalCode != null && placemark.postalCode!.isNotEmpty) {
      components.add(placemark.postalCode!);
    }

    return components.isNotEmpty
        ? components.join(', ')
        : _formatCoordinates(0, 0); // Fallback if no address components
  }

  /// Format coordinates as fallback address
  String _formatCoordinates(double latitude, double longitude) {
    return 'Location: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }
}