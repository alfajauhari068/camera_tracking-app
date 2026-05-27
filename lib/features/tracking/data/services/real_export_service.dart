import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../domain/entities/tracking.dart';
import '../../domain/services/export_service.dart';
import '../../domain/services/logger.dart';
import '../../../../core/error/failures.dart';

class RealExportService implements ExportService {
  final Logger logger;

  RealExportService(this.logger);

  @override
  Future<String> exportTrackings(List<Tracking> trackings, String format) async {
    try {
      final exportDir = await _getExportDirectory();
      final fileName = _generateFileName(format);
      final outputFile = File('${exportDir.path}/$fileName');

      final content = _buildExportContent(trackings, format);
      await outputFile.writeAsString(content, flush: true);

      logger.log('[ExportService] Export file created: ${outputFile.path}');
      return outputFile.path;
    } catch (e) {
      logger.error('[ExportService] Failed to generate export file', e);
      throw GenericFailure('Failed to export trackings: $e');
    }
  }

  Future<Directory> _getExportDirectory() async {
    final baseDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${baseDir.path}/CameraTracking/exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir;
  }

  String _generateFileName(String format) {
    final cleanedFormat = format.toLowerCase();
    final timestamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '_');
    return 'export_$timestamp.$cleanedFormat';
  }

  String _buildExportContent(List<Tracking> trackings, String format) {
    switch (format.toUpperCase()) {
      case 'JSON':
        return JsonEncoder.withIndent('  ').convert(
          trackings.map((tracking) => {
            'id': tracking.id,
            'imagePath': tracking.imagePath,
            'latitude': tracking.latitude,
            'longitude': tracking.longitude,
            'address': tracking.address,
            'accuracy': tracking.accuracy,
            'timestamp': tracking.timestamp.toIso8601String(),
            'type': tracking.type.name,
            'report_category': tracking.reportInfo?.category,
            'report_note': tracking.reportInfo?.note,
            'report_severity': tracking.reportInfo?.severity,
          }).toList(),
        );
      case 'CSV':
        return _buildCsv(trackings);
      case 'XLSX':
      case 'PDF':
        return 'Generated export for format $format\n\n${_buildCsv(trackings)}';
      default:
        throw GenericFailure('Format $format tidak didukung untuk export');
    }
  }

  String _buildCsv(List<Tracking> trackings) {
    final rows = <String>[];
    rows.add(
      'id,imagePath,latitude,longitude,address,accuracy,timestamp,type,report_category,report_note,report_severity',
    );
    for (final tracking in trackings) {
      final escapedAddress = tracking.address.replaceAll('"', '""');
      final escapedCategory = tracking.reportInfo?.category.replaceAll('"', '""') ?? '';
      final escapedNote = tracking.reportInfo?.note?.replaceAll('"', '""') ?? '';
      final escapedSeverity = tracking.reportInfo?.severity?.replaceAll('"', '""') ?? '';
      rows.add(
        '"${tracking.id}","${tracking.imagePath}",${tracking.latitude},${tracking.longitude},"$escapedAddress",${tracking.accuracy},"${tracking.timestamp.toIso8601String()}","${tracking.type.name}","$escapedCategory","$escapedNote","$escapedSeverity"',
      );
    }
    return rows.join('\n');
  }
}
