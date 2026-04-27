/*
# RESULT PATTERN & CONTROLLED ERROR FLOW - TESTING GUIDE

## 🔄 What Changed

**BEFORE** (Exception-based):
```dart
try {
  final tracking = await useCase.execute();
} on CameraFailure catch (e) {
  // handle error
}
```

**AFTER** (Result-based, controlled):
```dart
final result = await useCase.execute();
result.when(
  success: (tracking) {
    // handle success
  },
  failure: (error) {
    // handle error - typed and controlled
  },
);
```

---

## ✅ Benefits of Result Pattern

1. **Controlled Flow** - No exception unwinding
2. **State Management Ready** - Riverpod can handle Result directly
3. **Typed Errors** - Failure types are explicit
4. **No Silent Failures** - Must handle both cases
5. **Composable** - Can map/flatMap results easily

---

## 📝 Basic Usage

```dart
import 'package:camera_tracking_gps/features/tracking/domain/usecases/capture_tracking.dart';
import 'package:camera_tracking_gps/features/tracking/domain/fakes/fake_camera_service.dart';
import 'package:camera_tracking_gps/features/tracking/domain/fakes/fake_location_service.dart';
import 'package:camera_tracking_gps/features/tracking/domain/fakes/fake_geocoding_service.dart';
import 'package:camera_tracking_gps/features/tracking/domain/fakes/fake_tracking_repository.dart';
import 'package:camera_tracking_gps/features/tracking/domain/fakes/fake_id_generator.dart';
import 'package:camera_tracking_gps/features/tracking/domain/fakes/fake_time_provider.dart';

Future<void> main() async {
  final captureTracking = CaptureTracking(
    repository: FakeTrackingRepository(),
    cameraService: FakeCameraService(),
    locationService: FakeLocationService(),
    geocodingService: FakeGeocodingService(),
    idGenerator: FakeIdGenerator(),
    timeProvider: FakeTimeProvider(),
  );

  // Execute returns Result<Tracking>, not Future<Tracking>
  final result = await captureTracking.execute();

  // Pattern matching for both cases
  result.when(
    success: (tracking) {
      print('✅ Capture successful!');
      print('ID: ${tracking.id}');
      print('Location: (${tracking.latitude}, ${tracking.longitude})');
    },
    failure: (failure) {
      print('❌ Error: ${failure.message}');
      print('Type: ${failure.type}');
      print('Retryable: ${failure.type.isRetryable}');
    },
  );
}
```

---

## 🧪 Test Scenario 1: Success Path

```dart
Future<void> testSuccessfulCapture() async {
  final captureTracking = CaptureTracking(
    repository: FakeTrackingRepository(),
    cameraService: FakeCameraService(),
    locationService: FakeLocationService(),
    geocodingService: FakeGeocodingService(),
    idGenerator: FakeIdGenerator(),
    timeProvider: FakeTimeProvider(),
  );

  final result = await captureTracking.execute();

  // Use getOrNull() to extract data
  final tracking = result.getOrNull();
  assert(tracking != null, 'Should have tracking data');
  assert(tracking!.id.isNotEmpty);
  assert(tracking.imagePath.isNotEmpty);

  print('✅ Success test passed');
}
```

---

## 🧪 Test Scenario 2: Camera Failure

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
    timeProvider: FakeTimeProvider(),
  );

  final result = await captureTracking.execute();

  // Check if failure
  assert(result.isFailure, 'Should be failure');
  assert(result.isSuccess == false, 'Should not be success');

  // Extract error
  final error = result.getErrorOrNull();
  assert(error != null);
  assert(error! is CameraFailure);
  assert(error.message == 'Camera permission denied');
  assert(error.type == FailureType.camera);
  assert(error.type.isRetryable == true);

  print('✅ Camera failure test passed');
}
```

---

## 🧪 Test Scenario 3: Location Timeout

```dart
Future<void> testLocationTimeout() async {
  final captureTracking = CaptureTracking(
    repository: FakeTrackingRepository(),
    cameraService: FakeCameraService(),  // Succeeds
    locationService: FakeLocationService(
      shouldFail: true,
      failureMessage: 'GPS timeout after 30 seconds',
    ),
    geocodingService: FakeGeocodingService(),
    idGenerator: FakeIdGenerator(),
    timeProvider: FakeTimeProvider(),
  );

  final result = await captureTracking.execute();

  // Camera succeeded, but location failed
  result.when(
    success: (_) {
      throw AssertionError('Should not succeed');
    },
    failure: (error) {
      assert(error.type == FailureType.location);
      assert(error.type.isRetryable == true);
      print('✅ Location timeout properly handled');
    },
  );
}
```

---

## 🧪 Test Scenario 4: Geocoding API Failure

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
    timeProvider: FakeTimeProvider(),
  );

  final result = await captureTracking.execute();

  result.when(
    success: (_) {
      throw AssertionError('Should not succeed');
    },
    failure: (error) {
      assert(error.type == FailureType.geocoding);
      // Geocoding failures ARE retryable
      assert(error.type.isRetryable == true);
    },
  );

  print('✅ Geocoding failure test passed');
}
```

---

## 🧪 Test Scenario 5: Deterministic Time

```dart
Future<void> testDeterministicTime() async {
  final timeProvider = FakeTimeProvider();
  final now = DateTime(2026, 6, 15, 14, 30, 45);
  timeProvider.setFixedTime(now);

  final captureTracking = CaptureTracking(
    repository: FakeTrackingRepository(),
    cameraService: FakeCameraService(),
    locationService: FakeLocationService(),
    geocodingService: FakeGeocodingService(),
    idGenerator: FakeIdGenerator(),
    timeProvider: timeProvider,
  );

  final result = await captureTracking.execute();
  final tracking = result.getOrNull();

  // Timestamp should be exactly the fixed time
  assert(tracking!.timestamp == now);
  print('✅ Time determinism test passed');
}
```

---

## 🧪 Test Scenario 6: Time Advancement

```dart
Future<void> testTimeAdvancement() async {
  final timeProvider = FakeTimeProvider();
  final idGen = FakeIdGenerator();

  // First capture
  final use1 = CaptureTracking(
    repository: FakeTrackingRepository(),
    cameraService: FakeCameraService(),
    locationService: FakeLocationService(),
    geocodingService: FakeGeocodingService(),
    idGenerator: idGen,
    timeProvider: timeProvider,
  );

  final result1 = await use1.execute();
  final tracking1 = result1.getOrNull()!;
  final time1 = tracking1.timestamp;

  // Advance time
  timeProvider.advanceBy(Duration(hours: 1));

  // Second capture
  final use2 = CaptureTracking(
    repository: FakeTrackingRepository(),
    cameraService: FakeCameraService(),
    locationService: FakeLocationService(),
    geocodingService: FakeGeocodingService(),
    idGenerator: idGen,
    timeProvider: timeProvider,
  );

  final result2 = await use2.execute();
  final tracking2 = result2.getOrNull()!;
  final time2 = tracking2.timestamp;

  // Should be 1 hour apart
  assert(time2.difference(time1).inHours == 1);
  print('✅ Time advancement test passed');
}
```

---

## 📊 Result Pattern API

```dart
// Check status
result.isSuccess    // true if success
result.isFailure    // true if failure

// Extract data safely
tracking = result.getOrNull()         // T? (null if failure)
error = result.getErrorOrNull()       // Failure? (null if success)

// Pattern matching
result.when(
  success: (data) { },     // Guaranteed T (not null)
  failure: (error) { },    // Guaranteed Failure (not null)
);

// Future: mapping
// result.map((t) => t.someField)
// result.flatMap((t) => someOtherUseCase.execute())
```

---

## 🔑 Key Improvements from Exception-Based

| Aspect | Exception-Based | Result-Based |
|--------|-----------------|--------------|
| Error Flow | Exception unwinding | Controlled return |
| Type Safety | Runtime exceptions | Compile-time failures |
| State Management | Messy error handling | Clean when/match |
| Testability | Try/catch everywhere | Explicit result handling |
| Performance | Stack unwinding | No exceptions thrown |
| Composability | Limited | Easy map/flatMap |

---

## ✅ Ready for STEP 2: State Management

Result pattern makes Riverpod integration clean:

```dart
final captureProvider = FutureProvider<Result<Tracking>>((ref) async {
  final useCase = ref.watch(captureTrackingProvider);
  return useCase.execute();  // Returns Result<Tracking>
});

// In UI:
ref.watch(captureProvider).when(
  data: (result) {
    return result.when(
      success: (tracking) => SuccessWidget(tracking),
      failure: (error) => ErrorWidget(error),
    );
  },
  loading: () => LoadingWidget(),
  error: (error, stack) => ErrorWidget(Failure(error.toString())),
);
```

Clean, typed, and composable! ✅
*/
