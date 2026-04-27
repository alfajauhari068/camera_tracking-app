import '../services/time_provider.dart';

/// Fake time provider for deterministic testing
class FakeTimeProvider implements TimeProvider {
  /// Fixed time untuk predictable testing
  DateTime _fixedTime = DateTime(2026, 4, 20, 12, 0, 0);

  /// Set fixed time untuk testing
  void setFixedTime(DateTime time) {
    _fixedTime = time;
  }

  /// Advance time untuk simulating time progression
  void advanceBy(Duration duration) {
    _fixedTime = _fixedTime.add(duration);
  }

  /// Reset ke default time
  void reset() {
    _fixedTime = DateTime(2026, 4, 20, 12, 0, 0);
  }

  @override
  DateTime now() => _fixedTime;
}
