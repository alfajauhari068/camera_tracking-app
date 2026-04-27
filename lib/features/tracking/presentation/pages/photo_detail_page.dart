import 'package:flutter/material.dart';

import '../../../../routes.dart' as app_routes;
import '../../domain/entities/tracking.dart';

/// PHOTO DETAIL PAGE
/// 
/// Tujuan: Menampilkan satu foto dengan metadata lengkap dan action buttons
/// Route: /detail
/// Arguments: trackingId (String) atau tracking (Tracking object)
class PhotoDetailPage extends StatelessWidget {
  // Dapat menerima ID atau object
  final String? trackingId;
  final Tracking? tracking;

  const PhotoDetailPage({
    super.key,
    this.trackingId,
    this.tracking,
  });

  @override
  Widget build(BuildContext context) {
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
            // PHOTO PREVIEW (Large)
            // ===================================================================
            Container(
              width: double.infinity,
              height: 300,
              color: Colors.grey[300],
              child: const Icon(Icons.image, size: 64),
            ),

            const SizedBox(height: 16),

            // ===================================================================
            // METADATA SECTION
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
                    value: tracking?.timestamp.toString() ?? '--',
                  ),

                  const SizedBox(height: 12),

                  // Koordinat (Latitude, Longitude)
                  _MetadataCard(
                    icon: Icons.location_on,
                    label: 'Koordinat GPS',
                    value: tracking != null
                        ? '${tracking!.latitude.toStringAsFixed(6)}, ${tracking!.longitude.toStringAsFixed(6)}'
                        : '--',
                  ),

                  const SizedBox(height: 12),

                  // Alamat
                  _MetadataCard(
                    icon: Icons.place,
                    label: 'Alamat',
                    value: tracking?.address ?? '--',
                  ),

                  const SizedBox(height: 12),

                  // Akurasi
                  _MetadataCard(
                    icon: Icons.router,
                    label: 'Akurasi GPS',
                    value: tracking != null ? '±${tracking!.accuracy.toStringAsFixed(2)} meter' : '--',
                  ),

                  const SizedBox(height: 12),

                  // ID
                  _MetadataCard(
                    icon: Icons.fingerprint,
                    label: 'ID Tracking',
                    value: tracking?.id ?? trackingId ?? '--',
                  ),

                  const SizedBox(height: 24),

                  // ===================================================================
                  // ACTION BUTTONS
                  // ===================================================================
                  Row(
                    children: [
                      // View on Map Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _navigateToMapWithLocation(context),
                          icon: const Icon(Icons.map),
                          label: const Text('View on Map'),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Share/Export Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _navigateToExport(context),
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

  // =========================================================================
  // NAVIGATION METHODS
  // =========================================================================

  /// Navigate ke Map dengan highlight lokasi foto ini
  void _navigateToMapWithLocation(BuildContext context) {
    // TODO: Pass tracking object ke map untuk highlight marker
    app_routes.navigateTo(context, app_routes.AppRoutes.map, arguments: tracking);
  }

  /// Navigate ke Export screen dengan filter preset untuk foto ini
  void _navigateToExport(BuildContext context) {
    // TODO: Pass tracking object ke export untuk preset filter
    app_routes.navigateTo(context, app_routes.AppRoutes.export, arguments: tracking);
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
