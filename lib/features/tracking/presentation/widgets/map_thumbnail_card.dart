import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/entities/tracking.dart';

/// MapThumbnailCard - Thumbnail untuk horizontal list di map
///
/// Menampilkan:
/// - Preview image dari tracking.imagePath jika tersedia
/// - Address singkat di bawah
/// - Highlight border jika selected
/// - Coordinates kecil sebagai label
class MapThumbnailCard extends StatelessWidget {
  final Tracking tracking;
  final bool isSelected;
  final VoidCallback onTap;

  const MapThumbnailCard({
    super.key,
    required this.tracking,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage =
        tracking.imagePath.isNotEmpty && File(tracking.imagePath).existsSync();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
          color: Colors.grey[300],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                  color: Colors.grey[300],
                  image: hasImage
                      ? DecorationImage(
                          image: FileImage(File(tracking.imagePath)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: hasImage
                    ? null
                    : const Center(
                        child: Icon(Icons.image, size: 32, color: Colors.grey),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tracking.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${tracking.latitude.toStringAsFixed(4)}, ${tracking.longitude.toStringAsFixed(4)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
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
