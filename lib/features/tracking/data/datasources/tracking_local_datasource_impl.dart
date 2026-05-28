import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../../core/error/failures.dart';
import '../models/tracking_model.dart';
import 'tracking_local_datasource.dart';

class TrackingLocalDataSourceImpl implements TrackingLocalDataSource {
  static const String _fileName = 'tracking.json';

  @override
  Future<List<TrackingModel>> getAll() async {
    try {
      final file = await _getFile();
      print('[TrackingLocalDataSource] Reading from: ${file.path}');

      if (!file.existsSync()) {
        print(
          '[TrackingLocalDataSource] ⚠️  File does not exist: ${file.path}',
        );
        return [];
      }

      final content = await file.readAsString();
      print(
        '[TrackingLocalDataSource] File content length: ${content.length} bytes',
      );

      final List<dynamic> jsonList = jsonDecode(content);
      print(
        '[TrackingLocalDataSource] ✅ Successfully read ${jsonList.length} items from JSON',
      );

      return jsonList
          .map((item) => TrackingModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on StorageFailure {
      rethrow;
    } catch (e) {
      print('[TrackingLocalDataSource] ❌ Error reading data: $e');
      throw StorageFailure('Failed to read tracking data: $e');
    }
  }

  @override
  Future<void> save(TrackingModel model) async {
    try {
      final file = await _getFile();
      print('[TrackingLocalDataSource] Saving to: ${file.path}');
      print('[TrackingLocalDataSource] Model to save: ${model.id}');

      // Get existing data
      List<dynamic> existingData = [];
      if (file.existsSync()) {
        final content = await file.readAsString();
        existingData = jsonDecode(content);
        print(
          '[TrackingLocalDataSource] Existing data count: ${existingData.length}',
        );
      } else {
        print('[TrackingLocalDataSource] Creating new file: ${file.path}');
      }

      // Prepare JSON to save. If image exists, copy it to app documents/images
      final Map<String, dynamic> jsonToSave = Map<String, dynamic>.from(model.toJson());
      final originalImagePath = model.imagePath;
      if (originalImagePath.isNotEmpty) {
        try {
          final original = File(originalImagePath);
          if (original.existsSync()) {
            final dir = await getApplicationDocumentsDirectory();
            final imagesDir = Directory('${dir.path}/images');
            if (!imagesDir.existsSync()) imagesDir.createSync(recursive: true);
            final ext = p.extension(original.path);
            final destPath = '${imagesDir.path}/${model.id}$ext';
            if (original.path != destPath) {
              await original.copy(destPath);
              print('[TrackingLocalDataSource] Copied image to: $destPath');
            }
            jsonToSave['imagePath'] = destPath;
          } else {
            print('[TrackingLocalDataSource] Original image not found: $originalImagePath');
          }
        } catch (e) {
          print('[TrackingLocalDataSource] ❌ Error copying image: $e');
        }
      }

      // Add new data
      existingData.add(jsonToSave);
      print('[TrackingLocalDataSource] New data count: ${existingData.length}');

      // Write back to file
      await file.writeAsString(jsonEncode(existingData));
      print(
        '[TrackingLocalDataSource] ✅ Successfully saved. File size: ${await file.length()} bytes',
      );
    } on StorageFailure {
      rethrow;
    } catch (e) {
      print('[TrackingLocalDataSource] ❌ Error saving data: $e');
      throw StorageFailure('Failed to save tracking data: $e');
    }
  }

  @override
  Future<TrackingModel?> getById(String id) async {
    try {
      final allTrackings = await getAll();
      final tracking = allTrackings
          .where((tracking) => tracking.id == id)
          .firstOrNull;
      print(
        '[TrackingLocalDataSource] getById($id): ${tracking != null ? 'Found' : 'Not found'}',
      );
      return tracking;
    } on StorageFailure {
      rethrow;
    } catch (e) {
      print('[TrackingLocalDataSource] ❌ Error getting tracking by ID: $e');
      throw StorageFailure('Failed to get tracking by ID: $e');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      final file = await _getFile();
      print('[TrackingLocalDataSource] Deleting tracking with ID: $id');

      if (!file.existsSync()) {
        print(
          '[TrackingLocalDataSource] File does not exist, nothing to delete',
        );
        return;
      }

      final content = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);

      // Filter out the tracking with the given ID
      final filteredList = jsonList.where((item) {
        final model = TrackingModel.fromJson(item as Map<String, dynamic>);
        return model.id != id;
      }).toList();

      print(
        '[TrackingLocalDataSource] Deleted count: ${jsonList.length - filteredList.length}',
      );
      print(
        '[TrackingLocalDataSource] Remaining count: ${filteredList.length}',
      );

      // Write back the filtered list
      await file.writeAsString(jsonEncode(filteredList));
      print('[TrackingLocalDataSource] ✅ Successfully deleted');
    } on StorageFailure {
      rethrow;
    } catch (e) {
      print('[TrackingLocalDataSource] ❌ Error deleting tracking: $e');
      throw StorageFailure('Failed to delete tracking: $e');
    }
  }

  /// Get the file path for tracking data
  ///
  /// Debug: Prints the full path untuk reference
  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_fileName');
    print('[TrackingLocalDataSource] File path: ${file.path}');
    return file;
  }
}
