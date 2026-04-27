import '../../../../core/error/failures.dart';
import '../services/location_service.dart';

class FakeLocationService implements LocationService {
  final bool shouldFail;
  final String? failureMessage;

  FakeLocationService({
    this.shouldFail = false,
    this.failureMessage,
  });

  @override
  Future<LocationData> getLocation() async {
    // Simulate GPS delay
    await Future.delayed(const Duration(seconds: 1));

    if (shouldFail) {
      throw LocationFailure(failureMessage ?? 'Failed to get location');
    }

    // Return fake location (Jakarta coordinates)
    return const LocationData(
      latitude: -6.2088,
      longitude: 106.8456,
      accuracy: 10.5,
    );
  }
}
