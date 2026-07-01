import 'dart:io';

import 'package:share_plus/share_plus.dart';

import '../utils/app_logger.dart';

class ShareServiceException implements Exception {
  ShareServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ShareService {
  const ShareService([this._logger = const AppLogger(tag: 'ShareService')]);

  final AppLogger _logger;

  Future<void> shareLocationText({
    required String? locationName,
    required String? address,
    required double? latitude,
    required double? longitude,
    required DateTime timestamp,
  }) async {
    if (latitude == null || longitude == null) {
      throw ShareServiceException('Koordinat lokasi tidak tersedia.');
    }

    final location = locationName?.trim().isNotEmpty == true
        ? locationName!.trim()
        : 'Unknown';
    final locationAddress = address?.trim().isNotEmpty == true
        ? address!.trim()
        : 'Unknown';

    final shareText =
        '''
Lokasi:
$location

Alamat:
$locationAddress

Koordinat:
${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}

Tanggal:
${_formatDateTime(timestamp)}

Google Maps:
https://maps.google.com/?q=${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}
''';

    try {
      _logger.info('Starting location share');
      await Share.share(shareText);
      _logger.info('Location share completed');
    } catch (error, stackTrace) {
      _logger.error('Location share failed', error, stackTrace);
      throw ShareServiceException('Gagal membagikan teks lokasi.');
    }
  }

  Future<void> sharePhotoWithText({
    required String filePath,
    String? locationName,
    String? address,
    double? latitude,
    double? longitude,
    required DateTime timestamp,
  }) async {
    if (filePath.trim().isEmpty) {
      throw ShareServiceException('File foto tidak tersedia.');
    }

    final file = File(filePath);
    if (!await file.exists()) {
      throw ShareServiceException('File foto tidak ditemukan.');
    }

    final location = locationName?.trim().isNotEmpty == true
        ? locationName!.trim()
        : 'Unknown';
    final locationAddress = address?.trim().isNotEmpty == true
        ? address!.trim()
        : 'Unknown';
    final coordinates = latitude != null && longitude != null
        ? '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}'
        : '-';

    final shareText =
        '''
Lokasi:
$location

Alamat:
$locationAddress

Koordinat:
$coordinates

Tanggal:
${_formatDateTime(timestamp)}

Google Maps:
https://maps.google.com/?q=${latitude?.toStringAsFixed(6) ?? 0},${longitude?.toStringAsFixed(6) ?? 0}
''';

    try {
      _logger.info('Starting photo share for file: $filePath');
      final imageFile = XFile(filePath);
      await Share.shareXFiles([imageFile], text: shareText);
      _logger.info('Photo share completed');
    } catch (error, stackTrace) {
      _logger.error('Photo share failed', error, stackTrace);
      throw ShareServiceException('Gagal membagikan foto.');
    }
  }

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}
