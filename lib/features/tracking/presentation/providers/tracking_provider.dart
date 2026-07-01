import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/tracking.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../../domain/usecases/capture_tracking.dart';
import '../providers.dart';

/// UI state for tracking list and capture operations.
class TrackingLogState {
  final List<Tracking> trackings;
  final bool isLoading;
  final bool isProcessing;
  final String? errorMessage;

  const TrackingLogState({
    this.trackings = const [],
    this.isLoading = false,
    this.isProcessing = false,
    this.errorMessage,
  });

  TrackingLogState copyWith({
    List<Tracking>? trackings,
    bool? isLoading,
    bool? isProcessing,
    String? errorMessage,
  }) {
    return TrackingLogState(
      trackings: trackings ?? this.trackings,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: errorMessage,
    );
  }
}

class TrackingLogNotifier extends StateNotifier<TrackingLogState> {
  final CaptureTracking _captureTracking;
  final TrackingRepository _repository;

  TrackingLogNotifier(
    this._captureTracking,
    this._repository,
  ) : super(const TrackingLogState()) {
    loadTrackings();
  }

  Future<void> loadTrackings() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final trackings = await _repository.getAllTracking();
      state = state.copyWith(
        trackings: trackings,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat data tracking: $e',
      );
    }
  }

  Future<void> refreshTrackings() async {
    await loadTrackings();
  }

  Future<void> captureAndSave() async {
    if (state.isProcessing) {
      return;
    }

    state = state.copyWith(isProcessing: true, errorMessage: null);

    try {
      final result = await _captureTracking.execute();
      result.when(
        success: (tracking) {
          final updatedList = [tracking, ...state.trackings];
          state = state.copyWith(
            trackings: updatedList,
            isProcessing: false,
            errorMessage: null,
          );
        },
        failure: (failure) {
          state = state.copyWith(
            isProcessing: false,
            errorMessage: failure.message,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Gagal melakukan capture: $e',
      );
    }
  }

  Future<void> deleteLogItem(String id) async {
    state = state.copyWith(isProcessing: true, errorMessage: null);

    try {
      await _repository.deleteTracking(id);
      final updatedList = state.trackings.where((item) => item.id != id).toList();
      state = state.copyWith(
        trackings: updatedList,
        isProcessing: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Gagal menghapus item: $e',
      );
    }
  }
}

final trackingLogNotifierProvider = StateNotifierProvider<TrackingLogNotifier, TrackingLogState>(
  (ref) => TrackingLogNotifier(
    ref.watch(captureTrackingProvider),
    ref.watch(trackingRepositoryProvider),
  ),
);
