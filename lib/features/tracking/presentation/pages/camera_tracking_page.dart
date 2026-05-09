import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../../../core/utils/app_logger.dart';
import '../providers.dart';


enum CameraMode { locationShare, photo, video, reporting }


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

class _CameraTrackingPageState extends ConsumerState<CameraTrackingPage> {
  final _logger = const AppLogger(tag: 'CameraTrackingPage');

  CapturedPhoto? _lastPhoto;
  List<CapturedPhoto> _photoHistory = [];
  bool _isFlashOn = false;
  bool _isWatermarkOn = true;
  bool _showGrid = false;
  bool _isRecording = false;

  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  OverlayConfig _overlayConfig = const OverlayConfig();

  List<CameraDescription> _availableCameras = [];
  int _currentCameraIndex = 0;

  CapturedMeta _meta = CapturedMeta(
    locationName: 'Kecamatan Contoh',
    address: 'Jl. Contoh No. 123, Kelurahan Sampel, Kota Demo, Provinsi Nusantara',
    coordinates: '-6.200000, 106.816666',
    timestamp: DateTime.now(),
  );

  CameraMode _selectedMode = CameraMode.photo;

  double? _latitude;
  double? _longitude;

  // Camera zoom controls (relative levels)
  double _zoomLevel = 1.0;
  final List<double> _zoomPresets = const [0.6, 1.0, 2.0];


  DateTime? _lastLocationUpdateTime;
  bool _locationLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Force portrait orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    _initializeControllerFuture = _initCamera().then((_) async {
      await _refreshLocationData(showLoading: false);
    });
    _lastLocationUpdateTime ??= DateTime.now();
  }

  Future<void> _applyZoom(double zoom) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      // Clamp using known limits if available; otherwise apply the preset directly.
      final minZoom = 0.6;
      final maxZoom = 2.0;
      final clamped = zoom.clamp(minZoom, maxZoom);
      await controller.setZoomLevel(clamped);
      setState(() => _zoomLevel = clamped);
      _logger.info('Zoom set to ${clamped.toStringAsFixed(2)}x');
    } catch (e) {
      _logger.warning('Failed to set zoom level: $e');
    }
  }

  void _tapToFocus() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      await controller.setFocusMode(FocusMode.auto);
    } catch (e) {
      _logger.warning('Failed to trigger autofocus: $e');
    }
  }

  Future<void> _initCamera() async {

    _availableCameras = await availableCameras();
    if (!mounted) return;

    final backCamera = _availableCameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => _availableCameras.first,
    );

    _currentCameraIndex = _availableCameras.indexOf(backCamera);

    final controller = CameraController(
      backCamera,
      ResolutionPreset.veryHigh,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = controller;
    await controller.initialize();

    await controller.setFlashMode(FlashMode.off);
    
    // Set zoom to lowest level for wide view
    try {
      // Get the minimum zoom level available on the camera
      final zoomLevel = 1.0;
      await controller.setZoomLevel(zoomLevel);
      _logger.info('Zoom set to 1.0x (minimum)');
    } catch (e) {
      _logger.warning('Failed to set zoom level');
    }
    
    // Enable autofocus for sharp image
    try {
      await controller.setFocusMode(FocusMode.auto);
      _logger.info('Autofocus enabled');
    } catch (e) {
      _logger.warning('Failed to enable autofocus');
    }

    _logger.info('Camera initialized: ${controller.value.previewSize}');
  }

  @override
  void dispose() {
    // Reset orientation to portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _refreshLocationData({bool showLoading = false}) async {
    if (showLoading) {
      setState(() {
        _locationLoading = true;
      });
    }

    try {
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

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final lat = pos.latitude;
      final lng = pos.longitude;

      String? addressLine;
      String? placeName;

      try {
        final placemarks = await placemarkFromCoordinates(lat, lng);
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

          placeName = p.locality ?? p.subAdministrativeArea ?? p.administrativeArea;
        }
      } catch (e) {
        _logger.error('Reverse geocoding failed', e is Object ? e : e.toString());
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

      _logger.info('Location refreshed: lat=$lat lng=$lng');
    } finally {
      if (showLoading && mounted) {
        setState(() {
          _locationLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
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

            return Stack(
              children: [
                  Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _tapToFocus,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final cameraAspectRatio = controller.value.aspectRatio;

                        return ClipRect(
                          child: OverflowBox(
                            alignment: Alignment.center,
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: constraints.maxWidth,
                                height: constraints.maxWidth / cameraAspectRatio,
                                child: CameraPreview(controller),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (_showGrid)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: GridPainter(),
                    ),
                  ),
                if (_isRecording)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.fiber_manual_record, color: Colors.white, size: 12),
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
                // Zoom presets UI (di bawah Utility/Top Control Bar agar mudah di-tap)
                if (_controller != null && _controller!.value.isInitialized)
                  Positioned(
                    top: 72, // Top Control Bar height ~56 + padding
                    left: 16,
                    right: 16,
                    child: IgnorePointer(
                      ignoring: false,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final z in _zoomPresets)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: InkWell(
                                    onTap: () => _applyZoom(z),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: (z - _zoomLevel).abs() < 0.01
                                            ? Colors.blue.withOpacity(0.25)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: (z - _zoomLevel).abs() < 0.01
                                              ? Colors.blue.withOpacity(0.7)
                                              : Colors.white.withOpacity(0.10),
                                        ),
                                      ),
                                      child: Text(
                                        '${z.toStringAsFixed(z == 1.0 ? 0 : 1)}x',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: (z - _zoomLevel).abs() < 0.01
                                              ? FontWeight.w800
                                              : FontWeight.w600,
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
                // Preview size indicator (kept but moved to top-right to avoid conflict)
                if (_controller != null && _controller!.value.isInitialized)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_controller!.value.previewSize?.width.toInt()}x${_controller!.value.previewSize?.height.toInt()}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
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
                    lastLocationUpdateTime: _lastLocationUpdateTime,
                    isLoading: _locationLoading,
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
        ),
      );
  }

  Widget _buildBottomSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _BottomModeSelector(
          selectedMode: _selectedMode,
          onModeChanged: (mode) {
            setState(() {
              _selectedMode = mode;
            });
            _logger.info('Mode changed to $mode');
          },
        ),
        const SizedBox(height: 8),
        _BottomActionBar(
          onCapture: onCapture,
          onOpenTemplates: onOpenTemplates,
          onOpenPhotoHistory: _showPhotoHistory,
          lastPhoto: _lastPhoto,
          selectedMode: _selectedMode,
          isRecording: _isRecording,
        ),
      ],
    );
  }

  Widget _buildTopControlBar(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 56,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _TopIconButton(
              icon: Icons.close,
              tooltip: 'Tutup kamera',
              onPressed: onToggleClose,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TopIconButton(
                  icon: _isWatermarkOn ? Icons.water_drop : Icons.water_drop_outlined,
                  tooltip: 'Toggle watermark',
                  onPressed: onToggleWatermark,
                ),
                const SizedBox(width: 10),
                _TopIconButton(
                  icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  tooltip: 'Toggle flash',
                  onPressed: onToggleFlash,
                ),
                const SizedBox(width: 10),
                _TopIconButton(
                  icon: Icons.grid_on,
                  tooltip: 'Toggle grid',
                  onPressed: onToggleGrid,
                ),
                const SizedBox(width: 10),
                _TopIconButton(
                  icon: Icons.layers,
                  tooltip: 'Overlay / Templates',
                  onPressed: onOpenTemplates,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _TopIconButton(
                  icon: Icons.my_location,
                  tooltip: 'Refetch lokasi',
                  onPressed: onRefreshLocation,
                ),
                const SizedBox(width: 10),
                _TopIconButton(
                  icon: Icons.rotate_right,
                  tooltip: 'Rotate camera',
                  onPressed: onRotateCamera,
                ),
                const SizedBox(width: 10),
                _TopIconButton(
                  icon: Icons.settings,
                  tooltip: 'Settings',
                  onPressed: onOpenSettings,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void onToggleFlash() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      _logger.warning('Camera not initialized, cannot toggle flash');
      return;
    }

    try {
      final newFlashState = !_isFlashOn;
      await controller.setFlashMode(
        newFlashState ? FlashMode.torch : FlashMode.off,
      );
      setState(() {
        _isFlashOn = newFlashState;
      });
      _logger.info('Flash toggled: isFlashOn=$_isFlashOn');
    } catch (e) {
      _logger.error('Failed to toggle flash', e is Object ? e : e.toString());
    }
  }

  void onToggleWatermark() {
    setState(() {
      _isWatermarkOn = !_isWatermarkOn;
    });
    _logger.info('Watermark toggled: isWatermarkOn=$_isWatermarkOn');
  }

  void onToggleGrid() {
    setState(() {
      _showGrid = !_showGrid;
    });
    _logger.info('Grid toggled: showGrid=$_showGrid');
  }

  void onOpenSettings() {
    _logger.info('onOpenSettings');
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.grey[900],
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _buildSettingsSheet(context),
    );
  }

  Widget _buildSettingsSheet(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Camera Settings',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Watermark', style: TextStyle(color: Colors.white)),
            value: _isWatermarkOn,
            activeColor: primary,
            onChanged: (value) {
              setState(() {
                _isWatermarkOn = value;
              });
              _logger.info('Settings changed watermark=$value');
            },
          ),
          SwitchListTile(
            title: const Text('Flash', style: TextStyle(color: Colors.white)),
            value: _isFlashOn,
            activeColor: primary,
            onChanged: (value) {
              onToggleFlash();
            },
          ),
          SwitchListTile(
            title: const Text('Grid', style: TextStyle(color: Colors.white)),
            value: _showGrid,
            activeColor: primary,
            onChanged: (value) {
              setState(() {
                _showGrid = value;
              });
              _logger.info('Settings changed grid=$value');
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void onRefreshLocation() {
    _refreshLocationData(showLoading: true);
  }

  void onRotateCamera() async {
    if (_availableCameras.isEmpty || _availableCameras.length < 2) {
      _logger.warning('No multiple cameras available');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hanya ada satu kamera tersedia'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _controller?.dispose();
      _currentCameraIndex = (_currentCameraIndex + 1) % _availableCameras.length;
      final newCamera = _availableCameras[_currentCameraIndex];

      final newController = CameraController(
        newCamera,
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await newController.initialize();
      await newController.setFlashMode(FlashMode.off);
      
      // Set zoom to 1.0x (minimum/widest view)
      try {
        await newController.setZoomLevel(1.0);
        await newController.setFocusMode(FocusMode.auto);
      } catch (e) {
        _logger.warning('Failed to configure camera settings');
      }

      if (!mounted) return;

      setState(() {
        _controller = newController;
        _isFlashOn = false;
      });

      _logger.info('Camera rotated to: ${newCamera.lensDirection}');
    } catch (e) {
      _logger.error('Failed to rotate camera', e is Object ? e : e.toString());
    }
  }

  void onToggleClose() async {
    try {
      await _controller?.dispose();
      if (!mounted) return;
      Navigator.of(context).pop();
      _logger.info('Camera closed');
    } catch (e) {
      _logger.error('Error closing camera', e is Object ? e : e.toString());
    }
  }

  void onCapture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      _logger.warning('Camera not initialized');
      return;
    }

    switch (_selectedMode) {
      case CameraMode.locationShare:
        await _handleLocationShare();
        break;
      case CameraMode.photo:
        await _handlePhotoCapture(controller);
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
    try {
      await _refreshLocationData(showLoading: true);

      if (_latitude == null || _longitude == null) {
        _logger.warning('Location not available for sharing');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lokasi tidak tersedia. Coba refresh GPS terlebih dahulu.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final shareText = '''
📍 Lokasi Saya

Nama Tempat: ${_meta.locationName}
Alamat: ${_meta.address}
Koordinat: $_latitude, $_longitude
Waktu: ${_formatDateTime(DateTime.now())}

Google Maps: https://www.google.com/maps?q=$_latitude,$_longitude
''';

      await Clipboard.setData(ClipboardData(text: shareText));

      _logger.info('Location shared to clipboard');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lokasi disalin ke clipboard!'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      _logger.error('Failed to share location', e is Object ? e : e.toString());
    }
  }

  Future<void> _handlePhotoCapture(CameraController controller) async {
    try {
      // 1) ambil foto untuk UI preview + file untuk persistence
      final XFile file = await controller.takePicture();
      final now = DateTime.now();

      final photo = CapturedPhoto(
        filePath: file.path,
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
        // tetap isi cache in-memory untuk respons cepat saat sheet dibuka di sesi yang sama
        _photoHistory.insert(0, photo);
      });

      // 2) persist ke storage (tracking.json) memakai usecase existing
      // CaptureTracking akan menjalankan permission+camera+location+geocode lagi.
      // Namun untuk memastikan persistence terjadi dari page ini, kita cukup jalankan usecase.
      final captureResult = await ref.read(captureTrackingProvider).execute();

      captureResult.when(
        success: (_) {
          _logger.info('Photo tracking saved to storage');
        },
        failure: (failure) {
          _logger.warning('Failed to persist tracking: ${failure.message}');
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto berhasil diproses & disimpan'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      _logger.error('Photo capture failed', e is Object ? e : e.toString());
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
        final XFile videoFile = await controller.stopVideoRecording();

        setState(() {
          _isRecording = false;
        });

        _logger.info('Video saved: ${videoFile.path}');

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video disimpan: ${videoFile.name}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await controller.startVideoRecording();

        setState(() {
          _isRecording = true;
        });

        _logger.info('Video recording started');

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔴 Merekam video...'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      _logger.error('Video recording failed', e is Object ? e : e.toString());
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _handleReportingCapture(CameraController controller) async {
    try {
      final XFile file = await controller.takePicture();
      final now = DateTime.now();

      final photo = CapturedPhoto(
        filePath: file.path,
        locationName: _meta.locationName,
        address: _meta.address,
        latitude: _latitude,
        longitude: _longitude,
        timestamp: now,
        overlayConfig: _overlayConfig,
      );

      setState(() {
        _lastPhoto = photo;
      });

      _logger.info('Reporting photo captured: ${photo.filePath}');

      if (!mounted) return;

      await _showReportingDialog(photo);
    } catch (e) {
      _logger.error('Reporting capture failed', e is Object ? e : e.toString());
    }
  }

  Future<void> _showReportingDialog(CapturedPhoto photo) async {
    final TextEditingController notesController = TextEditingController();
    String selectedCategory = 'Umum';

    final categories = ['Umum', 'Infrastruktur', 'Lingkungan', 'Keamanan', 'Lainnya'];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text(
                'Form Laporan',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
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
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedCategory = value ?? 'Umum';
                        });
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _logger.info(
                      'Report saved: category=$selectedCategory, '
                      'notes=${notesController.text}, '
                      'photo=${photo.filePath}',
                    );

                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Laporan berhasil disimpan!'),
                        backgroundColor: Colors.green,
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

  Future<void> onOpenTemplates() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.grey[900],
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
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
                      activeThumbColor: Colors.blue,
                      activeTrackColor: Colors.blue.withOpacity(0.5),
                      title: const Text(
                        'Tampilkan alamat lengkap',
                        style: TextStyle(color: Colors.white),
                      ),
                      onChanged: (v) {
                        setModalState(() {
                          _overlayConfig = _overlayConfig.copyWith(showAddress: v);
                        });
                        setState(() {});
                      },
                    ),
                    SwitchListTile(
                      value: _overlayConfig.showCoordinates,
                      activeThumbColor: Colors.blue,
                      activeTrackColor: Colors.blue.withOpacity(0.5),
                      title: const Text(
                        'Tampilkan koordinat',
                        style: TextStyle(color: Colors.white),
                      ),
                      onChanged: (v) {
                        setModalState(() {
                          _overlayConfig = _overlayConfig.copyWith(showCoordinates: v);
                        });
                        setState(() {});
                      },
                    ),
                    SwitchListTile(
                      value: _overlayConfig.showTimestamp,
                      activeThumbColor: Colors.blue,
                      activeTrackColor: Colors.blue.withOpacity(0.5),
                      title: const Text(
                        'Tampilkan timestamp',
                        style: TextStyle(color: Colors.white),
                      ),
                      onChanged: (v) {
                        setModalState(() {
                          _overlayConfig = _overlayConfig.copyWith(showTimestamp: v);
                        });
                        setState(() {});
                      },
                    ),
                    SwitchListTile(
                      value: _overlayConfig.showMiniMap,
                      activeThumbColor: Colors.blue,
                      activeTrackColor: Colors.blue.withOpacity(0.5),
                      title: const Text(
                        'Tampilkan mini map',
                        style: TextStyle(color: Colors.white),
                      ),
                      onChanged: (v) {
                        setModalState(() {
                          _overlayConfig = _overlayConfig.copyWith(showMiniMap: v);
                        });
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              );
            },
          ),
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

  Future<void> _showPhotoHistory() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.grey[900],
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: _photoHistory.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.white38,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Belum ada foto',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Riwayat Foto (${_photoHistory.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _photoHistory.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final photo = _photoHistory[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _showPhotoDetail(photo);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      bottomLeft: Radius.circular(12),
                                    ),
                                    child: Image.file(
                                      File(photo.filePath),
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            photo.locationName ?? 'Unknown',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatDateTime(photo.timestamp),
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.7),
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${photo.latitude?.toStringAsFixed(4)}, ${photo.longitude?.toStringAsFixed(4)}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.6),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.white.withOpacity(0.5),
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Future<void> _showPhotoDetail(CapturedPhoto photo) async {
    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image Section
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Image.file(
                          File(photo.filePath),
                          width: double.infinity,
                          height: 250,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Details Section with Scroll (bounded height to prevent overflow)
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Detail Lokasi Tracking',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatDateTime(photo.timestamp),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.65),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Card(
                              elevation: 0,
                              color: Colors.white.withOpacity(0.04),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.white.withOpacity(0.08)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _DetailRow(
                                      label: 'Nama Tempat',
                                      value: photo.locationName ?? 'Unknown',
                                      icon: Icons.location_on,
                                    ),
                                    const SizedBox(height: 14),
                                    _DetailRow(
                                      label: 'Alamat Lengkap',
                                      value: photo.address ?? 'Unknown',
                                      icon: Icons.home,
                                    ),
                                    const SizedBox(height: 14),
                                    _DetailRow(
                                      label: 'Koordinat GPS',
                                      value:
                                          '${photo.latitude?.toStringAsFixed(6)}, ${photo.longitude?.toStringAsFixed(6)}',
                                      icon: Icons.map,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _showShareOptions(context, photo),
                                    icon: const Icon(Icons.share),
                                    label: const Text('Share'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      side: BorderSide(color: Colors.white.withOpacity(0.14)),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text('Tutup'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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

  Future<void> _showShareOptions(BuildContext context, CapturedPhoto photo) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.grey[900],
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
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
                      try {
                        final shareText = _buildShareText(photo);
                        await Share.share(
                          shareText,
                          subject: 'Tracking Photo - ${photo.locationName ?? 'Unknown'}',
                        );
                        _logger.info('Photo shared as text');
                      } catch (e) {
                        _logger.warning('Failed to share text');
                      }
                    },
                    icon: const Icon(Icons.text_snippet),
                    label: const Text('Bagikan Teks & Lokasi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      try {
                        final shareText = _buildShareText(photo);
                        final imageFile = XFile(photo.filePath);
                        await Share.shareXFiles(
                          [imageFile],
                          text: shareText,
                          subject: 'Tracking Photo - ${photo.locationName ?? 'Unknown'}',
                        );
                        _logger.info('Photo shared as photo + text');
                      } catch (e) {
                        _logger.warning('Failed to share photo');
                      }
                    },
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Bagikan Foto + Teks'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      side: BorderSide(color: Colors.blue.withOpacity(0.35)),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal', style: TextStyle(color: Colors.white70)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Legacy: keep method for compatibility if referenced elsewhere.
  Future<void> _sharePhoto(CapturedPhoto photo) async {
    try {
      await Share.share(
        _buildShareText(photo),
        subject: 'Tracking Photo - ${photo.locationName ?? 'Unknown'}',
      );
      _logger.info('Photo shared');
    } catch (e) {
      _logger.warning('Failed to share photo');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal membagikan foto'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

}

// ========== WIDGETS ==========

class _InfoOverlay extends StatelessWidget {
  final CapturedMeta meta;
  final OverlayConfig config;
  final DateTime? lastLocationUpdateTime;
  final bool isLoading;

  const _InfoOverlay({
    required this.meta,
    required this.config,
    required this.lastLocationUpdateTime,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final ts = _formatDateTime(meta.timestamp);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  meta.locationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (config.showAddress) ...[
            const SizedBox(height: 8),
            Text(
              meta.address,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
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
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
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
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                ),
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

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $hh:$mm';
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
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
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
    final Color color = isActive ? primaryColor : Colors.white60;

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
  final VoidCallback onCapture;
  final Future<void> Function() onOpenTemplates;
  final CapturedPhoto? lastPhoto;
  final CameraMode selectedMode;
  final bool isRecording;
  final VoidCallback onOpenPhotoHistory;

  const _BottomActionBar({
    required this.onCapture,
    required this.onOpenTemplates,
    required this.lastPhoto,
    required this.selectedMode,
    required this.onOpenPhotoHistory,
    this.isRecording = false,
  });

  @override
  Widget build(BuildContext context) {
    Color shutterColor = Colors.white;
    if (selectedMode == CameraMode.video && isRecording) {
      shutterColor = Colors.red;
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
                onTap: onOpenPhotoHistory,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      border: Border.all(color: Colors.white.withOpacity(0.18)),
                    ),
                    child: lastPhoto == null
                        ? const Icon(Icons.image, color: Colors.white54, size: 20)
                        : Image.file(
                            File(lastPhoto!.filePath),
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
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
                      borderRadius: selectedMode == CameraMode.video && isRecording
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
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.0;

    // Vertical lines (rule of thirds)
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

    // Horizontal lines (rule of thirds)
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