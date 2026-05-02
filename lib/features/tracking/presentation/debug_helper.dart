import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Debug Helper - untuk troubleshoot masalah penyimpanan data
///
/// Gunakan di console atau print statement untuk diagnosa:
/// ```dart
/// await DebugHelper.printStorageStatus();
/// await DebugHelper.printTrackingFilePath();
/// await DebugHelper.printTrackingFileContent();
/// ```
class DebugHelper {
  static const String _fileName = 'tracking.json';

  /// Print full path of tracking storage file
  static Future<void> printTrackingFilePath() async {
    try {
      final file = await _getFile();
      print('');
      print('═' * 70);
      print('📁 TRACKING FILE PATH');
      print('═' * 70);
      print('Path: ${file.path}');
      print('Exists: ${file.existsSync()}');
      if (file.existsSync()) {
        final size = await file.length();
        print('Size: $size bytes');
      }
      print('═' * 70);
      print('');
    } catch (e) {
      print('❌ Error getting file path: $e');
    }
  }

  /// Print raw JSON content from tracking.json
  static Future<void> printTrackingFileContent() async {
    try {
      final file = await _getFile();
      print('');
      print('═' * 70);
      print('📄 TRACKING FILE CONTENT');
      print('═' * 70);

      if (!file.existsSync()) {
        print('⚠️  File does not exist: ${file.path}');
      } else {
        final content = await file.readAsString();
        if (content.isEmpty) {
          print('⚠️  File is empty');
        } else {
          // Format JSON untuk readability
          try {
            final parsed = jsonDecode(content);
            final formatted = jsonEncode(parsed).replaceAll('},{', '},\n{');
            print(formatted);
            print('');
            print('Total items: ${parsed is List ? parsed.length : '?'}');
          } catch (e) {
            print('❌ Invalid JSON format: $e');
            print('Raw content:');
            print(content);
          }
        }
      }
      print('═' * 70);
      print('');
    } catch (e) {
      print('❌ Error reading file content: $e');
    }
  }

  /// Print general storage status
  static Future<void> printStorageStatus() async {
    try {
      print('');
      print('═' * 70);
      print('💾 STORAGE STATUS');
      print('═' * 70);

      final directory = await getApplicationDocumentsDirectory();
      print('App Documents Directory: ${directory.path}');

      final file = await _getFile();
      print('Tracking File: ${file.path}');
      print('File exists: ${file.existsSync()}');

      if (file.existsSync()) {
        final size = await file.length();
        final content = await file.readAsString();
        print('File size: $size bytes');

        try {
          final parsed = jsonDecode(content);
          if (parsed is List) {
            print('JSON items count: ${parsed.length}');

            if (parsed.isNotEmpty) {
              print('\nFirst item sample:');
              print(jsonEncode(parsed[0]));
            }
          }
        } catch (e) {
          print('❌ Cannot parse JSON: $e');
        }
      } else {
        print('⚠️  Tracking file not found - no trackings saved yet');
      }

      print('═' * 70);
      print('');
    } catch (e) {
      print('❌ Error checking storage status: $e');
    }
  }

  /// Clear all tracking data (for testing/debug)
  /// ⚠️  USE WITH CAUTION - This deletes all tracking data!
  static Future<void> clearAllTrackingData() async {
    try {
      final file = await _getFile();
      if (file.existsSync()) {
        await file.delete();
        print('✅ All tracking data cleared!');
      } else {
        print('ℹ️  No tracking data to clear');
      }
    } catch (e) {
      print('❌ Error clearing data: $e');
    }
  }

  /// Get the file
  static Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }
}
