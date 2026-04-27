/*
# ERROR HANDLING & TESTING GUIDE - AFTER AUDIT FIXES

## 🔄 Updated Flow

CaptureTracking.execute() sekarang:
- ✅ RETURN: Tracking entity (data untuk UI/state management)
- ✅ THROW: Failure exception (untuk error handling)
- ✅ INJECT: IdGenerator (tidak hardcode ID)
- ✅ CATCH: Terstruktur (specific failure types)

---

## 📝 Basic Usage (Success Scenario)

```dart
import 'package:camera_tracking_gps/features/tracking/domain/usecases/capture_tracking.dart';
import 'package:camera_tracking_gps/features/tracking/domain/fakes/fake_camera_service.dart';
import 'package:camera_tracking_gps/features/tracking/domain/fakes/fake_location_service.dart';
import 'package:camera_tracking_gps/features/tracking/domain/fakes/fake_geocoding_service.dart';
import 'package:camera_tracking_gps/features/tracking/domain/fakes/fake_tracking_repository.dart';
import 'package:camera_tracking_gps/features/tracking/domain/fakes/fake_id_generator.dart';

Future<void> main() async {
  final captureTracking = CaptureTracking(
    repository: FakeTrackingRepository(),
    cameraService: FakeCameraService(),
    locationService: FakeLocationService(),
    geocodingService: FakeGeocodingService(),
    idGenerator: FakeIdGenerator(),
  );

  try {
    // Execute returns the created Tracking
    final tracking = await captureTracking.execute();
    print('✅ Capture successful!');
    print('ID: ${tracking.id}');
    print('Image: ${tracking.imagePath}');
    print('Location: (${tracking.latitude}, ${tracking.longitude})');
  } on Failure catch (failure) {
    print('❌ Error: ${failure.message}');
  }
}
```

---

## 🧪 Test Scenario 1: Camera Failure

```dart
Future<void> testCameraFailure() async {
  final captureTracking = CaptureTracking(
    repository: FakeTrackingRepository(),
    cameraService: FakeCameraService(
      shouldFail: true,
      failureMessage: 'Camera permission denied',
    ),
    locationService: FakeLocationService(),
    geocodingService: FakeGeocodingService(),
    idGenerator: FakeIdGenerator(),
  );

  try {
    await captureTracking.execute();
    print('❌ Should have thrown CameraFailure');
  } on CameraFailure catch (failure) {
    print('✅ Caught CameraFailure: ${failure.message}');
    assert(failure.message == 'Camera permission denied');
  }
}
```

Expected: CameraFailure is thrown, caught, and message is accessible.

---

## 🧪 Test Scenario 2: Location Failure (GPS Timeout)

```dart
Future<void> testLocationTimeout() async {
  final captureTracking = CaptureTracking(
    repository: FakeTrackingRepository(),
    cameraService: FakeCameraService(),
    locationService: FakeLocationService(
      shouldFail: true,
      failureMessage: 'GPS timeout after 30 seconds',
    ),
    geocodingService: FakeGeocodingService(),
    idGenerator: FakeIdGenerator(),
  );

  try {
    await captureTracking.execute();
    print('❌ Should have thrown LocationFailure');
  } on LocationFailure catch (failure) {
    print('✅ Caught LocationFailure: ${failure.message}');
    assert(failure.message == 'GPS timeout after 30 seconds');
  }
}
```

Expected: Capture stops after camera succeeds, but before location query. Flow is correct.

---

## 🧪 Test Scenario 3: Geocoding API Failure

```dart
Future<void> testGeocodingFailure() async {
  final captureTracking = CaptureTracking(
    repository: FakeTrackingRepository(),
    cameraService: FakeCameraService(),
    locationService: FakeLocationService(),
    geocodingService: FakeGeocodingService(
      shouldFail: true,
      failureMessage: 'Geocoding API rate limit exceeded',
    ),
    idGenerator: FakeIdGenerator(),
  );

  try {
    await captureTracking.execute();
    print('❌ Should have thrown GeocodingFailure');
  } on GeocodingFailure catch (failure) {
    print('✅ Caught GeocodingFailure: ${failure.message}');
  }
}
```

Expected: Camera and GPS succeed, but geocoding fails. Demonstrates orchestration.

---

## 🧪 Test Scenario 4: Storage Failure

```dart
Future<void> testStorageFailure() async {
  final captureTracking = CaptureTracking(
    repository: FakeTrackingRepository(shouldFailSave: true),
    cameraService: FakeCameraService(),
    locationService: FakeLocationService(),
    geocodingService: FakeGeocodingService(),
    idGenerator: FakeIdGenerator(),
  );

  try {
    await captureTracking.execute();
    print('❌ Should have thrown StorageFailure');
  } on StorageFailure catch (failure) {
    print('✅ Caught StorageFailure: ${failure.message}');
  }
}
```

Expected: All data collected, but save to storage fails. Shows complete flow.

---

## 🧪 Test Scenario 5: Return Value

```dart
Future<void> testReturnTracking() async {
  final idGen = FakeIdGenerator();
  final repo = FakeTrackingRepository();
  
  final captureTracking = CaptureTracking(
    repository: repo,
    cameraService: FakeCameraService(),
    locationService: FakeLocationService(),
    geocodingService: FakeGeocodingService(),
    idGenerator: idGen,
  );

  // Execute returns Tracking
  final tracking = await captureTracking.execute();

  // Verify returned data
  assert(tracking.id == 'fake_id_1', 'Should use injected ID generator');
  assert(tracking.imagePath.isNotEmpty, 'Should have image path');
  assert(tracking.latitude != 0, 'Should have latitude');
  assert(tracking.address.isNotEmpty, 'Should have address');

  // Verify data was saved
  final allTrackings = await repo.getTrackings();
  assert(allTrackings.length == 1, 'Should save exactly 1 tracking');
  assert(allTrackings.first.id == tracking.id, 'Saved ID should match returned ID');

  print('✅ Return value test passed!');
}
```

Expected: UseCase returns the created Tracking entity. UI can use this for rendering.

---

## 📊 Error Handling Architecture

```
CaptureTracking.execute() throws
  ↓
Specific Failure type caught at UI/Controller level
  ├── CameraFailure → Show "Camera permission denied"
  ├── LocationFailure → Show "Could not get GPS signal"
  ├── GeocodingFailure → Show "Address lookup failed"
  ├── StorageFailure → Show "Could not save data"
  └── GenericFailure → Show generic error

UI/Controller decides how to handle each type
```

---

## 🔑 Key Changes from Original STEP 1

### BEFORE (Issues):
```dart
Future<void> execute() async {
  // ...
  final id = '${now.millisecondsSinceEpoch}_${now.microsecond}';
  // ...
  // No return value
  // No error typing
}
```

### AFTER (Fixed):
```dart
Future<Tracking> execute() async {
  try {
    // ... steps ...
    final id = idGenerator.generate();  // Injected!
    final tracking = Tracking(...);
    await repository.saveTracking(tracking);
    return tracking;  // ← Return for UI
  } on CameraFailure {
    rethrow;  // Typed errors ✅
  }
  // ...
}
```

---

## ✅ Self-Test Validation (Updated)

### TEST 1: Return Value Makes Sense
```dart
final tracking = await useCase.execute();
// UI can now render this data ✅
```

### TEST 2: Error Handling is Catchable
```dart
try {
  await useCase.execute();
} on CameraFailure {
  // Handle camera-specific error
} on LocationFailure {
  // Handle location-specific error
}
// Clear error contracts ✅
```

### TEST 3: IdGenerator Swappable
```dart
// Test with FakeIdGenerator
final idGen1 = FakeIdGenerator();
final useCase1 = CaptureTracking(..., idGenerator: idGen1);

// Production with TimestampIdGenerator
final idGen2 = TimestampIdGenerator();
final useCase2 = CaptureTracking(..., idGenerator: idGen2);

// Both work without changing UseCase ✅
```

---

## 🎯 Ready for STEP 2

Now UseCase is:
- ✅ Returning meaningful data
- ✅ Throwing typed exceptions
- ✅ Fully injectable (all dependencies)
- ✅ Testable with failure scenarios
- ✅ Production-ready error handling

STEP 2 can now proceed with:
- Real CameraService implementation
- Real LocationService implementation
- Real GeocodingService implementation
- Riverpod state management (handles return value)
- Error UI rendering (catches specific failures)
*/
