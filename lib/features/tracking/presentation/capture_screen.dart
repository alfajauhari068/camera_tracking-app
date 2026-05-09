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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (state.isLoading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Capturing...'),
            ] else if (state.error != null) ...[
              const Icon(Icons.error, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                state.error!.message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              // Show buttons based on error type
              if (state.error!.type == FailureType.permissionDeniedForever)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => ref.read(captureNotifierProvider.notifier).openAppSettings(),
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
                        onPressed: () => ref.read(captureNotifierProvider.notifier).capture(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else if (state.error!.type.isRetryable)
                ElevatedButton(
                  onPressed: () => ref.read(captureNotifierProvider.notifier).capture(),
                  child: const Text('Retry'),
                )
              else
                // Non-retryable error
                ElevatedButton(
                  onPressed: () => ref.read(captureNotifierProvider.notifier).reset(),
                  child: const Text('Back'),
                ),
            ] else if (state.tracking != null) ...[
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              const Text('Capture Successful!'),
              const SizedBox(height: 8),
              Text('ID: ${state.tracking!.id}'),
              Text('Location: ${state.tracking!.latitude.toStringAsFixed(6)}, ${state.tracking!.longitude.toStringAsFixed(6)}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(captureNotifierProvider.notifier).reset(),
                child: const Text('Capture Again'),
              ),
            ] else ...[
              const Text('Ready to capture'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(captureNotifierProvider.notifier).capture(),
                child: const Text('Start Capture'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}