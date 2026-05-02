import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../routes.dart' as app_routes;
import '../../domain/entities/tracking.dart';
import '../providers.dart';

/// PHOTO DETAIL PAGE
/// 
/// Tujuan: Menampilkan satu foto dengan metadata lengkap dan action buttons
/// Route: /detail
/// 
/// Arguments dapat berupa:
/// 1. Tracking object (object): Navigator.pushNamed(..., arguments: tracking)
/// 2. String ID (id): Navigator.pushNamed(..., arguments: trackingId)
/// 
/// Pola yang disarankan: Pass Tracking object jika tersedia (dari Gallery)
/// Jika hanya ID tersedia, page akan load dari repository
class PhotoDetailPage extends ConsumerStatefulWidget {
  const PhotoDetailPage({super.key});

  @override
  ConsumerState<PhotoDetailPage> createState() => _PhotoDetailPageState();
}

class _PhotoDetailPageState extends ConsumerState<PhotoDetailPage> {
  Tracking? _tracking;
  bool _isLoading = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Extract argument dari route settings
    final args = ModalRoute.of(context)?.settings.arguments;
    
    if (args == null) {
      setState(() {
        _error = 'No tracking data provided';
      });
      return;
    }

    // =========================================================================
    // PATTERN 1: Argument adalah Tracking object (dari Gallery)
    // =========================================================================
    if (args is Tracking) {
      setState(() {
        _tracking = args;
      });
      return;
    }

    // =========================================================================
    // PATTERN 2: Argument adalah String ID
    // =========================================================================
    if (args is String) {
      _loadTrackingById(args);
      return;
    }

    setState(() {
      _error = 'Invalid argument type: ${args.runtimeType}';
    });
  }

  /// Load tracking dari repository menggunakan ID
  /// Digunakan jika hanya ID yang dikirim ke route
  Future<void> _loadTrackingById(String trackingId) async {
    if (_isLoading) return; // Prevent duplicate loads

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final useCase = ref.read(getTrackingByIdProvider);
      final tracking = await useCase.execute(trackingId);

      if (tracking == null) {
        setState(() {
          _error = 'Tracking not found (ID: $trackingId)';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _tracking = tracking;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load tracking: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // =========================================================================
    // ERROR STATE
    // =========================================================================
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Photo Detail')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text(_error!),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Back'),
              ),
            ],
          ),
        ),
      );
    }

    // =========================================================================
    // LOADING STATE
    // =========================================================================
    if (_isLoading || _tracking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Photo Detail')),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final tracking = _tracking!;

    // =========================================================================
    // DISPLAY STATE
    // =========================================================================
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Detail'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===================================================================
            // 🖼️ PHOTO PREVIEW (Large)
            // ===================================================================
            Container(
              width: double.infinity,
              height: 300,
              color: Colors.grey[300],
              child: _buildPhotoPreview(tracking),
            ),

            const SizedBox(height: 16),

            // ===================================================================
            // 📊 METADATA SECTION
            // ===================================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tanggal & Waktu
                  _MetadataCard(
                    icon: Icons.access_time,
                    label: 'Tanggal & Waktu',
                    value: _formatDateTime(tracking.timestamp),
                  ),

                  const SizedBox(height: 12),

                  // Koordinat (Latitude, Longitude)
                  _MetadataCard(
                    icon: Icons.location_on,
                    label: 'Koordinat GPS',
                    value: '${tracking.latitude.toStringAsFixed(6)}, ${tracking.longitude.toStringAsFixed(6)}',
                  ),

                  const SizedBox(height: 12),

                  // Alamat
                  _MetadataCard(
                    icon: Icons.place,
                    label: 'Alamat',
                    value: tracking.address,
                  ),

                  const SizedBox(height: 12),

                  // Akurasi
                  _MetadataCard(
                    icon: Icons.router,
                    label: 'Akurasi GPS',
                    value: '±${tracking.accuracy.toStringAsFixed(2)} meter',
                  ),

                  const SizedBox(height: 12),

                  // ID
                  _MetadataCard(
                    icon: Icons.fingerprint,
                    label: 'ID Tracking',
                    value: tracking.id,
                  ),

                  const SizedBox(height: 24),

                  // ===================================================================
                  // 🔘 ACTION BUTTONS
                  // ===================================================================
                  Row(
                    children: [
                      // View on Map Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _navigateToMapWithLocation(context, tracking),
                          icon: const Icon(Icons.map),
                          label: const Text('View on Map'),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Share/Export Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _navigateToExport(context, tracking),
                          icon: const Icon(Icons.share),
                          label: const Text('Share'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build photo preview area
  /// ✅ Load actual photo menggunakan Image.file()
  /// ✅ Fallback ke placeholder jika file invalid
  Widget _buildPhotoPreview(Tracking tracking) {
    // Check if imagePath is valid
    if (tracking.imagePath.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'No image path',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Image.file(
      File(tracking.imagePath),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 64, color: Colors.red),
              SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Failed to load image\nPath: ${tracking.imagePath}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================================================================
  // NAVIGATION METHODS
  // =========================================================================

  /// Navigate ke Map dengan highlight lokasi foto ini
  void _navigateToMapWithLocation(BuildContext context, Tracking tracking) {
    app_routes.navigateTo(
      context,
      app_routes.AppRoutes.map,
      arguments: tracking,
    );
  }

  /// Navigate ke Export screen dengan filter preset untuk foto ini
  void _navigateToExport(BuildContext context, Tracking tracking) {
    app_routes.navigateTo(
      context,
      app_routes.AppRoutes.export,
      arguments: tracking,
    );
  }

  /// Format DateTime untuk display
  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

// =============================================================================
// HELPER WIDGETS
// =============================================================================

/// Metadata card untuk menampilkan satu info (icon + label + value)
class _MetadataCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetadataCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
