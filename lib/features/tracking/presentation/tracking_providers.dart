import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/tracking.dart';
import '../domain/usecases/get_trackings.dart';
import 'providers.dart';

/// =============================================================================
/// TRACKING LIST PROVIDER
/// =============================================================================
/// Async provider yang mengambil semua tracking dari repository via GetTrackings use case
/// Tipe: FutureProvider<List<Tracking>>
/// 
/// Usage:
/// ```dart
/// final trackingListAsync = ref.watch(trackingListProvider);
/// trackingListAsync.when(
///   loading: () => CircularProgressIndicator(),
///   error: (e, st) => ErrorWidget(),
///   data: (trackings) => buildTrackingsList(trackings),
/// );
/// ```
final trackingListProvider = FutureProvider<List<Tracking>>((ref) async {
  final repository = ref.watch(trackingRepositoryProvider);
  final useCase = GetTrackings(repository: repository);
  return await useCase.execute();
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

final selectedTrackingProvider = StateNotifierProvider<SelectedTrackingNotifier, SelectedTrackingState>(
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
