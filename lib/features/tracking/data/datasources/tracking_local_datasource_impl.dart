import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../../core/error/failures.dart';
import '../models/tracking_model.dart';
import 'tracking_local_datasource.dart';

class TrackingLocalDataSourceImpl implements TrackingLocalDataSource {
  static const String _fileName = 'tracking.json';

  @override
  Future<List<TrackingModel>> getAll() async {
    try {
      final file = await _getFile();

      if (!file.existsSync()) {
        return [];
      }

      final content = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);

      return jsonList
          .map((item) => TrackingModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on StorageFailure {
      rethrow;
    } catch (e) {
      throw StorageFailure('Failed to read tracking data: $e');
    }
  }

  @override
  Future<void> save(TrackingModel model) async {
    try {
      final file = await _getFile();

      // Get existing data
      List<dynamic> existingData = [];
      if (file.existsSync()) {
        final content = await file.readAsString();
        existingData = jsonDecode(content);
      }

      // Add new data
      existingData.add(model.toJson());

      // Write back to file
      await file.writeAsString(jsonEncode(existingData));
    } on StorageFailure {
      rethrow;
    } catch (e) {
      throw StorageFailure('Failed to save tracking data: $e');
    }
  }

  @override
  Future<TrackingModel?> getById(String id) async {
    try {
      final allTrackings = await getAll();
      return allTrackings.where((tracking) => tracking.id == id).firstOrNull;
    } on StorageFailure {
      rethrow;
    } catch (e) {
      throw StorageFailure('Failed to get tracking by ID: $e');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      final file = await _getFile();

      if (!file.existsSync()) {
        return; // Nothing to delete
      }

      final content = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);

      // Filter out the tracking with the given ID
      final filteredList = jsonList.where((item) {
        final model = TrackingModel.fromJson(item as Map<String, dynamic>);
        return model.id != id;
      }).toList();

      // Write back the filtered list
      await file.writeAsString(jsonEncode(filteredList));
    } on StorageFailure {
      rethrow;
    } catch (e) {
      throw StorageFailure('Failed to delete tracking: $e');
    }
  }

  /// Get the file path for tracking data
  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }
}
