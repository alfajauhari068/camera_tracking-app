class Tracking {
  final String id;
  final String imagePath;
  final double latitude;
  final double longitude;
  final String address;
  final double accuracy;
  final DateTime timestamp;

  const Tracking({
    required this.id,
    required this.imagePath,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.accuracy,
    required this.timestamp,
  });
}
