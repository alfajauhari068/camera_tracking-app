import 'package:flutter/material.dart' show ThemeMode;

/// =============================================================================
/// APP SETTINGS MODEL
/// =============================================================================
/// 
/// Model untuk menyimpan pengaturan aplikasi
/// Binding ke SharedPreferences/DataStore
class AppSettings {
  final ThemeMode themeMode;
  final DistanceUnit distanceUnit;
  final SpeedUnit speedUnit;
  final bool showGridLine;
  final bool showOverlayInfo;
  final int locationUpdateInterval;  // dalam detik

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.distanceUnit = DistanceUnit.kilometer,
    this.speedUnit = SpeedUnit.kmh,
    this.showGridLine = false,
    this.showOverlayInfo = true,
    this.locationUpdateInterval = 5,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    DistanceUnit? distanceUnit,
    SpeedUnit? speedUnit,
    bool? showGridLine,
    bool? showOverlayInfo,
    int? locationUpdateInterval,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      speedUnit: speedUnit ?? this.speedUnit,
      showGridLine: showGridLine ?? this.showGridLine,
      showOverlayInfo: showOverlayInfo ?? this.showOverlayInfo,
      locationUpdateInterval: locationUpdateInterval ?? this.locationUpdateInterval,
    );
  }

  /// Convert ke Map untuk SharedPreferences
  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode.index,
      'distanceUnit': distanceUnit.index,
      'speedUnit': speedUnit.index,
      'showGridLine': showGridLine,
      'showOverlayInfo': showOverlayInfo,
      'locationUpdateInterval': locationUpdateInterval,
    };
  }

  /// Load dari Map (SharedPreferences)
  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      themeMode: ThemeMode.values[map['themeMode'] ?? 0],
      distanceUnit: DistanceUnit.values[map['distanceUnit'] ?? 0],
      speedUnit: SpeedUnit.values[map['speedUnit'] ?? 0],
      showGridLine: map['showGridLine'] ?? false,
      showOverlayInfo: map['showOverlayInfo'] ?? true,
      locationUpdateInterval: map['locationUpdateInterval'] ?? 5,
    );
  }

  String get themeModeDisplayName {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'Follow System';
    }
  }

  String get themeModeDescription {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Bright theme for day use';
      case ThemeMode.dark:
        return 'Easy on eyes in low light';
      case ThemeMode.system:
        return 'Match device settings';
    }
  }
}

/// Distance unit enum
enum DistanceUnit {
  meter,
  kilometer,
}

extension DistanceUnitExtension on DistanceUnit {
  String get displayName {
    switch (this) {
      case DistanceUnit.meter:
        return 'Meter (m)';
      case DistanceUnit.kilometer:
        return 'Kilometer (km)';
    }
  }

  String get shortName {
    switch (this) {
      case DistanceUnit.meter:
        return 'm';
      case DistanceUnit.kilometer:
        return 'km';
    }
  }
}

/// Speed unit enum
enum SpeedUnit {
  kmh,
  mph,
}

extension SpeedUnitExtension on SpeedUnit {
  String get displayName {
    switch (this) {
      case SpeedUnit.kmh:
        return 'Km/jam';
      case SpeedUnit.mph:
        return 'Mil/jam';
    }
  }
}

/// Location update interval options
class LocationIntervalOption {
  final int seconds;
  final String displayName;

  const LocationIntervalOption({
    required this.seconds,
    required this.displayName,
  });

  static const List<LocationIntervalOption> options = [
    LocationIntervalOption(seconds: 1, displayName: '1 detik'),
    LocationIntervalOption(seconds: 3, displayName: '3 detik'),
    LocationIntervalOption(seconds: 5, displayName: '5 detik'),
    LocationIntervalOption(seconds: 10, displayName: '10 detik'),
    LocationIntervalOption(seconds: 30, displayName: '30 detik'),
  ];
}

/// =============================================================================
/// DUMMY DATA
/// =============================================================================
class AppSettingsDummy {
  static AppSettings getDefault() => const AppSettings();

  static AppSettings getCustom() => const AppSettings(
    themeMode: ThemeMode.dark,
    distanceUnit: DistanceUnit.kilometer,
    speedUnit: SpeedUnit.kmh,
    showGridLine: true,
    showOverlayInfo: true,
    locationUpdateInterval: 5,
  );
}
