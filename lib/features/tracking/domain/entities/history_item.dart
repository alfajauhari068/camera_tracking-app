/// Data class untuk satu item history/tracking log
/// Digunakan untuk display di History Page
class HistoryItem {
  final String id;
  final DateTime timestamp;
  final String locationSummary;  // Alamat singkat atau "Lat, Lng"
  final HistoryStatus status;
  final double? latitude;
  final double? longitude;
  final String? imagePath;

  const HistoryItem({
    required this.id,
    required this.timestamp,
    required this.locationSummary,
    required this.status,
    this.latitude,
    this.longitude,
    this.imagePath,
  });

  /// Format waktu untuk display
  String get formattedDate {
    final d = timestamp.day.toString().padLeft(2, '0');
    final mo = timestamp.month.toString().padLeft(2, '0');
    final y = timestamp.year;
    return '$d/$mo/$y';
  }

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Helper untuk koordinat jika tidak ada alamat
  String get coordinatesDisplay {
    if (latitude == null || longitude == null) return locationSummary;
    return '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}';
  }
}

/// Status dari satu record history
enum HistoryStatus {
  trackingSession,  // Tracking aktif/session
  snapshot,       // Foto tunggal/snapshot
}

/// =============================================================================
/// DUMMY DATA CONSTRUCTOR
/// =============================================================================
/// Factory constructor untuk membuat dummy data untuk testing UI
class HistoryItemDummy {
  static List<HistoryItem> getDummyList() {
    return [
      HistoryItem(
        id: '1',
        timestamp: DateTime(2025, 1, 15, 10, 30),
        locationSummary: 'Jl. Sudirman No.123, Jakarta',
        status: HistoryStatus.trackingSession,
        latitude: -6.2000,
        longitude: 106.8161,
      ),
      HistoryItem(
        id: '2',
        timestamp: DateTime(2025, 1, 15, 09, 15),
        locationSummary: '-6.1751, 106.8650',
        status: HistoryStatus.snapshot,
        latitude: -6.1751,
        longitude: 106.8650,
      ),
      HistoryItem(
        id: '3',
        timestamp: DateTime(2025, 1, 14, 16, 45),
        locationSummary: 'Mall Grand Indonesia, Jakarta',
        status: HistoryStatus.trackingSession,
        latitude: -6.1953,
        longitude: 106.8235,
      ),
      HistoryItem(
        id: '4',
        timestamp: DateTime(2025, 1, 14, 14, 20),
        locationSummary: '-6.9147, 107.6097',
        status: HistoryStatus.snapshot,
        latitude: -6.9147,
        longitude: 107.6097,
      ),
      HistoryItem(
        id: '5',
        timestamp: DateTime(2025, 1, 13, 11, 00),
        locationSummary: 'Bandung, Jawa Barat',
        status: HistoryStatus.trackingSession,
        latitude: -6.9147,
        longitude: 107.6097,
      ),
    ];
  }
}
