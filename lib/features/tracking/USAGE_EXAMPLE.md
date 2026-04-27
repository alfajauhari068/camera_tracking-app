/*
# USAGE EXAMPLE - STEP 1 (WITH FAKE SERVICES)

## 🎯 How to use CaptureTracking UseCase

This example shows how to wire up the UseCase with fake services
for testing and validation purposes.

## 📝 Code Example

```dart
import 'package:camera_tracking_gps/features/tracking/domain/usecases/capture_tracking.dart';
import 'package:camera_tracking_gps/features/tracking/domain/fakes/fake_camera_service.dart';
import 'package:camera_tracking_gps/features/tracking/domain/fakes/fake_location_service.dart';
import 'package:camera_tracking_gps/features/tracking/domain/fakes/fake_geocoding_service.dart';
import 'package:camera_tracking_gps/features/tracking/domain/fakes/fake_tracking_repository.dart';

void main() async {
  // Setup fake services
  final cameraService = FakeCameraService();
  final locationService = FakeLocationService();
  final geocodingService = FakeGeocodingService();
  final repository = FakeTrackingRepository();

  // Create UseCase with injected dependencies
  final captureTracking = CaptureTracking(
    repository: repository,
    cameraService: cameraService,
    locationService: locationService,
    geocodingService: geocodingService,
  );

  // Execute the complete flow
  print('Starting capture flow...');
  await captureTracking.execute();
  print('Capture completed successfully!');

  // Verify data was saved
  final allTrackings = await repository.getTrackings();
  print('Total trackings saved: ${allTrackings.length}');
  
  if (allTrackings.isNotEmpty) {
    final tracking = allTrackings.first;
    print('Latest tracking:');
    print('  ID: ${tracking.id}');
    print('  Image: ${tracking.imagePath}');
    print('  Location: ${tracking.latitude}, ${tracking.longitude}');
    print('  Address: ${tracking.address}');
    print('  Accuracy: ${tracking.accuracy}m');
    print('  Time: ${tracking.timestamp}');
  }
}
```

## ✅ Self-Test Validation

### TEST 1 - Swap Storage
```dart
// Currently using FakeTrackingRepository (in-memory)
// To test with real file storage:

import 'package:camera_tracking_gps/features/tracking/data/datasources/tracking_local_datasource_impl.dart';
import 'package:camera_tracking_gps/features/tracking/data/repositories/tracking_repository_impl.dart';

final localDataSource = TrackingLocalDataSourceImpl();
final repository = TrackingRepositoryImpl(localDataSource: localDataSource);

// Pass this repository to CaptureTracking
final captureTracking = CaptureTracking(
  repository: repository,  // SWITCHED from FakeTrackingRepository
  cameraService: cameraService,
  locationService: locationService,
  geocodingService: geocodingService,
);

// UseCase continues to work WITHOUT ANY CHANGES ✅
await captureTracking.execute();
```

✅ RESULT: No changes needed to UseCase! Proves layer separation is correct.

### TEST 2 - Mock Different Services
```dart
// Create custom fake services for specific testing
class CustomFakeCameraService implements CameraService {
  @override
  Future<String> takePicture() async {
    return '/custom/path/image.jpg';
  }
}

class CustomFakeLocationService implements LocationService {
  @override
  Future<LocationData> getLocation() async {
    return const LocationData(
      latitude: -33.8688,  // Sydney
      longitude: 151.2093,
      accuracy: 5.0,
    );
  }
}

final captureTracking = CaptureTracking(
  repository: repository,
  cameraService: CustomFakeCameraService(),
  locationService: CustomFakeLocationService(),
  geocodingService: geocodingService,
);

await captureTracking.execute();  // Still works! ✅
```

✅ RESULT: UseCase works with any service implementation!

### TEST 3 - UI Independence
```dart
// In UI (presentation layer), you would do:

// 1. Get UseCase from dependency injection (STEP 2)
final captureTracking = getIt<CaptureTracking>();

// 2. Call execute() without knowing implementation details
await captureTracking.execute();

// 3. Get results from repository
final trackings = await repository.getTrackings();

// UI NEVER knows about:
// ❌ CameraService internals
// ❌ LocationService implementation
// ❌ GeocodingService API details
// ❌ File storage mechanisms
// ✅ Only knows about Tracking entity and execute() method
```

✅ RESULT: UI is completely decoupled from business logic!

## 🔍 Architecture Validation Checklist

- [x] Domain layer has NO imports from data layer
- [x] UseCase is the ONLY entry point for logic
- [x] Entity has NO JSON methods (toJson/fromJson)
- [x] Services are injected (NOT hardcoded)
- [x] Repository can be swapped without UseCase changes
- [x] Fake implementations work with real UseCase
- [x] No file I/O in domain layer
- [x] No API calls in domain layer

## 🎯 Dependency Inversion Principle Applied

UseCase depends on abstractions (interfaces), not concrete implementations:
- CameraService (abstract) ← UseCase depends on this
- FakeCameraService (concrete) ← Test uses this
- RealCameraService (concrete, STEP 2) ← Production uses this

Same implementation class, multiple concrete providers! ✅
*/
