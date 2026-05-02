import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/entities/tracking.dart';

/// PhotoCard widget untuk menampilkan individual tracking photo dalam grid
/// 
/// Menampilkan:
/// - Placeholder atau actual image dari tracking.imagePath
/// - Overlay dengan alamat (address) dan waktu (timestamp)
/// - Support untuk tap action (navigasi ke detail)
class PhotoCard extends StatelessWidget {
  final Tracking tracking;
  final VoidCallback? onTap;

  const PhotoCard({
    super.key,
    required this.tracking,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[300],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ================================================================
            // IMAGE AREA
            // ================================================================
            // Load actual image dari tracking.imagePath
            Image.file(
              File(tracking.imagePath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback ke placeholder jika file tidak found atau invalid
                return _buildPlaceholder();
              },
            ),

            // ================================================================
            // INFORMATION OVERLAY
            // ================================================================
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Address
                    Text(
                      tracking.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Timestamp
                    Text(
                      _formatDateTime(tracking.timestamp),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ================================================================
            // ACCURACY BADGE (optional)
            // ================================================================
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '±${tracking.accuracy.toStringAsFixed(0)}m',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build placeholder image (sebelum actual image dimuat)
  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Icon(
        Icons.image,
        size: 40,
        color: Colors.grey,
      ),
    );
  }

  /// Format DateTime untuk tampilan ringkas
  /// Format: DD/MM/YYYY HH:MM
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
