import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failures.dart';
import 'providers.dart';

class CaptureScreen extends ConsumerWidget {
  const CaptureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(captureNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera GPS Tracking'),
      ),
      body: _buildBody(context, ref, state),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, CaptureState state) {
    switch (state.phase) {
      case CapturePhase.ready:
        return _buildReadyScreen(context, ref, state);

      case CapturePhase.initializingCamera:
        return _buildLoadingScreen('Initializing camera...');

      case CapturePhase.previewReady:
        return _buildPreviewScreen(context, ref, state);

      case CapturePhase.capturingPhoto:
        return _buildLoadingScreen('Capturing photo & GPS...');

      case CapturePhase.processingData:
        return _buildLoadingScreen('Processing data...');

      case CapturePhase.complete:
        return _buildCompleteScreen(context, ref, state);
    }
  }

  /// Screen 1: Initial "Ready" state - user hasn't started yet
  Widget _buildReadyScreen(BuildContext context, WidgetRef ref, CaptureState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt, size: 64, color: Colors.blue),
          const SizedBox(height: 24),
          const Text(
            'Ready to capture',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Take a photo with GPS location and address',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => ref.read(captureNotifierProvider.notifier).initializeCamera(),
            icon: const Icon(Icons.camera),
            label: const Text('Start Capture'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          if (state.error != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    state.error!.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                  if (state.error!.type == FailureType.permissionDeniedForever) ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => ref.read(captureNotifierProvider.notifier).openAppSettings(),
                      icon: const Icon(Icons.settings),
                      label: const Text('Open App Settings'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Screen 2: Camera Preview - user sees live feed and can capture
  Widget _buildPreviewScreen(BuildContext context, WidgetRef ref, CaptureState state) {
    final controller = ref.watch(cameraServiceProvider).getController();

    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        // Camera preview (full screen)
        CameraPreview(controller),

        // Overlay: GPS info (top)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.5), Colors.transparent],
              ),
            ),
            child: const Text(
              'Position camera to frame shot, then tap Capture',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),

        // Capture button (bottom center)
        Positioned(
          bottom: 32,
          left: 0,
          right: 0,
          child: Center(
            child: ElevatedButton.icon(
              onPressed: () => ref.read(captureNotifierProvider.notifier).capturePhoto(),
              icon: const Icon(Icons.camera),
              label: const Text('Capture Photo'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),

        // Back button (top left) - allows user to cancel preview
        Positioned(
          top: 16,
          left: 16,
          child: FloatingActionButton.small(
            backgroundColor: Colors.black54,
            onPressed: () => ref.read(captureNotifierProvider.notifier).reset(),
            child: const Icon(Icons.arrow_back),
          ),
        ),

        // Error overlay (if any)
        if (state.error != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.red.shade900,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.error!.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref.read(captureNotifierProvider.notifier).capturePhoto(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Screen 3: Loading state
  Widget _buildLoadingScreen(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(message, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  /// Screen 4: Capture complete - show results
  Widget _buildCompleteScreen(BuildContext context, WidgetRef ref, CaptureState state) {
    final tracking = state.tracking;
    if (tracking == null) return _buildReadyScreen(context, ref, state);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 80),
          const SizedBox(height: 24),
          const Text(
            'Capture Successful!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildResultRow('ID', tracking.id),
                _buildResultRow('Address', tracking.address),
                _buildResultRow(
                  'Location',
                  '${tracking.latitude.toStringAsFixed(6)}, ${tracking.longitude.toStringAsFixed(6)}',
                ),
                _buildResultRow('Accuracy', '${tracking.accuracy.toStringAsFixed(2)} m'),
                _buildResultRow(
                  'Time',
                  tracking.timestamp.toLocal().toString().split('.')[0],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => ref.read(captureNotifierProvider.notifier).reset(),
            icon: const Icon(Icons.camera),
            label: const Text('Capture Again'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}