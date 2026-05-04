import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_settings.dart';

/// =============================================================================
/// APP SETTINGS PROVIDER
/// =============================================================================
/// AsyncNotifierProvider untuk AppSettings dengan SharedPreferences persistence
class AppSettingsNotifier extends AsyncNotifier<AppSettings> {
  static final appSettingsProvider = AsyncNotifierProvider<AppSettingsNotifier, AppSettings>(
    () => AppSettingsNotifier(),
  );

  /// Load settings dari SharedPreferences saat init
  @override
  Future<AppSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    final map = prefs.getString('app_settings');
    
    if (map != null) {
      try {
        final data = Map<String, dynamic>.from(jsonDecode(map));
        return AppSettings.fromMap(data);
      } catch (e) {
        debugPrint('Error loading settings: $e');
      }
    }
    
    return const AppSettings();
  }

  /// Update single setting dan save ke SharedPreferences
  Future<void> updateThemeMode(ThemeMode themeMode) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final current = state.value ?? const AppSettings();
      final updated = current.copyWith(themeMode: themeMode);
      await _saveToPrefs(updated);
      return updated;
    });
  }

  Future<void> updateDistanceUnit(DistanceUnit distanceUnit) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final current = state.value ?? const AppSettings();
      final updated = current.copyWith(distanceUnit: distanceUnit);
      await _saveToPrefs(updated);
      return updated;
    });
  }

  Future<void> updateSpeedUnit(SpeedUnit speedUnit) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final current = state.value ?? const AppSettings();
      final updated = current.copyWith(speedUnit: speedUnit);
      await _saveToPrefs(updated);
      return updated;
    });
  }

  Future<void> updateShowGridLine(bool showGridLine) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final current = state.value ?? const AppSettings();
      final updated = current.copyWith(showGridLine: showGridLine);
      await _saveToPrefs(updated);
      return updated;
    });
  }

  Future<void> updateShowOverlayInfo(bool showOverlayInfo) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final current = state.value ?? const AppSettings();
      final updated = current.copyWith(showOverlayInfo: showOverlayInfo);
      await _saveToPrefs(updated);
      return updated;
    });
  }

  Future<void> updateLocationInterval(int interval) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final current = state.value ?? const AppSettings();
      final updated = current.copyWith(locationUpdateInterval: interval);
      await _saveToPrefs(updated);
      return updated;
    });
  }

  /// Save ke SharedPreferences
  Future<void> _saveToPrefs(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_settings', jsonEncode(settings.toMap()));
  }
}
