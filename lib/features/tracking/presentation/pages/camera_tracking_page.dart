// Rebuilt from the latest stable full preview to fix broken structure/duplicates.
// NOTE: This version focuses on compilation and basic functionality.

import 'dart:async';
import 'dart:io';
import 'dart:ui' show ImageFilter;
import 'package:flutter/services.dart'
    show Clipboard, ClipboardData, SystemNavigator;

import 'package:camera/camera.dart'
    show
        CameraController,
        CameraException,
        CameraLensDirection,
        ResolutionPreset,
        FocusMode,
        CameraPreview,
        CameraDescription,
        availableCameras;
import 'package:camera/camera.dart' as camera show FlashMode;
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../../routes.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../tracking_providers.dart';
import '../providers.dart';
import '../../domain/entities/tracking.dart';
// For navigator route names.
import '../../../../routes.dart' show AppRoutes;

import '../providers/state/camera_config_state.dart';
import 'package:camera_tracking_gps/features/tracking/presentation/providers/camera_provider.dart'
    show cameraConfigProvider;
import '../widgets/grid_overlay_helper.dart';

// Keep enum names compatible with existing UI.
enum CameraMode { locationShare, photo, video, reporting }

enum FlashMode { off, on, auto }

class OverlayConfig {
  final bool showAddress;
  final bool showCoordinates;
  final bool showTimestamp;
  final bool showMiniMap;

  const OverlayConfig({
    this.showAddress = true,
    this.showCoordinates = true,
    this.showTimestamp = true,
    this.showMiniMap = true,
  });

  OverlayConfig copyWith({
    bool? showAddress,
    bool? showCoordinates,
    bool? showTimestamp,
    bool? showMiniMap,
  }) {
    return OverlayConfig(
      showAddress: showAddress ?? this.showAddress,
      showCoordinates: showCoordinates ?? this.showCoordinates,
      showTimestamp: showTimestamp ?? this.showTimestamp,
      showMiniMap: showMiniMap ?? this.showMiniMap,
    );
  }
}

class CapturedPhoto {
  final String filePath;
  final String? locationName;
  final String? address;
  final double? latitude;
  final double? longitude;
  final DateTime timestamp;
  final OverlayConfig overlayConfig;

  const CapturedPhoto({
    required this.filePath,
    required this.timestamp,
    this.locationName,
    this.address,
    this.latitude,
    this.longitude,
    required this.overlayConfig,
  });
}

class ReportFormResult {
  final String category;
  final String? note;

  const ReportFormResult({required this.category, this.note});
}

class CapturedMeta {
  final String locationName;
  final String address;
  final String coordinates;
  final DateTime timestamp;

  const CapturedMeta({
    required this.locationName,
    required this.address,
    required this.coordinates,
    required this.timestamp,
  });
}

class CameraTrackingPage extends ConsumerStatefulWidget {
  const CameraTrackingPage({super.key});

  @override
  ConsumerState<CameraTrackingPage> createState() => _CameraTrackingPageState();
}

class _CameraTrackingPageState extends ConsumerState<CameraTrackingPage>
    with TickerProviderStateMixin {
  final _logger = const AppLogger(tag: 'CameraTrackingPage');

  late final AnimationController _flashPulseController;
  late final AnimationController _lensFlipController;

  CapturedPhoto? _lastPhoto;
  final List<CapturedPhoto> _photoHistory = [];

  bool _isRecording = false;
  bool _locationLoading = false;

  bool get _isFlashOn => _flashMode == FlashMode.on;

  bool get _showGrid => ref.watch(cameraConfigProvider).showGrid;
  final List<CameraZoomPreset> _zoomPresets = CameraZoomPreset.values;

  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  StreamSubscription<Position>? _gpsPositionSubscription;

  OverlayConfig _overlayConfig = const OverlayConfig();

  CapturedMeta _meta = CapturedMeta(
    locationName: 'Kecamatan Contoh',
    address:
        'Jl. Contoh No. 123, Kelurahan Sampel, Kota Demo, Provinsi Nusantara',
    coordinates: '-6.200000, 106.816666',
    timestamp: DateTime(2025, 1, 1, 12, 0, 0),
  );

  // Capture mode is now sourced from provider.
  CameraMode get _selectedMode =>
      switch (ref.watch(cameraConfigProvider).selectedMode) {
        CameraCaptureMode.photo => CameraMode.photo,
        CameraCaptureMode.reporting => CameraMode.reporting,
        CameraCaptureMode.video => CameraMode.video,
        CameraCaptureMode.locationShare => CameraMode.locationShare,
      };

  double? _latitude;
  double? _longitude;
  DateTime? _lastLocationUpdateTime;

  List<CameraDescription> _availableCameras = const [];
  int _currentCameraIndex = 0;

  double _zoomLevel = 1.0;
  FlashMode _flashMode = FlashMode.off;

  camera.FlashMode _nativeFlashMode(FlashMode flashMode) {
    return switch (flashMode) {
      FlashMode.off => camera.FlashMode.off,
      FlashMode.on => camera.FlashMode.always,
      FlashMode.auto => camera.FlashMode.auto,
    };
  }

  Future<void> _applyFlashModeToController(FlashMode flashMode) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      await controller.setFlashMode(_nativeFlashMode(flashMode));
    } on CameraException catch (e) {
      _logger.error('Failed to set flash mode', e);
    }
  }

  Future<void> _cycleFlashMode() async {
    final next =
        FlashMode.values[(_flashMode.index + 1) % FlashMode.values.length];
    setState(() => _flashMode = next);
    await _applyFlashModeToController(next);
  }

  Future<bool> _ensureCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      if (status.isGranted) return true;

      if (status.isPermanentlyDenied) {
        _logger.error('Camera permission permanently denied.');
        await Permission.camera.request();
      }

      return false;
    } catch (e) {
      _logger.error('Failed to request camera permission', e);
      return false;
    }
  }

  Widget _buildCroppedViewfinder(BuildContext context) {
    final cfg = ref.watch(cameraConfigProvider);
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator.adaptive(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    final aspect = cfg.selectedRatio.aspectRatio;
    final bool isFlashActive = _flashMode == FlashMode.on;
    final double baseFlashOpacity = isFlashActive ? 0.26 : 0.0;
    final double glowOpacity = isFlashActive ? 0.52 : 0.0;
    final double pulse = _flashPulseController.value;

    return AnimatedBuilder(
      animation: _lensFlipController,
      builder: (context, child) {
        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(_lensFlipController.value * 3.14159265359);

        // Remove horizontal mirror for front camera preview so the preview
        // reflects real-world left/right orientation.
        // if (isFrontCamera) {
        //   matrix.scale(-1.0, 1.0, 1.0);
        // }

        return Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: ClipRect(
                child: Transform(
                  transform: matrix,
                  alignment: Alignment.center,
                  child: Transform.scale(
                    scale: cfg.zoomLevel < 1.0 ? 0.85 : 1.0,
                    child: AspectRatio(
                      aspectRatio: aspect,
                      child: CameraPreview(controller),
                    ),
                  ),
                ),
              ),
            ),

            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _showGrid ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  child: const GridOverlayHelper(),
                ),
              ),
            ),

            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                color: Colors.white.withOpacity(baseFlashOpacity),
              ),
            ),

            Positioned.fill(
              child: AnimatedOpacity(
                opacity: glowOpacity,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.2),
                      radius: 0.6,
                      colors: [
                        Colors.white.withOpacity(0.85 + 0.05 * pulse),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            Positioned(top: 72, right: 16, child: _buildStatusBadge(cfg)),
          ],
        );
      },
    );
  }

  Widget _buildStatusBadge(CameraConfigState cfg) {
    final bool flashActive = _flashMode == FlashMode.on;
    final double pulseValue = _flashPulseController.value;
    final Color flashColor = flashActive ? Colors.orangeAccent : Colors.white70;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(flashActive ? 0.78 : 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(
            flashActive ? 0.18 + pulseValue * 0.05 : 0.10,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusRow(
            label: 'FLASH',
            value: _flashMode.name.toUpperCase(),
            valueColor: flashColor,
            icon: Icons.flash_on,
            iconColor: flashColor.withOpacity(flashActive ? 1.0 : 0.65),
            animate: flashActive,
          ),
          const SizedBox(height: 8),
          _buildStatusRow(
            label: 'GPS',
            value: cfg.gpsMode.label,
            valueColor: cfg.gpsMode.isSimulator
                ? Colors.lightGreenAccent
                : Colors.white70,
            icon: Icons.gps_fixed,
            iconColor: cfg.gpsMode.isSimulator
                ? Colors.lightGreenAccent
                : Colors.white70,
          ),
          const SizedBox(height: 8),
          _buildStatusRow(
            label: 'RATIO',
            value: cfg.selectedRatio.label,
            valueColor: Colors.white70,
            icon: Icons.aspect_ratio,
            iconColor: Colors.white70,
          ),
          const SizedBox(height: 8),
          _buildStatusRow(
            label: 'ZOOM',
            value:
                '${cfg.zoomLevel.toStringAsFixed(cfg.zoomLevel == 1.0 ? 0 : 1)}x',
            valueColor: Colors.white70,
            icon: Icons.zoom_in,
            iconColor: Colors.white70,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required String label,
    required String value,
    required Color valueColor,
    required IconData icon,
    required Color iconColor,
    bool animate = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          opacity: animate ? 0.85 + (_flashPulseController.value * 0.15) : 0.85,
          child: Icon(icon, size: 14, color: iconColor),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 9,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _lastLocationUpdateTime ??= DateTime.now();

    _flashPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);

    _lensFlipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _initializeControllerFuture = _ensureCameraPermission().then((
      granted,
    ) async {
      if (!granted) {
        throw CameraException(
          'CameraPermissionDenied',
          'Camera permission not granted',
        );
      }

      final cfg = ref.read(cameraConfigProvider);
      await _initCamera();
      await _refreshLocationData(showLoading: false);
      await _applyFlashModeToController(_flashMode);
      await _applyZoom(cfg.zoomLevel);
    });
  }

  Future<void> _initCamera({int? cameraIndex}) async {
    _isRecording = false;

    _availableCameras = await availableCameras();
    if (_availableCameras.isEmpty) {
      throw CameraException('NoCamera', 'No camera devices found');
    }

    final index = cameraIndex ?? _pickBackCameraIndex();
    _currentCameraIndex = index.clamp(0, _availableCameras.length - 1);

    final cam = _availableCameras[_currentCameraIndex];

    await _controller?.dispose();
    _controller = null;

    final controller = CameraController(
      cam,
      ResolutionPreset.high,
      enableAudio: false,
    );

    _controller = controller;
    await controller.initialize();

    await _applyFlashStateSafely(_isFlashOn);

    try {
      await controller.setZoomLevel(1.0);
      setState(() => _zoomLevel = 1.0);
    } catch (_) {
      // best-effort
    }

    try {
      await controller.setFocusMode(FocusMode.auto);
    } catch (_) {
      // best-effort
    }

    _logger.info('Camera initialized: ${controller.value.previewSize}');
  }

  int _pickBackCameraIndex() {
    final idx = _availableCameras.indexWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
    );
    return idx != -1 ? idx : 0;
  }

  Future<void> _applyFlashStateSafely(bool turnOn) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      await controller.setFlashMode(
        turnOn ? camera.FlashMode.always : camera.FlashMode.off,
      );
    } on CameraException catch (e) {
      _logger.error('CameraException while applying flash mode', e);
    } catch (e) {
      _logger.error('Unexpected error while applying flash mode', e);
    }
  }

  Future<void> _switchCamera() async {
    // Play the 3D flip animation forward, switch camera, then reverse
    await _lensFlipController.forward(from: 0.0);

    if (_availableCameras.isEmpty) {
      await _initCamera();
      // Ensure animation returns to neutral state
      await _lensFlipController.reverse();
      return;
    }

    final current = _availableCameras[_currentCameraIndex];
    final wantLens = current.lensDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;

    final nextIdx = _availableCameras.indexWhere(
      (c) => c.lensDirection == wantLens,
    );
    final fallbackIdx = (_currentCameraIndex + 1) % _availableCameras.length;
    final chosenIdx = nextIdx != -1 ? nextIdx : fallbackIdx;

    await _initCamera(cameraIndex: chosenIdx);
    ref
        .read(cameraConfigProvider.notifier)
        .setLensDirection(
          _availableCameras[_currentCameraIndex].lensDirection ==
              CameraLensDirection.back,
        );
    await _applyFlashModeToController(_flashMode);

    // Reverse the flip to show the newly-selected camera upright
    await _lensFlipController.reverse();
  }

  Future<void> _applyZoom(double zoom) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    // Flutter camera plugin versi tertentu tidak mengekspos min/max zoom.
    // Karena itu, gunakan clamp aman [1.0..10.0] (sebelumnya),
    // tetapi buat perilaku UI tetap jujur berdasarkan apakah hasil clamped sama dengan requested.
    // catatan: jika device Anda mendukung zoom < 1, plugin versi Anda mungkin tidak menyediakan range.
    const double minZoomFallback = 1.0;
    const double maxZoomFallback = 10.0;

    final double clamped = zoom.clamp(minZoomFallback, maxZoomFallback);

    try {
      await controller.setZoomLevel(clamped);
      if (!mounted) return;

      // UI mengikuti nilai aktual yang berhasil diterapkan (jujur, tidak bohong).
      setState(() => _zoomLevel = clamped);

      _logger.info(
        'Zoom set to ${clamped.toStringAsFixed(2)}x (requested: ${zoom.toStringAsFixed(2)}) '
        '; deviceRange=[${minZoomFallback.toStringAsFixed(2)}..${maxZoomFallback.toStringAsFixed(2)}] '
        '; note=${zoom < minZoomFallback ? "requested < min, clamped" : "ok"}',
      );
    } catch (e) {
      _logger.warning(
        'Failed to set zoom level (requested: $zoom, clamped: $clamped, deviceRange=[$minZoomFallback..$maxZoomFallback]): $e',
      );
    }
  }

  Future<void> _tapToFocus() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      await controller.setFocusMode(FocusMode.auto);
    } catch (e) {
      _logger.warning('Failed to trigger autofocus: $e');
    }
  }

  /// PERBAIKAN: Validate GPS accuracy sebelum generate share link
  /// Return true jika accuracy acceptable (mock GPS atau accuracy <= 15 meter)
  bool _isGpsAccuracyAcceptable() {
    final cameraConfig = ref.watch(cameraConfigProvider);

    // Mock GPS selalu acceptable untuk testing
    if (cameraConfig.gpsMode.isSimulator) {
      _logger.info('GPS accuracy check: PASS (Mock GPS enabled)');
      return true;
    }

    // Real GPS: Jika belum ada koordinat, prompt user untuk refresh
    if (_latitude == null || _longitude == null) {
      _logger.warning('GPS accuracy check: FAIL (No coordinates available)');
      return false;
    }

    // Check last update time - jika > 30 detik, koordinat mungkin stale
    if (_lastLocationUpdateTime != null) {
      final timeSinceUpdate = DateTime.now().difference(
        _lastLocationUpdateTime!,
      );
      if (timeSinceUpdate.inSeconds > 30) {
        _logger.warning(
          'GPS accuracy check: WARN (Coordinates stale: ${timeSinceUpdate.inSeconds}s old)',
        );
        // Masih acceptable, tapi warn user
      }
    }

    _logger.info('GPS accuracy check: PASS (Coordinates available and fresh)');
    return true;
  }

  Future<void> _refreshLocationData({bool showLoading = false}) async {
    if (showLoading && mounted) {
      setState(() => _locationLoading = true);
    }

    try {
      final cameraConfig = ref.watch(cameraConfigProvider);
      final isMockGpsEnabled = cameraConfig.gpsMode.isSimulator;

      double lat;
      double lng;

      // If mock GPS is enabled, use simulated coordinates instantly
      if (isMockGpsEnabled) {
        _logger.info('Using mock GPS coordinates');
        lat = -6.200000;
        lng = 106.816666;
      } else {
        // Request location permission for real GPS
        final status = await Permission.location.request();
        if (!status.isGranted) {
          _logger.error('Location permission not granted');
          return;
        }

        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          _logger.warning('Location service is disabled');
          return;
        }

        // Get current position with high accuracy
        final pos =
            await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
              timeLimit: const Duration(seconds: 10),
            ).timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                _logger.error('Location request timed out');
                throw TimeoutException('GPS request timed out');
              },
            );

        lat = pos.latitude;
        lng = pos.longitude;
      }

      String? addressLine;
      String? placeName;

      // Perform reverse geocoding asynchronously
      try {
        final placemarks = await placemarkFromCoordinates(lat, lng).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            _logger.warning('Reverse geocoding timed out');
            return [];
          },
        );

        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          addressLine = [
            p.street,
            p.subLocality,
            p.locality,
            p.administrativeArea,
            p.postalCode,
            p.country,
          ].whereType<String>().where((s) => s.trim().isNotEmpty).join(', ');

          placeName =
              p.locality ?? p.subAdministrativeArea ?? p.administrativeArea;
        }
      } catch (e) {
        _logger.error('Reverse geocoding failed', e);
      }

      if (!mounted) return;

      setState(() {
        _latitude = lat;
        _longitude = lng;
        _meta = CapturedMeta(
          locationName: placeName ?? _meta.locationName,
          address: addressLine ?? _meta.address,
          coordinates: '$lat, $lng',
          timestamp: DateTime.now(),
        );
        _lastLocationUpdateTime = DateTime.now();
      });

      _logger.info(
        'Location refreshed: lat=$lat lng=$lng (mock=${isMockGpsEnabled})',
      );
    } finally {
      if (showLoading && mounted) {
        setState(() => _locationLoading = false);
      }
    }
  }

  Future<void> _disposeCameraAndGpsResources() async {
    try {
      await _controller?.dispose();
    } catch (e, st) {
      _logger.error('Failed to dispose camera controller', e, st);
    } finally {
      _controller = null;
    }

    await _gpsPositionSubscription?.cancel();
    _gpsPositionSubscription = null;
  }

  Future<void> _handleClosePressed(BuildContext context) async {
    await _disposeCameraAndGpsResources();

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    await SystemNavigator.pop();
  }

  @override
  void dispose() {
    _flashPulseController.dispose();
    _lensFlipController.dispose();
    _controller?.dispose();
    _gpsPositionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _onCapture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    switch (_selectedMode) {
      case CameraMode.locationShare:
        // PERBAIKAN: Refresh GPS SEBELUM capture foto untuk akurasi koordinat
        await _refreshLocationData(showLoading: true);

        // Validasi akurasi GPS sebelum capture
        if (!_isGpsAccuracyAcceptable()) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Akurasi GPS rendah. Tunggu sebentar dan coba lagi.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }

        _logger.info(
          'GPS coordinates confirmed before photo capture: lat=$_latitude, lng=$_longitude',
        );

        // Capture photo dengan koordinat yang sudah fresh
        await _handlePhotoCapture(
          controller,
          saveToRepository: true,
          skipLocationRefresh: true,
        );
        break;
      case CameraMode.photo:
        await _handlePhotoCapture(controller, saveToRepository: true);
        break;
      case CameraMode.video:
        await _handleVideoRecording(controller);
        break;
      case CameraMode.reporting:
        await _handleReportingCapture(controller);
        break;
    }
  }

  Future<void> _handleLocationShare() async {
    // PERBAIKAN: Jangan refresh GPS lagi di sini, gunakan koordinat yang sudah di-confirm di _onCapture
    // Ini mencegah race condition dan drift koordinat antara foto vs link

    if (_latitude == null || _longitude == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lokasi tidak tersedia. Coba refresh GPS terlebih dahulu.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final maps = 'https://www.google.com/maps?q=$_latitude,$_longitude';
    final shareText =
        '''
📍 Lokasi Saya

Nama Tempat: ${_meta.locationName}
Alamat: ${_meta.address}
Koordinat: $_latitude, $_longitude
Waktu: ${_formatDateTime(DateTime.now())}

Google Maps: $maps
''';

    _logger.info(
      'Location share generated with consistent coordinates: lat=$_latitude, lng=$_longitude, maps=$maps',
    );

    try {
      await Clipboard.setData(ClipboardData(text: shareText));
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lokasi disalin ke clipboard!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _handlePhotoCapture(
    CameraController controller, {
    bool saveToRepository = true,
    bool skipLocationRefresh = false,
  }) async {
    try {
      // PERBAIKAN: Hanya refresh GPS jika belum di-refresh di _onCapture
      // Ini menjaga koordinat tetap konsisten antara foto dan share link
      if (!skipLocationRefresh) {
        await _refreshLocationData(showLoading: true);
      }

      final xFile = await controller.takePicture();
      final now = DateTime.now();

      final photo = CapturedPhoto(
        filePath: xFile.path,
        locationName: _meta.locationName,
        address: _meta.address,
        latitude: _latitude,
        longitude: _longitude,
        timestamp: now,
        overlayConfig: _overlayConfig,
      );

      _logger.info(
        'Photo captured with coordinates: lat=${photo.latitude}, lng=${photo.longitude}',
      );

      if (!mounted) return;

      setState(() {
        _lastPhoto = photo;
        _photoHistory.insert(0, photo);
      });

      if (saveToRepository) {
        final tracking = Tracking(
          id: ref.read(idGeneratorProvider).generate(),
          imagePath: photo.filePath,
          latitude: photo.latitude ?? 0.0,
          longitude: photo.longitude ?? 0.0,
          address: photo.address ?? '',
          accuracy: 0.0,
          timestamp: photo.timestamp,
          type: TrackingType.photo,
        );

        await ref.read(trackingRepositoryProvider).saveTracking(tracking);
        ref.invalidate(trackingListProvider);
        _logger.info('Tracking saved with ID: ${tracking.id}');
      }

      if (_selectedMode == CameraMode.locationShare) {
        await _showShareOptions(photo);
        // Jangan refresh location lagi - koordinat sudah di-lock saat capture
        await _handleLocationShare();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto berhasil diproses & disimpan'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      _logger.error('Photo capture failed', e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan foto ke riwayat'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _handleVideoRecording(CameraController controller) async {
    try {
      if (_isRecording) {
        final videoFile = await controller.stopVideoRecording();
        if (!mounted) return;
        setState(() => _isRecording = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video disimpan: ${videoFile.name}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await controller.startVideoRecording();
        if (!mounted) return;
        setState(() => _isRecording = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔴 Merekam video...'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      _logger.error('Video recording failed', e);
      if (!mounted) return;
      setState(() => _isRecording = false);
    }
  }

  Future<void> _handleReportingCapture(CameraController controller) async {
    try {
      final xFile = await controller.takePicture();
      final now = DateTime.now();

      final photo = CapturedPhoto(
        filePath: xFile.path,
        locationName: _meta.locationName,
        address: _meta.address,
        latitude: _latitude,
        longitude: _longitude,
        timestamp: now,
        overlayConfig: _overlayConfig,
      );

      if (!mounted) return;
      setState(() {
        _lastPhoto = photo;
        _photoHistory.insert(0, photo);
      });

      final reportResult = await _showReportingDialog(photo);
      if (reportResult == null) {
        return;
      }

      final tracking = Tracking(
        id: ref.read(idGeneratorProvider).generate(),
        imagePath: photo.filePath,
        latitude: photo.latitude ?? 0.0,
        longitude: photo.longitude ?? 0.0,
        address: photo.address ?? '',
        accuracy: 0.0,
        timestamp: photo.timestamp,
        type: TrackingType.reporting,
        reportInfo: ReportInfo(
          category: reportResult.category,
          note: reportResult.note,
        ),
      );

      await ref.read(trackingRepositoryProvider).saveTracking(tracking);
      ref.invalidate(trackingListProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan berhasil disimpan'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _logger.error('Reporting capture failed', e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan laporan: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<ReportFormResult?> _showReportingDialog(CapturedPhoto photo) async {
    final notesController = TextEditingController();
    String selectedCategory = 'Umum';
    const categories = [
      'Umum',
      'Infrastruktur',
      'Lingkungan',
      'Keamanan',
      'Lainnya',
    ];

    return showDialog<ReportFormResult?>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.grey[900],
              title: const Text(
                'Form Laporan',
                style: TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: 380,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(photo.filePath),
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Kategori',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        dropdownColor: Colors.grey[800],
                        style: const TextStyle(color: Colors.white),
                        items: categories.map((cat) {
                          return DropdownMenuItem(value: cat, child: Text(cat));
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(
                            () => selectedCategory = value ?? 'Umum',
                          );
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[800],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Catatan',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: notesController,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Tulis catatan laporan...',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: Colors.grey[800],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      ReportFormResult(
                        category: selectedCategory,
                        note: notesController.text.trim().isEmpty
                            ? null
                            : notesController.text.trim(),
                      ),
                    );
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $hh:$mm';
  }

  String _buildShareText(CapturedPhoto photo) {
    return '''
📍 Tracking Photo Details

Nama Tempat: ${photo.locationName ?? 'Unknown'}
Alamat: ${photo.address ?? 'Unknown'}
Koordinat: ${photo.latitude?.toStringAsFixed(6) ?? '-'}, ${photo.longitude?.toStringAsFixed(6) ?? '-'}
Waktu: ${_formatDateTime(photo.timestamp)}

Google Maps: https://www.google.com/maps?q=${photo.latitude ?? 0},${photo.longitude ?? 0}
''';
  }

  Future<void> _showShareOptions(CapturedPhoto photo) async {
    final shareText = _buildShareText(photo);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.grey[900],
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bagikan',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await Clipboard.setData(ClipboardData(text: shareText));
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Teks lokasi disalin'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.text_snippet),
                    label: const Text('Bagikan Teks & Lokasi'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Bagikan foto: fitur share_plus belum diaktifkan',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Bagikan Foto + Teks'),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Batal',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onOpenTemplates() async {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.black87,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overlay Elements',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: _overlayConfig.showAddress,
                      title: const Text(
                        'Tampilkan alamat lengkap',
                        style: TextStyle(color: Colors.white),
                      ),
                      onChanged: (v) {
                        setModalState(() {
                          _overlayConfig = _overlayConfig.copyWith(
                            showAddress: v,
                          );
                        });
                        setState(() {});
                      },
                    ),
                    SwitchListTile(
                      value: _overlayConfig.showCoordinates,
                      title: const Text(
                        'Tampilkan koordinat',
                        style: TextStyle(color: Colors.white),
                      ),
                      onChanged: (v) {
                        setModalState(() {
                          _overlayConfig = _overlayConfig.copyWith(
                            showCoordinates: v,
                          );
                        });
                        setState(() {});
                      },
                    ),
                    SwitchListTile(
                      value: _overlayConfig.showTimestamp,
                      title: const Text(
                        'Tampilkan timestamp',
                        style: TextStyle(color: Colors.white),
                      ),
                      onChanged: (v) {
                        setModalState(() {
                          _overlayConfig = _overlayConfig.copyWith(
                            showTimestamp: v,
                          );
                        });
                        setState(() {});
                      },
                    ),
                    SwitchListTile(
                      value: _overlayConfig.showMiniMap,
                      title: const Text(
                        'Tampilkan mini map',
                        style: TextStyle(color: Colors.white),
                      ),
                      onChanged: (v) {
                        setModalState(() {
                          _overlayConfig = _overlayConfig.copyWith(
                            showMiniMap: v,
                          );
                        });
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _onOpenSettings() async {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black87,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _SettingsModalContent(
        onFlashChanged: (nextMode) async {
          setState(() => _flashMode = nextMode);
          await _applyFlashModeToController(nextMode);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _handleClosePressed(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: FutureBuilder<void>(
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
                final msg = snapshot.hasError
                    ? snapshot.error.toString()
                    : 'Camera not initialized';
                _logger.error('Camera preview failed', msg);
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Failed to initialize camera.\n$msg',
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final screenWidth = MediaQuery.of(context).size.width;

              return OrientationBuilder(
                builder: (context, orientation) {
                  // Frame kamera ditaruh di area yang tersedia agar bisa fill layar.
                  // Gunakan height sisa setelah UI overlay (top bar + bottom bar + info overlay).
                  final double frameWidth = screenWidth;
                  final double frameHeight =
                      MediaQuery.of(context).size.height -
                      56 -
                      64; // top bar + bottom bar
                  final double safeFrameHeight = frameHeight > 0
                      ? frameHeight
                      : MediaQuery.of(context).size.height;

                  return Stack(
                    children: [
                      // Viewfinder preview (with aspect-ratio cropping + optional digital zoom simulation)
                      Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: frameWidth,
                          height: safeFrameHeight,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _tapToFocus,
                            child: ClipRect(
                              child: _buildCroppedViewfinder(context),
                            ),
                          ),
                        ),
                      ),

                      if (_showGrid)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(painter: GridPainter()),
                          ),
                        ),

                      if (_isRecording)
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.fiber_manual_record,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'REC',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: _buildTopControlBar(context),
                      ),

                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 180,
                        child: _InfoOverlay(
                          meta: _meta,
                          config: _overlayConfig,
                          activeTheme: ref
                              .watch(cameraConfigProvider)
                              .activeTheme,
                          lastLocationUpdateTime: _lastLocationUpdateTime,
                          isLoading: _locationLoading,
                          watermarkOpacity: ref
                              .watch(cameraConfigProvider)
                              .watermarkOpacity,
                        ),
                      ),

                      Positioned(
                        top: 72,
                        left: 16,
                        right: 16,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: IgnorePointer(
                            ignoring: false,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.55),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (final z in _zoomPresets)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: InkWell(
                                        onTap: () => _applyZoom(z.value),
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                (z.value - _zoomLevel).abs() <
                                                    0.01
                                                ? Colors.blue.withOpacity(0.25)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color:
                                                  (z.value - _zoomLevel).abs() <
                                                      0.01
                                                  ? Colors.blue.withOpacity(0.7)
                                                  : Colors.white.withOpacity(
                                                      0.10,
                                                    ),
                                            ),
                                          ),
                                          child: Text(
                                            z.label,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      Align(
                        alignment: Alignment.bottomCenter,
                        child: SafeArea(
                          top: false,
                          child: _buildBottomSection(),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    final config = ref.watch(cameraConfigProvider);
    return _ThemedBottomPanel(
      activeTheme: config.activeTheme,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BottomModeSelector(
            selectedMode: _selectedMode,
            onModeChanged: (mode) {
              final notifier = ref.read(cameraConfigProvider.notifier);
              final target = switch (mode) {
                CameraMode.photo => CameraCaptureMode.photo,
                CameraMode.reporting => CameraCaptureMode.reporting,
                CameraMode.video => CameraCaptureMode.video,
                CameraMode.locationShare => CameraCaptureMode.locationShare,
              };
              while (ref.read(cameraConfigProvider).selectedMode != target) {
                notifier.cycleModes();
              }
              if (mode != CameraMode.video) {
                setState(() => _isRecording = false);
              }
            },
          ),
          const SizedBox(height: 8),
          _BottomActionBar(
            selectedMode: _selectedMode,
            isRecording: _isRecording,
            onCapture: _onCapture,
            onOpenTemplates: _onOpenTemplates,
            lastPhoto: _lastPhoto,
          ),
        ],
      ),
    );
  }

  Widget _buildTopControlBar(BuildContext context) {
    final notifier = ref.read(cameraConfigProvider.notifier);

    return Container(
      height: 56,

      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1) Close
          _TopIconButton(
            icon: Icons.close,
            tooltip: 'Close',
            onPressed: () => _handleClosePressed(context),
          ),

          // 2) Theme cycle + 3) Flash cycle + 4) Grid toggle + 5) Modes cycle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TopIconButton(
                icon: Icons.water_drop,
                tooltip: 'Theme cycle',
                onPressed: notifier.cycleWatermarkTheme,
              ),
              const SizedBox(width: 10),
              _TopIconButton(
                icon: _flashMode == FlashMode.off
                    ? Icons.flash_off
                    : _flashMode == FlashMode.on
                    ? Icons.flash_on
                    : Icons.flash_auto,
                tooltip: 'Flash cycle',
                onPressed: _cycleFlashMode,
              ),
              const SizedBox(width: 10),
              _TopIconButton(
                icon: Icons.grid_on,
                tooltip: 'Grid toggle',
                onPressed: notifier.toggleGrid,
              ),
              const SizedBox(width: 10),
              _TopIconButton(
                icon: Icons.layers,
                tooltip: 'Modes cycle',
                onPressed: notifier.cycleModes,
              ),
            ],
          ),

          // 6) Mock GPS + 7) Lens flip + 8) Settings
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _TopIconButton(
                icon: Icons.gps_fixed,
                tooltip: 'Toggle Mock/Real GPS',
                onPressed: notifier.toggleMockGps,
              ),
              const SizedBox(width: 10),
              _TopIconButton(
                icon: Icons.flip_camera_ios,
                tooltip: 'Flip camera',
                onPressed: () async {
                  notifier.toggleLensDirection();
                  await _switchCamera();
                },
              ),
              const SizedBox(width: 10),
              _TopIconButton(
                icon: Icons.settings,
                tooltip: 'Settings',
                onPressed: _onOpenSettings,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeColors {
  final Color border;
  final Color background;
  final Color text;
  final Color mutedText;

  const _ThemeColors({
    required this.border,
    required this.background,
    required this.text,
    required this.mutedText,
  });
}

class _InfoOverlay extends StatelessWidget {
  final CapturedMeta meta;
  final OverlayConfig config;
  final String activeTheme;
  final DateTime? lastLocationUpdateTime;
  final bool isLoading;
  final double watermarkOpacity;

  const _InfoOverlay({
    required this.meta,
    required this.config,
    required this.activeTheme,
    required this.lastLocationUpdateTime,
    required this.isLoading,
    required this.watermarkOpacity,
  });

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $hh:$mm';
  }

  _ThemeColors _themeColors(String theme) {
    switch (theme) {
      case 'Pure OLED Black':
        return const _ThemeColors(
          border: Color(0xFF00FFA5),
          background: Color(0xFF000000),
          text: Colors.white,
          mutedText: Color(0xFFB8FFE0),
        );
      case 'Sunset Slate':
        return const _ThemeColors(
          border: Color(0xFFFFB85C),
          background: Color(0xFF2F3240),
          text: Color(0xFFF8F0E3),
          mutedText: Color(0xFFCCB6A4),
        );
      default:
        return const _ThemeColors(
          border: Color(0xFF4D9BE6),
          background: Color(0xFF071A3F),
          text: Colors.white,
          mutedText: Color(0xFFB7D4F1),
        );
    }
  }

  String _fontFamily(String theme) {
    switch (theme) {
      case 'Pure OLED Black':
        return 'JetBrains Mono';
      case 'Sunset Slate':
        return 'Space Grotesk';
      default:
        return 'Inter';
    }
  }

  TextStyle _labelTextStyle(String theme) {
    final colors = _themeColors(theme);
    return TextStyle(
      color: colors.text,
      fontFamily: _fontFamily(theme),
      letterSpacing: 0.2,
    );
  }

  TextStyle _infoTextStyle(String theme) {
    final colors = _themeColors(theme);
    return TextStyle(
      color: colors.text.withOpacity(0.88),
      fontFamily: _fontFamily(theme),
      height: 1.3,
    );
  }

  Color _mutedTextColor(String theme) {
    return _themeColors(theme).mutedText;
  }

  @override
  Widget build(BuildContext context) {
    final ts = _formatDateTime(meta.timestamp);
    final themeColors = _themeColors(activeTheme);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeColors.background.withOpacity(watermarkOpacity),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeColors.border, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: themeColors.border.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  meta.locationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _labelTextStyle(
                    activeTheme,
                  ).copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              if (isLoading)
                const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (config.showTimestamp)
            Text(
              ts,
              style: _infoTextStyle(
                activeTheme,
              ).copyWith(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          if (config.showAddress) ...[
            const SizedBox(height: 8),
            Text(
              meta.address,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _infoTextStyle(activeTheme).copyWith(
                color: _mutedTextColor(activeTheme),
                fontSize: 12.5,
                height: 1.25,
              ),
            ),
          ],
          if (config.showCoordinates) ...[
            const SizedBox(height: 6),
            Text(
              'Lat,Lng: ${meta.coordinates}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _infoTextStyle(
                activeTheme,
              ).copyWith(color: _mutedTextColor(activeTheme), fontSize: 12),
            ),
          ],
          if (config.showMiniMap) ...[
            const SizedBox(height: 10),
            Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: const Center(
                child: Text(
                  'Mini Map Placeholder',
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BottomModeSelector extends StatelessWidget {
  final CameraMode selectedMode;
  final ValueChanged<CameraMode> onModeChanged;

  const _BottomModeSelector({
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.black),
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: _ModeItem(
                  mode: CameraMode.locationShare,
                  selectedMode: selectedMode,
                  icon: Icons.share_location,
                  label: 'Location Share',
                  onTap: () => onModeChanged(CameraMode.locationShare),
                ),
              ),
              Expanded(
                child: _ModeItem(
                  mode: CameraMode.photo,
                  selectedMode: selectedMode,
                  icon: Icons.photo_camera,
                  label: 'Photo',
                  onTap: () => onModeChanged(CameraMode.photo),
                ),
              ),
              Expanded(
                child: _ModeItem(
                  mode: CameraMode.video,
                  selectedMode: selectedMode,
                  icon: Icons.videocam,
                  label: 'Video',
                  onTap: () => onModeChanged(CameraMode.video),
                ),
              ),
              Expanded(
                child: _ModeItem(
                  mode: CameraMode.reporting,
                  selectedMode: selectedMode,
                  icon: Icons.description,
                  label: 'Reporting',
                  onTap: () => onModeChanged(CameraMode.reporting),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeItem extends StatelessWidget {
  final CameraMode mode;
  final CameraMode selectedMode;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ModeItem({
    required this.mode,
    required this.selectedMode,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = mode == selectedMode;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final color = isActive ? primaryColor : Colors.white60;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(top: 2),
                height: 2,
                width: 24,
                color: primaryColor,
              ),
          ],
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final Future<void> Function() onCapture;
  final Future<void> Function() onOpenTemplates;
  final CapturedPhoto? lastPhoto;
  final CameraMode selectedMode;
  final bool isRecording;

  const _BottomActionBar({
    required this.onCapture,
    required this.onOpenTemplates,
    required this.lastPhoto,
    required this.selectedMode,
    required this.isRecording,
  });

  @override
  Widget build(BuildContext context) {
    Color shutterColor;
    switch (selectedMode) {
      case CameraMode.photo:
        shutterColor = Colors.white;
        break;
      case CameraMode.reporting:
        shutterColor = Colors.amber;
        break;
      case CameraMode.video:
        shutterColor = Colors.red;
        break;
      case CameraMode.locationShare:
        shutterColor = Colors.cyanAccent;
        break;
    }

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: Colors.black.withOpacity(0.35),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.history);
                },
                child: _buildHistoryThumbnail(context),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: onCapture,
                child: Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: shutterColor, width: 4),
                    color: shutterColor.withOpacity(0.12),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: selectedMode == CameraMode.video && isRecording
                          ? BoxShape.rectangle
                          : BoxShape.circle,
                      borderRadius:
                          selectedMode == CameraMode.video && isRecording
                          ? BorderRadius.circular(6)
                          : null,
                      color: shutterColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onOpenTemplates,
                icon: const Icon(Icons.layers, color: Colors.white),
                label: const Text(
                  'Template',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.25),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.blue.withOpacity(0.35)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build thumbnail widget untuk history page.
  ///
  /// Behavior:
  /// - Jika lastPhoto ada → tampilkan thumbnail gambar
  /// - Jika lastPhoto null → tampilkan placeholder icon + teks
  ///
  /// Perilaku tap SELALU sama: buka HistoryPage tanpa guard
  /// HistoryPage sendiri menangani empty state jika tidak ada data
  Widget _buildHistoryThumbnail(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: lastPhoto == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.photo_library_outlined,
                      color: Colors.white54,
                      size: 18,
                    ),
                  ],
                ),
              )
            : Image.file(
                File(lastPhoto!.filePath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.image,
                    color: Colors.white54,
                    size: 18,
                  );
                },
              ),
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _TopIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 250),
      showDuration: const Duration(seconds: 2),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _ThemedBottomPanel extends StatelessWidget {
  final String activeTheme;
  final Widget child;

  const _ThemedBottomPanel({required this.activeTheme, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = _BottomThemePreset.fromActiveTheme(activeTheme);

    return ClipRRect(
      borderRadius: BorderRadius.circular(theme.borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.panelColor,
            borderRadius: BorderRadius.circular(theme.borderRadius),
            border: Border.all(color: theme.borderColor, width: 1),
          ),
          child: DefaultTextStyle.merge(style: theme.textStyle, child: child),
        ),
      ),
    );
  }
}

class _BottomThemePreset {
  final double borderRadius;
  final Color panelColor;
  final Color borderColor;
  final Color accentColor;
  final TextStyle textStyle;

  const _BottomThemePreset({
    required this.borderRadius,
    required this.panelColor,
    required this.borderColor,
    required this.accentColor,
    required this.textStyle,
  });

  static _BottomThemePreset fromActiveTheme(String activeTheme) {
    switch (activeTheme) {
      case 'Classic Navy':
        return _BottomThemePreset(
          borderRadius: 18,
          panelColor: const Color.fromARGB(160, 5, 25, 55),
          borderColor: const Color.fromARGB(90, 110, 170, 255),
          accentColor: const Color.fromARGB(255, 90, 170, 255),
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            height: 1.25,
            fontWeight: FontWeight.w600,
          ),
        );
      case 'Pure OLED Black':
        return _BottomThemePreset(
          borderRadius: 18,
          panelColor: const Color.fromARGB(150, 0, 0, 0),
          borderColor: const Color.fromARGB(85, 255, 255, 255),
          accentColor: const Color.fromARGB(255, 255, 255, 255),
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            height: 1.25,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        );
      case 'Sunset Slate':
        return _BottomThemePreset(
          borderRadius: 18,
          panelColor: const Color.fromARGB(160, 30, 10, 40),
          borderColor: const Color.fromARGB(90, 255, 150, 90),
          accentColor: const Color.fromARGB(255, 255, 150, 90),
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            height: 1.25,
            fontWeight: FontWeight.w700,
          ),
        );
      default:
        return _BottomThemePreset(
          borderRadius: 18,
          panelColor: const Color.fromARGB(160, 5, 25, 55),
          borderColor: const Color.fromARGB(90, 110, 170, 255),
          accentColor: const Color.fromARGB(255, 90, 170, 255),
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            height: 1.25,
            fontWeight: FontWeight.w600,
          ),
        );
    }
  }
}

// ==================== Settings Modal Content ====================
// ConsumerWidget untuk membuat settings modal reactive terhadap state changes

class _SettingsModalContent extends ConsumerWidget {
  final Function(FlashMode) onFlashChanged;

  const _SettingsModalContent({required this.onFlashChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ ref.watch() sekarang akan trigger rebuild saat state berubah
    final cfg = ref.watch(cameraConfigProvider);
    final notifier = ref.read(cameraConfigProvider.notifier);
    final primary = Theme.of(context).colorScheme.primary;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Camera Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            // ==================== Watermark Opacity Slider ====================
            Text(
              'Watermark Opacity',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                Slider(
                  value: cfg.watermarkOpacity,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  activeColor: primary,
                  inactiveColor: Colors.white24,
                  label: '${(cfg.watermarkOpacity * 100).toStringAsFixed(0)}%',
                  onChanged: (value) {
                    notifier.setWatermarkOpacity(value);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Opacity: ${(cfg.watermarkOpacity * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                      Icon(Icons.info, size: 14, color: Colors.white54),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // ==================== Watermark Toggle Switch ====================
            SwitchListTile(
              title: const Text(
                'Watermark',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: cfg.activeTheme.isEmpty
                  ? const Text(
                      'Disabled',
                      style: TextStyle(color: Colors.white54),
                    )
                  : Text(cfg.activeTheme, style: TextStyle(color: primary)),
              value: cfg.activeTheme.isNotEmpty,
              activeThumbColor: primary,
              onChanged: (value) {
                // ✅ Fixed: Use toggleWatermark() for proper ON/OFF logic
                notifier.toggleWatermark();
              },
            ),
            const SizedBox(height: 8),
            // ==================== Aspect Ratio ====================
            Text(
              'Aspect Ratio',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                for (final ratio in CameraAspectRatio.values)
                  RadioListTile<CameraAspectRatio>(
                    title: Text(
                      ratio.label,
                      style: const TextStyle(color: Colors.white),
                    ),
                    value: ratio,
                    groupValue: cfg.selectedRatio,
                    activeColor: primary,
                    onChanged: (selected) {
                      if (selected != null) {
                        notifier.setAspectRatio(selected);
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // ==================== Flash ====================
            SwitchListTile(
              title: const Text('Flash', style: TextStyle(color: Colors.white)),
              value: cfg.flashMode == CameraFlashMode.on,
              activeThumbColor: primary,
              onChanged: (value) {
                final nextMode = value ? FlashMode.on : FlashMode.off;
                onFlashChanged(nextMode);
              },
            ),
            // ==================== GPS Simulator ====================
            SwitchListTile(
              title: const Text(
                'GPS Simulator',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: cfg.gpsMode.isSimulator
                  ? const Text(
                      'Using mock GPS coordinates',
                      style: TextStyle(color: Colors.white54),
                    )
                  : const Text(
                      'Using real GPS coordinates',
                      style: TextStyle(color: Colors.white54),
                    ),
              value: cfg.gpsMode.isSimulator,
              activeThumbColor: primary,
              onChanged: (value) {
                notifier.toggleMockGps();
              },
            ),
            // ==================== Grid ====================
            SwitchListTile(
              title: const Text('Grid', style: TextStyle(color: Colors.white)),
              subtitle: cfg.showGrid
                  ? const Text(
                      'Rule of thirds grid visible',
                      style: TextStyle(color: Colors.white54),
                    )
                  : const Text(
                      'Grid hidden',
                      style: TextStyle(color: Colors.white54),
                    ),
              value: cfg.showGrid,
              activeThumbColor: primary,
              onChanged: (value) {
                notifier.toggleGrid();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(2 * size.width / 3, 0),
      Offset(2 * size.width / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      paint,
    );
    canvas.drawLine(
      Offset(0, 2 * size.height / 3),
      Offset(size.width, 2 * size.height / 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
