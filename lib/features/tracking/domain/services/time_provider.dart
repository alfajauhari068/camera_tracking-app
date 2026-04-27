/// Contract for getting current time (injectable, testable)
/// Jangan gunakan DateTime.now() directly di domain/usecase
abstract class TimeProvider {
  /// Get current DateTime
  DateTime now();
}
