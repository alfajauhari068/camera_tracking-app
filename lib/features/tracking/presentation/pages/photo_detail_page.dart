import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../routes.dart' as app_routes;
import '../../domain/entities/tracking.dart';
import '../providers.dart';
import '../tracking_providers.dart';
import '../widgets/report_badge.dart';

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
      // temporary resolver: use local repository directly (avoids missing provider)
      final tracking = await ref.read(trackingRepositoryProvider).getTrackingById(trackingId);


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
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final tracking = _tracking!;
    final isReporting = tracking.type == TrackingType.reporting;
    final reportInfo = tracking.reportInfo;
    final theme = Theme.of(context);

    // =========================================================================
    // DISPLAY STATE
    // =========================================================================
    return Scaffold(
      appBar: AppBar(title: const Text('Photo Detail'), elevation: 0),
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
                  if (isReporting) ...[
                    const ReportBadge(),
                    const SizedBox(height: 16),
                  ],

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
                    value:
                        '${tracking.latitude.toStringAsFixed(6)}, ${tracking.longitude.toStringAsFixed(6)}',
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

                  if (isReporting && reportInfo != null) ...[
                    const SizedBox(height: 16),
                    Text('Detail Laporan', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Kategori laporan', style: theme.textTheme.labelMedium),
                    const SizedBox(height: 4),
                    Text(reportInfo.category, style: theme.textTheme.bodyMedium),
                    if (reportInfo.severity?.isNotEmpty == true) ...[
                      const SizedBox(height: 12),
                      Text('Tingkat keparahan', style: theme.textTheme.labelMedium),
                      const SizedBox(height: 4),
                      Text(
                        _readableSeverity(reportInfo.severity),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text('Catatan', style: theme.textTheme.labelMedium),
                    const SizedBox(height: 4),
                    Text(
                      reportInfo.note?.isNotEmpty == true ? reportInfo.note! : '-',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                  ],

                  const SizedBox(height: 24),

                  // ===================================================================
                  // 🔘 ACTION BUTTONS
                  // ===================================================================
                  Row(
                    children: [
                      // View on Map Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _navigateToMapWithLocation(context, tracking),
                          icon: const Icon(Icons.map),
                          label: const Text('View on Map'),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Share/Export Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _shareTracking(context, tracking),
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
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _deleteTracking(context, tracking),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Hapus Foto'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ),
    );
  }

  /// Build photo preview area
  /// ✅ Load actual photo menggunakan Image.file()
  /// ✅ Fallback ke placeholder jika file invalid
  Widget _buildPhotoPreview(Tracking tracking) {
    final path = tracking.imagePath;
    final file = File(path);

    if (path.isEmpty || !file.existsSync()) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
            SizedBox(height: 8),
            Text('No image ditemukan', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 64, color: Colors.red),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Gagal memuat gambar\nPath: $path',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
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

  Future<void> _deleteTracking(BuildContext context, Tracking tracking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus foto?'),
        content: const Text('Tindakan ini akan menghapus foto dan data tracking terkait.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(trackingRepositoryProvider).deleteTracking(tracking.id);
      ref.invalidate(trackingListProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Share tracking data dengan foto dan link Google Maps
  void _shareTracking(BuildContext context, Tracking tracking) {
    final googleMapsUrl =
        'https://www.google.com/maps/place/${tracking.latitude},${tracking.longitude}';

    final baseText = '''
Alamat: ${tracking.address}
Koordinat: ${tracking.latitude.toStringAsFixed(6)}, ${tracking.longitude.toStringAsFixed(6)}
Akurasi: ${tracking.accuracy.toStringAsFixed(2)} meter
Waktu: ${_formatDateTime(tracking.timestamp)}

Lihat di Google Maps: $googleMapsUrl
''';

    final severityText = tracking.reportInfo?.severity;
    final severityLine = severityText?.isNotEmpty == true
        ? 'Tingkat keparahan: ${_readableSeverity(severityText)}\n'
        : '';

    final shareText = tracking.type == TrackingType.reporting &&
            tracking.reportInfo != null
        ? 'Laporan lapangan:\n'
            'Kategori: ${tracking.reportInfo!.category}\n'
            '$severityLine'
            'Catatan: ${tracking.reportInfo!.note ?? '-'}\n'
            '$baseText'
        : 'Foto dokumentasi:\n$baseText';

    // Share foto bersama dengan pesan teks
    final imageFile = XFile(tracking.imagePath);
    Share.shareXFiles([imageFile], text: shareText);
  }

  String _readableSeverity(String? severity) {
    if (severity == null || severity.isEmpty) return '-';

    switch (severity.toLowerCase()) {
      case 'low':
        return 'Rendah';
      case 'medium':
        return 'Sedang';
      case 'high':
        return 'Tinggi';
      default:
        return severity[0].toUpperCase() + severity.substring(1);
    }
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
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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
