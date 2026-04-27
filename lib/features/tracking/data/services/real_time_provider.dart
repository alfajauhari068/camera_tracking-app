import '../../domain/services/time_provider.dart';

/// Real time provider using system clock
class RealTimeProvider implements TimeProvider {
  @override
  DateTime now() => DateTime.now();
}
