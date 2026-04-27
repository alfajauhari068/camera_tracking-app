import '../../../../core/error/failures.dart';
import '../services/geocoding_service.dart';

class FakeGeocodingService implements GeocodingService {
  final bool shouldFail;
  final String? failureMessage;

  FakeGeocodingService({
    this.shouldFail = false,
    this.failureMessage,
  });

  @override
  Future<String> getAddress(double latitude, double longitude) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));

    if (shouldFail) {
      throw GeocodingFailure(failureMessage ?? 'Geocoding service unavailable');
    }

    // Return fake address
    return 'Jl. Gatot Subroto No. 56, Jakarta, Indonesia';
  }
}
