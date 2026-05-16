// Rebuilt from the latest stable full preview to fix broken structure/duplicates.
// NOTE: This version focuses on compilation and basic functionality.

import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart' show Clipboard, ClipboardData, TextInputFormatter;



import 'package:camera/camera.dart';
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
import '../../domain/entities/history_item.dart';


// For navigator route names.
import '../../../../routes.dart' show AppRoutes;




// Keep enum names compatible with existing UI.
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


  CaptureState get _captureState => ref.watch(captureNotifierProvider);

  Future<void> _captureAndSyncUI({required bool showSuccessSnackBar}) async {
    final notifier = ref.read(captureNotifierProvider.notifier);

    await notifier.capture();

    if (!mounted) return;

    final after = ref.read(captureNotifierProvider);

    if (after.isLoading) {
      // notifier should finish quickly, but keep guard
      return;
    }

    if (after.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(after.error!.message),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (showSuccessSnackBar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto berhasil diproses & disimpan'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    }

    final tracking = after.tracking;
    if (tracking != null) {
      setState(() {
        _lastPhoto = CapturedPhoto(
          filePath: tracking.imagePath,
          timestamp: tracking.timestamp,
          locationName: '',
          address: tracking.address,
          latitude: tracking.latitude,
          longitude: tracking.longitude,
          overlayConfig: _overlayConfig,
        );
      });
    }
  }


  CapturedPhoto? _lastPhoto;
  final List<CapturedPhoto> _photoHistory = [];

  // UI toggles
  bool _isFlashOn = false;
  bool _isWatermarkOn = true;
  bool _showGrid = false;
  bool _isRecording = false;
  bool _locationLoading = false;

  // Camera
  static const double _targetCameraAspect = 16 / 9;

  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  OverlayConfig _overlayConfig = const OverlayConfig();

  CapturedMeta _meta = CapturedMeta(
    locationName: 'Kecamatan Contoh',
    address: 'Jl. Contoh No. 123, Kelurahan Sampel, Kota Demo, Provinsi Nusantara',
    coordinates: '-6.200000, 106.816666',
    timestamp: DateTime(2025, 1, 1, 12, 0, 0),
  );

  CameraMode _selectedMode = CameraMode.photo;

  double? _latitude;
  double? _longitude;
  DateTime? _lastLocationUpdateTime;

  List<CameraDescription> _availableCameras = const [];
  int _currentCameraIndex = 0;

  double _zoomLevel = 1.0;
  // Preset yang dipilih user.
  // Catatan: controller kamera bisa punya range zoom yang berbeda tiap device.
  // Jadi nilai preset akan di-clamp ke range aktual controller.
  final List<double> _zoomPresets = const [0.6, 1.0, 2.0];

  bool get _hasController => _controller != null && _controller!.value.isInitialized;

  static const double _targetAspect = 16 / 9;

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
      _logger.error('Failed to request camera permission', e is Object ? e : e.toString());
      return false;
    }
  }

  Widget _buildCameraPreview(BuildContext context) {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator.adaptive(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    final double cameraAspectRaw = controller.value.aspectRatio;
    final double cameraAspect = cameraAspectRaw > 0 ? cameraAspectRaw : _targetAspect;

    // Lebih sederhana & stabil: jaga aspek ratio tanpa clip/crop berlapis.
    return AspectRatio(
      aspectRatio: cameraAspect,
      child: CameraPreview(controller),
    );
  }








  @override
  void initState() {
    super.initState();
    _lastLocationUpdateTime ??= DateTime.now();

    _initializeControllerFuture = _ensureCameraPermission().then((granted) async {
      if (!granted) {
        throw CameraException('CameraPermissionDenied', 'Camera permission not granted');
      }

      await _initCamera();
      await _refreshLocationData(showLoading: false);
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
      await controller.setFlashMode(turnOn ? FlashMode.torch : FlashMode.off);
    } on CameraException catch (e) {
      _logger.error('CameraException while applying flash mode', e);
    } catch (e) {
      _logger.error('Unexpected error while applying flash mode', e);
    }
  }

  Future<void> _switchCamera() async {
    if (_availableCameras.isEmpty) {
      await _initCamera();
      return;
    }

    final current = _availableCameras[_currentCameraIndex];
    final wantLens = current.lensDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;

    final nextIdx = _availableCameras.indexWhere((c) => c.lensDirection == wantLens);
    final fallbackIdx = (_currentCameraIndex + 1) % _availableCameras.length;
    final chosenIdx = nextIdx != -1 ? nextIdx : fallbackIdx;

    await _initCamera(cameraIndex: chosenIdx);
    setState(() => _isFlashOn = false);
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

  Future<void> _refreshLocationData({bool showLoading = false}) async {
    if (showLoading && mounted) {
      setState(() => _locationLoading = true);
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
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
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
          ]
              .whereType<String>()
              .where((s) => s.trim().isNotEmpty)
              .join(', ');

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
        setState(() => _locationLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onCapture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    switch (_selectedMode) {
      case CameraMode.locationShare:
        // Usecase capture -> repository history
        await _captureAndSyncUI(showSuccessSnackBar: true);
        // Keep existing UI behaviour (clipboard share) based on refreshed GPS state
        await _handleLocationShare();
        break;
      case CameraMode.photo:
        // Usecase capture -> repository history
        await _captureAndSyncUI(showSuccessSnackBar: true);
        break;
      case CameraMode.video:
        await _handleVideoRecording(controller);
        break;
      case CameraMode.reporting:
        // Usecase capture -> repository history, then show dialog (uses UI photo preview)
        await _captureAndSyncUI(showSuccessSnackBar: false);
        if (_lastPhoto != null) {
          await _showReportingDialog(_lastPhoto!);
        }
        break;
    }
  }

  Future<void> _handleLocationShare() async {
    await _refreshLocationData(showLoading: true);

    if (_latitude == null || _longitude == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi tidak tersedia. Coba refresh GPS terlebih dahulu.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final maps = 'https://www.google.com/maps?q=$_latitude,$_longitude';
    final shareText = '''
📍 Lokasi Saya

Nama Tempat: ${_meta.locationName}
Alamat: ${_meta.address}
Koordinat: $_latitude, $_longitude
Waktu: ${_formatDateTime(DateTime.now())}

Google Maps: $maps
''';

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

  Future<void> _handlePhotoCapture(CameraController controller) async {
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

      // Basic flow: if locationShare mode, open share sheet.
      if (_selectedMode == CameraMode.locationShare) {
        await _showShareOptions(photo);
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
      _logger.error('Video recording failed', e is Object ? e : e.toString());
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
      setState(() => _lastPhoto = photo);

      await _showReportingDialog(photo);
    } catch (e) {
      _logger.error('Reporting capture failed', e is Object ? e : e.toString());
    }
  }

  Future<void> _showReportingDialog(CapturedPhoto photo) async {
    final notesController = TextEditingController();
    String selectedCategory = 'Umum';
    const categories = ['Umum', 'Infrastruktur', 'Lingkungan', 'Keamanan', 'Lainnya'];

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text('Form Laporan', style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(photo.filePath), height: 120, width: double.infinity, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 16),
                    const Text('Kategori', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      dropdownColor: Colors.grey[800],
                      style: const TextStyle(color: Colors.white),
                      items: categories.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() => selectedCategory = value ?? 'Umum');
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Catatan', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bagikan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        )),
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
                          content: Text('Bagikan foto: fitur share_plus belum diaktifkan'),
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
                    child: const Text('Batal', style: TextStyle(color: Colors.white70)),
                  ),
                )
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
                    const Text('Overlay Elements',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: _overlayConfig.showAddress,
                      title: const Text('Tampilkan alamat lengkap', style: TextStyle(color: Colors.white)),
                      onChanged: (v) {
                        setModalState(() {
                          _overlayConfig = _overlayConfig.copyWith(showAddress: v);
                        });
                        setState(() {});
                      },
                    ),
                    SwitchListTile(
                      value: _overlayConfig.showCoordinates,
                      title: const Text('Tampilkan koordinat', style: TextStyle(color: Colors.white)),
                      onChanged: (v) {
                        setModalState(() {
                          _overlayConfig = _overlayConfig.copyWith(showCoordinates: v);
                        });
                        setState(() {});
                      },
                    ),
                    SwitchListTile(
                      value: _overlayConfig.showTimestamp,
                      title: const Text('Tampilkan timestamp', style: TextStyle(color: Colors.white)),
                      onChanged: (v) {
                        setModalState(() {
                          _overlayConfig = _overlayConfig.copyWith(showTimestamp: v);
                        });
                        setState(() {});
                      },
                    ),
                    SwitchListTile(
                      value: _overlayConfig.showMiniMap,
                      title: const Text('Tampilkan mini map', style: TextStyle(color: Colors.white)),
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
      backgroundColor: Colors.black87,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final primary = Theme.of(context).colorScheme.primary;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Camera Settings', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Watermark', style: TextStyle(color: Colors.white)),
                value: _isWatermarkOn,
                activeColor: primary,
                onChanged: (value) {
                  setState(() => _isWatermarkOn = value);
                },
              ),
              SwitchListTile(
                title: const Text('Flash', style: TextStyle(color: Colors.white)),
                value: _isFlashOn,
                activeColor: primary,
                onChanged: (value) async {
                  setState(() => _isFlashOn = value);
                  await _applyFlashStateSafely(_isFlashOn);
                },
              ),
              SwitchListTile(
                title: const Text('Grid', style: TextStyle(color: Colors.white)),
                value: _showGrid,
                activeColor: primary,
                onChanged: (value) {
                  setState(() => _showGrid = value);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
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
            final msg = snapshot.hasError ? snapshot.error.toString() : 'Camera not initialized';
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
          const targetAspect = 16 / 9;

          return OrientationBuilder(
            builder: (context, orientation) {
              // Frame kamera ditaruh di area yang tersedia agar bisa fill layar.
              // Gunakan height sisa setelah UI overlay (top bar + bottom bar + info overlay).
              final double frameWidth = screenWidth;
              final double frameHeight = MediaQuery.of(context).size.height - 56 - 64; // top bar + bottom bar
              final double safeFrameHeight = frameHeight > 0 ? frameHeight : MediaQuery.of(context).size.height;


              return Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: frameWidth,
                      height: frameHeight,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _tapToFocus,
                        child: _buildCameraPreview(context),
                      ),
                    ),
                  ),

                  if (_showGrid)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: GridPainter(),
                        ),
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
                      lastLocationUpdateTime: _lastLocationUpdateTime,
                      isLoading: _locationLoading,
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
                                    onTap: () => _applyZoom(z),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (z - _zoomLevel).abs() < 0.01
                                            ? Colors.blue.withOpacity(0.25)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color:
                                              (z - _zoomLevel).abs() < 0.01
                                                  ? Colors.blue.withOpacity(0.7)
                                                  : Colors.white.withOpacity(
                                                      0.10,
                                                    ),
                                        ),
                                      ),
                                      child: Text(
                                        '${z.toStringAsFixed(z == 1.0 ? 0 : 1)}x',
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
              if (mode != CameraMode.video) _isRecording = false;
            });
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
    );
  }

  Widget _buildTopControlBar(BuildContext context) {
    return Container(
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
          _TopIconButton(icon: Icons.close, tooltip: 'Tutup kamera', onPressed: () => Navigator.of(context).maybePop()),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TopIconButton(
                icon: _isWatermarkOn ? Icons.water_drop : Icons.water_drop_outlined,
                tooltip: 'Toggle watermark',
                onPressed: () => setState(() => _isWatermarkOn = !_isWatermarkOn),
              ),
              const SizedBox(width: 10),
              _TopIconButton(
                icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                tooltip: 'Toggle flash',
                onPressed: () async {
                  setState(() => _isFlashOn = !_isFlashOn);
                  await _applyFlashStateSafely(_isFlashOn);
                },
              ),
              const SizedBox(width: 10),
              _TopIconButton(icon: Icons.grid_on, tooltip: 'Toggle grid', onPressed: () => setState(() => _showGrid = !_showGrid)),
              const SizedBox(width: 10),
              _TopIconButton(icon: Icons.layers, tooltip: 'Overlay / Templates', onPressed: _onOpenTemplates),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _TopIconButton(icon: Icons.my_location, tooltip: 'Refetch lokasi', onPressed: () => _refreshLocationData(showLoading: true)),
              const SizedBox(width: 10),
              _TopIconButton(icon: Icons.rotate_right, tooltip: 'Rotate camera', onPressed: _switchCamera),
              const SizedBox(width: 10),
              _TopIconButton(icon: Icons.settings, tooltip: 'Settings', onPressed: _onOpenSettings),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoOverlay extends StatelessWidget {
  final CapturedMeta meta;
  final OverlayConfig config;
  final DateTime? lastLocationUpdateTime;
  final bool isLoading;

  const _InfoOverlay({
    required this.meta,
    required this.config,
    required this.lastLocationUpdateTime,
    required this.isLoading,
  });

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $hh:$mm';
  }

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
              const Icon(Icons.location_on, color: Colors.white70, size: 16),
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
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
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
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
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
              Expanded(child: _ModeItem(mode: CameraMode.locationShare, selectedMode: selectedMode, icon: Icons.share_location, label: 'Location Share', onTap: () => onModeChanged(CameraMode.locationShare))),
              Expanded(child: _ModeItem(mode: CameraMode.photo, selectedMode: selectedMode, icon: Icons.photo_camera, label: 'Photo', onTap: () => onModeChanged(CameraMode.photo))),
              Expanded(child: _ModeItem(mode: CameraMode.video, selectedMode: selectedMode, icon: Icons.videocam, label: 'Video', onTap: () => onModeChanged(CameraMode.video))),
              Expanded(child: _ModeItem(mode: CameraMode.reporting, selectedMode: selectedMode, icon: Icons.description, label: 'Reporting', onTap: () => onModeChanged(CameraMode.reporting))),
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
                onTap: () {
                  if (lastPhoto == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Belum ada riwayat foto tracking'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  Navigator.pushNamed(context, AppRoutes.history);
                },
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
                        : Image.file(File(lastPhoto!.filePath), fit: BoxFit.cover),
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
                      shape: selectedMode == CameraMode.video && isRecording ? BoxShape.rectangle : BoxShape.circle,
                      borderRadius: selectedMode == CameraMode.video && isRecording ? BorderRadius.circular(6) : null,
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
                label: const Text('Template', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(2 * size.width / 3, 0), Offset(2 * size.width / 3, size.height), paint);
    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, 2 * size.height / 3), Offset(size.width, 2 * size.height / 3), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

