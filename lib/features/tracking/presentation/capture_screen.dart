import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failures.dart';
import 'providers.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize camera on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cameraControllerProvider.notifier).initializeCamera();
    });
  }

  @override
  void dispose() {
    // TEMP: Comment dispose to test lifecycle stability
    // If preview becomes stable, this is the root cause
    // ref.read(cameraControllerProvider.notifier).disposeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraControllerProvider);
    final captureState = ref.watch(captureNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera GPS Tracking'),
      ),
      body: Stack(
        children: [
          // =====================================================================
          // CAMERA PREVIEW (Main Content)
          // =====================================================================
          if (cameraState.isInitialized) ...[
            CameraPreview(cameraState.controller!),
            // Overlay with capture button
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  children: [
                    // Status text
                    if (captureState.isLoading)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Capturing...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    // Capture button
                    GestureDetector(
                      onTap: captureState.isLoading
                          ? null
                          : () => ref.read(captureNotifierProvider.notifier).capture(),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: captureState.isLoading
                              ? Colors.grey
                              : Colors.red,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                        ),
                        child: captureState.isLoading
                            ? const CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 40,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]
          // =====================================================================
          // LOADING STATE
          // =====================================================================
          else if (cameraState.isInitializing) ...[
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing camera...'),
                ],
              ),
            ),
          ]
          // =====================================================================
          // ERROR STATE
          // =====================================================================
          else if (cameraState.error != null) ...[
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    cameraState.error!.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  if (cameraState.error!.type ==
                      FailureType.permissionDeniedForever)
                    ElevatedButton.icon(
                      onPressed: () =>
                          ref.read(captureNotifierProvider.notifier).openAppSettings(),
                      icon: const Icon(Icons.settings),
                      label: const Text('Open App Settings'),
                    )
                  else
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(cameraControllerProvider.notifier).initializeCamera(),
                      child: const Text('Retry'),
                    ),
                ],
              ),
            ),
          ]
          // =====================================================================
          // SUCCESS OVERLAY
          // =====================================================================
          else if (captureState.tracking != null) ...[
            // Semi-transparent overlay
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'Capture Successful!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ID: ${captureState.tracking!.id}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      'Location: ${captureState.tracking!.latitude.toStringAsFixed(6)}, ${captureState.tracking!.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(captureNotifierProvider.notifier).reset(),
                      child: const Text('Capture Again'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          // =====================================================================
          // CAPTURE ERROR OVERLAY
          // =====================================================================
          if (captureState.error != null && captureState.tracking == null) ...[
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black87,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        captureState.error!.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (captureState.error!.type ==
                          FailureType.permissionDeniedForever)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => ref
                                    .read(captureNotifierProvider.notifier)
                                    .openAppSettings(),
                                icon: const Icon(Icons.settings),
                                label: const Text('Open App Settings'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 48),
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: () => ref
                                    .read(captureNotifierProvider.notifier)
                                    .capture(),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 48),
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      else if (captureState.error!.type.isRetryable)
                        ElevatedButton(
                          onPressed: () =>
                              ref.read(captureNotifierProvider.notifier).capture(),
                          child: const Text('Retry'),
                        )
                      else
                        ElevatedButton(
                          onPressed: () =>
                              ref.read(captureNotifierProvider.notifier).reset(),
                          child: const Text('Back'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}