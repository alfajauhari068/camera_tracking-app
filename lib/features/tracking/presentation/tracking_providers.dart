import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../domain/entities/tracking.dart';
import '../domain/usecases/get_trackings.dart';
import 'providers.dart';

/// =============================================================================
/// TRACKING LIST PROVIDER (dengan enhanced error handling & debugging)
/// =============================================================================
/// Async provider yang mengambil semua tracking dari repository via GetTrackings use case
/// Tipe: FutureProvider<List<Tracking>>
///
/// Enhancement:
/// - Debug logging untuk setiap tahap loading
/// - Better error messages dengan stack trace
/// - Auto-invalidate recommendation
///
/// Usage:
/// ```dart
/// final trackingListAsync = ref.watch(trackingListProvider);
/// trackingListAsync.when(
///   loading: () => CircularProgressIndicator(),
///   error: (e, st) => ErrorWidget(error: e),
///   data: (trackings) => buildTrackingsList(trackings),
/// );
/// ```
final trackingListProvider = FutureProvider<List<Tracking>>((ref) async {
  try {
    print('[trackingListProvider] Starting to fetch trackings...');

    final repository = ref.watch(trackingRepositoryProvider);
    final useCase = GetTrackings(repository: repository);

    final trackings = await useCase.execute();

    print(
      '[trackingListProvider] ✅ Successfully loaded ${trackings.length} trackings',
    );

    return trackings;
  } catch (e, st) {
    print('[trackingListProvider] ❌ Error loading trackings: $e');
    print('[trackingListProvider] Stack trace: $st');
    rethrow;
  }
});

final userLocationProvider = FutureProvider<Position?>((ref) async {
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('[userLocationProvider] Location services disabled');
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      print('[userLocationProvider] Location permission denied');
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
    print('[userLocationProvider] Got user location: $position');
    return position;
  } catch (e) {
    print('[userLocationProvider] Error requesting location: $e');
    return null;
  }
});

/// =============================================================================
/// SELECTED TRACKING PROVIDER (for Map view)
/// =============================================================================
/// State provider untuk track Tracking yang sedang dipilih di peta
/// Tipe: StateProvider<SelectedTrackingState>
///
/// State ini digunakan untuk:
/// - Menyimpan tracking mana yang sedang dipilih di map
/// - Sync selection antara marker tap dan thumbnail tap
/// - Menampilkan detail lokasi yang dipilih
///
/// Usage:
/// ```dart
/// final selectedState = ref.watch(selectedTrackingProvider);
///
/// // Jika ada tracking yang dipilih
/// if (selectedState.tracking != null) {
///   print('Selected: ${selectedState.tracking!.address}');
/// }
///
/// // Update selection
/// ref.read(selectedTrackingProvider.notifier).selectTracking(tracking);
/// ref.read(selectedTrackingProvider.notifier).clearSelection();
/// ```
class SelectedTrackingState {
  final Tracking? tracking;

  const SelectedTrackingState({this.tracking});

  /// Copy with helper untuk immutability
  SelectedTrackingState copyWith({Tracking? tracking}) {
    return SelectedTrackingState(tracking: tracking);
  }
}

class SelectedTrackingNotifier extends StateNotifier<SelectedTrackingState> {
  SelectedTrackingNotifier() : super(const SelectedTrackingState());

  /// Select a tracking
  void selectTracking(Tracking tracking) {
    state = state.copyWith(tracking: tracking);
  }

  /// Clear selection
  void clearSelection() {
    state = const SelectedTrackingState();
  }
}

final selectedTrackingProvider =
    StateNotifierProvider<SelectedTrackingNotifier, SelectedTrackingState>(
      (ref) => SelectedTrackingNotifier(),
    );

/// =============================================================================
/// INVALIDATE HELPERS
/// =============================================================================
/// Gunakan untuk refresh tracking list setelah capture baru atau delete
/// 
/// Usage:
/// ```dart
/// // Setelah capture foto baru
/// ref.invalidate(trackingListProvider);
/// 
/// // Di capture screen setelah successful capture
/// ref.read(captureNotifierProvider.notifier).reset();
/// ref.invalidate(trackingListProvider);
/// ```
