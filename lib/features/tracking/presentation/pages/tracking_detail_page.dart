import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/entities/tracking_detail_ui_model.dart';

/// =============================================================================
/// TRACKING DETAIL PAGE
/// =============================================================================
/// 
/// Menampilkan detail satu tracking item:
/// - Judul (waktu + jenis event)
/// - Peta mini (placeholder)
/// - Info lokasi (lat, lng, alamat)
/// - Durasi/jarak (jika tracking session)
/// - Foto (jika ada)
/// - Tombol Share/Export
/// 
/// Route: /tracking-detail
/// Arguments: TrackingDetailUiModel
class TrackingDetailPage extends StatelessWidget {
  const TrackingDetailPage({
    super.key,
    TrackingDetailUiModel? data,
  }) : _data = data;

  final TrackingDetailUiModel? _data;

  TrackingDetailUiModel get _effectiveData => _data ?? TrackingDetailDummy.getDummy();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),  // Dark background
      appBar: AppBar(
        title: const Text('Detail'),
        backgroundColor: const Color(0xFF1a237e),  // Navy
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildMapPlaceholder(),
            _buildLocationInfo(),
            if (_effectiveData.isTrackingSession) _buildTrackingInfo(),
            if (_effectiveData.hasImage) _buildPhotoPreview(),
            const SizedBox(height: 24),
            _buildShareButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // HEADER: Waktu + Jenis Event
  // =========================================================================

  Widget _buildHeader() {
    final isTracking = _effectiveData.isTrackingSession;
    final statusColor = isTracking 
        ? const Color(0xFF00e676)  // Neon green
        : const Color(0xFF64b5f6);  // Blue
    
    final statusText = isTracking ? 'Tracking Session' : 'Snapshot';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1e1e1e),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _effectiveData.formattedDateTime,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: statusColor, width: 1),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // MAP PLACEHOLDER
  // =========================================================================

  Widget _buildMapPlaceholder() {
    return Container(
      height: 180,
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1e1e1e),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map, size: 48, color: Colors.grey[600]),
                const SizedBox(height: 8),
                Text('Peta Lokasi', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                const SizedBox(height: 4),
                Text(_effectiveData.coordinatesDisplay, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
              ],
            ),
          ),
          Center(
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00e676),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00e676).withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // LOCATION INFO
  // =========================================================================

  Widget _buildLocationInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1e1e1e),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Informasi Lokasi', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.location_on, label: 'Koordinat', value: _effectiveData.coordinatesDisplay),
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.gps_fixed, label: 'Akurasi', value: _effectiveData.accuracyDisplay),
          if (_effectiveData.address != null && _effectiveData.address!.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(color: Colors.grey, height: 1),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.place, label: 'Alamat', value: _effectiveData.address!),
          ],
        ],
      ),
    );
  }

  // =========================================================================
  // TRACKING INFO (Duration + Distance)
  // =========================================================================

  Widget _buildTrackingInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1e1e1e),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tracking Session', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _InfoCard(icon: Icons.timer, label: 'Durasi', value: _effectiveData.durationDisplay)),
              const SizedBox(width: 12),
              Expanded(child: _InfoCard(icon: Icons.straighten, label: 'Jarak', value: _effectiveData.distanceDisplay)),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // PHOTO PREVIEW
  // =========================================================================

  Widget _buildPhotoPreview() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Foto', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: const Color(0xFF2c2c2c),
                child: () {
                  final imagePath = _effectiveData.imagePath;
                  if (imagePath == null || imagePath.isEmpty) {
                    return _buildPhotoPlaceholder();
                  }
                  try {
                    final imageFile = File(imagePath);
                    if (!imageFile.existsSync()) {
                      return _buildPhotoPlaceholder();
                    }
                    return Image.file(
                      imageFile,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPhotoPlaceholder(),
                    );
                  } catch (_) {
                    return _buildPhotoPlaceholder();
                  }
                }(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 8),
          Text('Preview Foto', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  // =========================================================================
  // SHARE BUTTON
  // =========================================================================

  Widget _buildShareButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: _onShare,
          icon: const Icon(Icons.share, size: 24),
          label: const Text('Share / Export', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00e676),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  void _onShare() {
    // TODO: Implement share functionality
  }
}

// =============================================================================
// HELPER WIDGETS
// =============================================================================

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[500]),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2c2c2c),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: const Color(0xFF00e676)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
