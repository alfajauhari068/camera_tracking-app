import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';

/// SettingsService - Single source of truth untuk semua settings Camera Tracking GPS
class SettingsService {
  static const String _key = 'camera_tracking_settings';
  static SettingsService? _instance;
  
  factory SettingsService() => _instance ??= SettingsService._();
  SettingsService._();

  SettingsModel _settings = const SettingsModel();

  /// Load settings dari SharedPreferences
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString != null) {
      try {
        final map = jsonDecode(jsonString) as Map<String, dynamic>;
        _settings = SettingsModel.fromMap(map);
        if (kDebugMode) debugPrint('Settings loaded: ${_settings.appLanguage}');
      } catch (e) {
        if (kDebugMode) debugPrint('Error loading settings: $e - using defaults');
        _settings = const SettingsModel();
      }
    }
  }

  /// Save settings ke SharedPreferences
  Future<void> saveSettings(SettingsModel settings) async {
    _settings = settings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, settings.toJson());
    if (kDebugMode) debugPrint('Settings saved: ${settings.officerName}');
  }

  /// Current settings (non-nullable)
  SettingsModel get currentSettings => _settings;

  // ========== GPS SETTINGS ==========
  Future<void> updateAccuracyMode(String value) async {
    _settings = _settings.copyWith(accuracyMode: value);
    await saveSettings(_settings);
  }

  Future<void> updateLocationSource(String value) async {
    _settings = _settings.copyWith(locationSource: value);
    await saveSettings(_settings);
  }

  Future<void> updateShowCoordinatesInDetail(bool value) async {
    _settings = _settings.copyWith(showCoordinatesInDetail: value);
    await saveSettings(_settings);
  }

  // ========== PHOTO SETTINGS ==========
  Future<void> updatePhotoQuality(String value) async {
    _settings = _settings.copyWith(photoQuality: value);
    await saveSettings(_settings);
  }

  Future<void> updateDuplicateToGallery(bool value) async {
    _settings = _settings.copyWith(duplicateToGallery: value);
    await saveSettings(_settings);
  }

  // ========== METADATA ==========
  Future<void> updateDateTimeFormat(String value) async {
    _settings = _settings.copyWith(dateTimeFormat: value);
    await saveSettings(_settings);
  }

  Future<void> updateGalleryMetadataOptions(List<String> values) async {
    _settings = _settings.copyWith(galleryMetadataOptions: values);
    await saveSettings(_settings);
  }

  // ========== MAP ==========
  Future<void> updateMapType(String value) async {
    _settings = _settings.copyWith(mapType: value);
    await saveSettings(_settings);
  }

  Future<void> updateInitialZoomLevel(String value) async {
    _settings = _settings.copyWith(initialZoomLevel: value);
    await saveSettings(_settings);
  }

  Future<void> updateShowMyLocationOnMap(bool value) async {
    _settings = _settings.copyWith(showMyLocationOnMap: value);
    await saveSettings(_settings);
  }

  // ========== EXPORT ==========
  Future<void> updateExportFormat(String value) async {
    _settings = _settings.copyWith(exportFormat: value);
    await saveSettings(_settings);
  }

  Future<void> updateExportColumns(List<String> values) async {
    _settings = _settings.copyWith(exportColumns: values);
    await saveSettings(_settings);
  }

  // ========== USER ==========
  Future<void> updateOfficerName(String value) async {
    _settings = _settings.copyWith(officerName: value);
    await saveSettings(_settings);
  }

  Future<void> updateActiveProject(String value) async {
    _settings = _settings.copyWith(activeProject: value);
    await saveSettings(_settings);
  }

  // ========== LANGUAGE ==========
  Future<void> updateAppLanguage(String value) async {
    _settings = _settings.copyWith(appLanguage: value);
    await saveSettings(_settings);
  }
}

/// Global singleton instance
final settingsService = SettingsService();

