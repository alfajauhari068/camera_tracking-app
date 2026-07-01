import 'dart:convert';

/// @immutable
/// SettingsModel - Central configuration for Camera Tracking GPS app
class SettingsModel {
  // Section 1 – Lokasi & GPS
  final String accuracyMode; // 'high' / 'standard'
  final String locationSource; // 'gpsOnly' / 'gpsAndNetwork'
  final bool showCoordinatesInDetail;

  // Section 2 – Foto & Penyimpanan
  final String photoQuality; // 'high' / 'medium' / 'low'
  final bool duplicateToGallery;

  // Section 3 – Metadata & Tampilan
  final String dateTimeFormat; // '24h_ddMMyyyy' / '12h_yyyyMMdd'
  final List<String> galleryMetadataOptions; // ['address_short', 'coordinates', 'tracking_id', 'project_name']

  // Section 4 – Map & Peta
  final String mapType; // 'standard' / 'satellite'
  final String initialZoomLevel; // 'near' / 'medium' / 'far'
  final bool showMyLocationOnMap;

  // Section 5 – Export & Laporan
  final String exportFormat; // 'csv' / 'xlsx' / 'pdf' / 'json'
  final List<String> exportColumns; // ['coordinates', 'full_address', 'gps_accuracy', 'note', 'project_name']

  // Section 6 – Identitas Petugas & Proyek
  final String officerName;
  final String activeProject;

  // Section 7 – Umum (Language)
  final String appLanguage; // 'id' / 'en'

  const SettingsModel({
    this.accuracyMode = 'standard',
    this.locationSource = 'gpsAndNetwork',
    this.showCoordinatesInDetail = true,
    this.photoQuality = 'medium',
    this.duplicateToGallery = false,
    this.dateTimeFormat = '24h_ddMMyyyy',
    this.galleryMetadataOptions = const ['address_short', 'coordinates', 'tracking_id', 'project_name'],
    this.mapType = 'standard',
    this.initialZoomLevel = 'medium',
    this.showMyLocationOnMap = true,
    this.exportFormat = 'csv',
    this.exportColumns = const ['coordinates', 'full_address', 'gps_accuracy', 'note', 'project_name'],
    this.officerName = '',
    this.activeProject = 'Umum',
    this.appLanguage = 'id',
  });

  SettingsModel copyWith({
    String? accuracyMode,
    String? locationSource,
    bool? showCoordinatesInDetail,
    String? photoQuality,
    bool? duplicateToGallery,
    String? dateTimeFormat,
    List<String>? galleryMetadataOptions,
    String? mapType,
    String? initialZoomLevel,
    bool? showMyLocationOnMap,
    String? exportFormat,
    List<String>? exportColumns,
    String? officerName,
    String? activeProject,
    String? appLanguage,
  }) {
    return SettingsModel(
      accuracyMode: accuracyMode ?? this.accuracyMode,
      locationSource: locationSource ?? this.locationSource,
      showCoordinatesInDetail: showCoordinatesInDetail ?? this.showCoordinatesInDetail,
      photoQuality: photoQuality ?? this.photoQuality,
      duplicateToGallery: duplicateToGallery ?? this.duplicateToGallery,
      dateTimeFormat: dateTimeFormat ?? this.dateTimeFormat,
      galleryMetadataOptions: galleryMetadataOptions ?? this.galleryMetadataOptions,
      mapType: mapType ?? this.mapType,
      initialZoomLevel: initialZoomLevel ?? this.initialZoomLevel,
      showMyLocationOnMap: showMyLocationOnMap ?? this.showMyLocationOnMap,
      exportFormat: exportFormat ?? this.exportFormat,
      exportColumns: exportColumns ?? this.exportColumns,
      officerName: officerName ?? this.officerName,
      activeProject: activeProject ?? this.activeProject,
      appLanguage: appLanguage ?? this.appLanguage,
    );
  }

  Map<String, dynamic> toMap() => {
    'accuracyMode': accuracyMode,
    'locationSource': locationSource,
    'showCoordinatesInDetail': showCoordinatesInDetail,
    'photoQuality': photoQuality,
    'duplicateToGallery': duplicateToGallery,
    'dateTimeFormat': dateTimeFormat,
    'galleryMetadataOptions': galleryMetadataOptions,
    'mapType': mapType,
    'initialZoomLevel': initialZoomLevel,
    'showMyLocationOnMap': showMyLocationOnMap,
    'exportFormat': exportFormat,
    'exportColumns': exportColumns,
    'officerName': officerName,
    'activeProject': activeProject,
    'appLanguage': appLanguage,
  };

  factory SettingsModel.fromMap(Map<String, dynamic> map) => SettingsModel(
    accuracyMode: map['accuracyMode'] ?? 'standard',
    locationSource: map['locationSource'] ?? 'gpsAndNetwork',
    showCoordinatesInDetail: map['showCoordinatesInDetail'] ?? true,
    photoQuality: map['photoQuality'] ?? 'medium',
    duplicateToGallery: map['duplicateToGallery'] ?? false,
    dateTimeFormat: map['dateTimeFormat'] ?? '24h_ddMMyyyy',
    galleryMetadataOptions: List<String>.from(map['galleryMetadataOptions'] ?? const ['address_short', 'coordinates']),
    mapType: map['mapType'] ?? 'standard',
    initialZoomLevel: map['initialZoomLevel'] ?? 'medium',
    showMyLocationOnMap: map['showMyLocationOnMap'] ?? true,
    exportFormat: map['exportFormat'] ?? 'csv',
    exportColumns: List<String>.from(map['exportColumns'] ?? const ['coordinates', 'full_address']),
    officerName: map['officerName'] ?? '',
    activeProject: map['activeProject'] ?? 'Umum',
    appLanguage: map['appLanguage'] ?? 'id',
  );

  String toJson() => json.encode(toMap());
  factory SettingsModel.fromJson(String source) => SettingsModel.fromMap(json.decode(source) as Map<String, dynamic>);
}

