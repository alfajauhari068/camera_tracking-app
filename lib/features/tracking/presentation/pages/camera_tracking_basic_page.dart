import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Basic camera tracking page.
///
/// Spec:
/// - Initialize back camera in initState
/// - Render CameraPreview only after controller Future completes (FutureBuilder)
/// - Dispose CameraController correctly
/// - Full screen dark background + CameraPreview
class CameraTrackingPage extends StatefulWidget {
  const CameraTrackingPage({super.key});

  @override
  State<CameraTrackingPage> createState() => _CameraTrackingPageState();
}

class _CameraTrackingPageState extends State<CameraTrackingPage> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();

    final backCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    _controller = controller;
    await controller.initialize();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator.adaptive(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            );
          }

          if (snapshot.hasError || _controller == null || !_controller!.value.isInitialized) {
            return const Center(
              child: Text(
                'Failed to initialize camera',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            );
          }

          final controller = _controller!;

          // Preserve aspect ratio to avoid stretched preview.
          return Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: Transform.scale(
                scale: 1.0,
                child: CameraPreview(controller),
              ),
            ),
          );
        },
      ),
    );
  }
}

