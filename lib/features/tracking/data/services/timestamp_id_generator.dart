import '../../domain/services/id_generator.dart';
import '../../domain/services/time_provider.dart';

/// Real ID generator using timestamp and microsecond precision
class TimestampIdGenerator implements IdGenerator {
  final TimeProvider timeProvider;

  const TimestampIdGenerator(this.timeProvider);

  @override
  String generate() {
    final now = timeProvider.now();
    return '${now.millisecondsSinceEpoch}_${now.microsecond}';
  }
}
