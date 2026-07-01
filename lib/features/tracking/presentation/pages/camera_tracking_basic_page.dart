import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Basic camera tracking page.
///
/// Spec:
/// - Initialize back camera in initState
/// - Render CameraPreview only after controller Future completes (FutureBuilder)
/// - Dispose CameraController correctly
/// - Full screen dark background + CameraPreview with correct aspect ratio
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

    if (cameras.isEmpty) {
      throw CameraException('NoCamera', 'No camera devices found');
    }

    // Pilih kamera belakang sebagai default.
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

  /// Membangun preview kamera dengan rasio yang benar.
  ///
  /// Menggunakan Transform.scale untuk mengatasi perbedaan
  /// antara rasio layar (deviceAspect) dan rasio kamera (cameraAspect),
  /// sehingga preview tidak tampak 1:1 atau melebar aneh.
  Widget _buildCameraPreview(BuildContext context) {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator.adaptive(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    final size = MediaQuery.of(context).size;
    final cameraValue = controller.value;

    // Rasio layar (portrait): width / height.
    final deviceAspect = size.width / size.height;

    // Rasio kamera dari plugin (biasanya landscape).
    final cameraAspect =
        (cameraValue.aspectRatio > 0) ? cameraValue.aspectRatio : deviceAspect;

    // Hitung scale agar konten tidak distorsi tapi tetap mengisi area.
    // Referensi pola komunitas: Transform.scale dengan deviceAspect vs cameraAspect.
    // scale > 1 artinya sedikit "zoom in" agar tidak ada letterbox.
    var scale = deviceAspect / cameraAspect;
    if (scale < 1) {
      // Pastikan tidak mengecil; jika < 1, balik agar tetap cover.
      scale = 1 / scale;
    }

    return Transform.scale(
      scale: scale,
      alignment: Alignment.center,
      child: Center(
        child: AspectRatio(
          aspectRatio: cameraAspect,
          child: CameraPreview(controller),
        ),
      ),
    );
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

          if (snapshot.hasError ||
              _controller == null ||
              !_controller!.value.isInitialized) {
            return const Center(
              child: Text(
                'Failed to initialize camera',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            );
          }

          // Preview kamera dengan rasio yang dijaga agar tidak stretch.
          return _buildCameraPreview(context);
        },
      ),
    );
  }
}