import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class GpsServiceException implements Exception {
  final String message;

  GpsServiceException(this.message);

  @override
  String toString() => 'GpsServiceException(message: $message)';
}

class GpsStatus {
  final bool serviceEnabled;
  final bool permissionGranted;
  final bool hasLock;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final String? address;
  final String? errorMessage;

  const GpsStatus({
    this.serviceEnabled = false,
    this.permissionGranted = false,
    this.hasLock = false,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.address,
    this.errorMessage,
  });

  GpsStatus copyWith({
    bool? serviceEnabled,
    bool? permissionGranted,
    bool? hasLock,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? address,
    String? errorMessage,
  }) {
    return GpsStatus(
      serviceEnabled: serviceEnabled ?? this.serviceEnabled,
      permissionGranted: permissionGranted ?? this.permissionGranted,
      hasLock: hasLock ?? this.hasLock,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      address: address ?? this.address,
      errorMessage: errorMessage,
    );
  }

  bool get isStreaming => latitude != null && longitude != null;

  bool get isReady => serviceEnabled && permissionGranted && hasLock;
}

class GpsService {
  final StreamController<GpsStatus> _statusController;
  StreamSubscription<Position>? _positionSubscription;
  GpsStatus _currentStatus;

  GpsService._(
    this._statusController,
    this._currentStatus,
  );

  factory GpsService() {
    final controller = StreamController<GpsStatus>.broadcast();
    final status = const GpsStatus();
    final service = GpsService._(controller, status);
    controller.onListen = () {
      service._statusController.add(service._currentStatus);
    };
    return service;
  }

  Stream<GpsStatus> get statusStream => _statusController.stream;

  GpsStatus get currentStatus => _currentStatus;

  Future<LocationPermission> requestPermissions() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      return await Geolocator.requestPermission();
    }
    return permission;
  }

  Future<void> start({
    LocationAccuracy accuracy = LocationAccuracy.best,
    double lockAccuracyMeters = 15,
    int distanceFilter = 10,
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _emit(_currentStatus.copyWith(
        serviceEnabled: false,
        permissionGranted: false,
        errorMessage: 'Layanan lokasi tidak aktif',
      ));
      throw GpsServiceException('Location services are disabled.');
    }

    final permission = await requestPermissions();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _emit(_currentStatus.copyWith(
        serviceEnabled: true,
        permissionGranted: false,
        errorMessage: 'Izin lokasi tidak diberikan',
      ));
      throw GpsServiceException('Location permission denied.');
    }

    _emit(_currentStatus.copyWith(
      serviceEnabled: true,
      permissionGranted: true,
      errorMessage: null,
    ));

    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    ).listen(
      _handlePosition,
      onError: _handleError,
      cancelOnError: false,
    );
  }

  Future<void> stop() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _emit(_currentStatus.copyWith(
      hasLock: false,
      latitude: null,
      longitude: null,
      accuracy: null,
    ));
  }

  Future<String> reverseGeocode(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) {
        throw GpsServiceException('Tidak ditemukan alamat dari koordinat tersebut.');
      }

      final placemark = placemarks.first;
      final components = <String>[];

      if (placemark.street != null && placemark.street!.isNotEmpty) {
        components.add(placemark.street!);
      }
      if (placemark.locality != null && placemark.locality!.isNotEmpty) {
        components.add(placemark.locality!);
      }
      if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
        components.add(placemark.administrativeArea!);
      }
      if (placemark.country != null && placemark.country!.isNotEmpty) {
        components.add(placemark.country!);
      }

      final address = components.join(', ');
      _emit(_currentStatus.copyWith(address: address, errorMessage: null));
      return address;
    } catch (e) {
      final message = e is GpsServiceException ? e.message : 'Reverse geocoding gagal: $e';
      _emit(_currentStatus.copyWith(errorMessage: message));
      throw GpsServiceException(message);
    }
  }

  Future<void> updateAddressFromCurrentLocation() async {
    final lat = _currentStatus.latitude;
    final lon = _currentStatus.longitude;
    if (lat == null || lon == null) {
      throw GpsServiceException('Koordinat lokasi belum tersedia.');
    }

    final address = await reverseGeocode(lat, lon);
    _emit(_currentStatus.copyWith(address: address, errorMessage: null));
  }

  void _handlePosition(Position position) {
    final hasLock = position.accuracy <= 15.0;
    _emit(_currentStatus.copyWith(
      serviceEnabled: true,
      permissionGranted: true,
      hasLock: hasLock,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      errorMessage: null,
    ));
  }

  void _handleError(Object error) {
    _emit(_currentStatus.copyWith(errorMessage: error.toString()));
  }

  void _emit(GpsStatus status) {
    _currentStatus = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  void dispose() {
    _positionSubscription?.cancel();
    _statusController.close();
  }
}
