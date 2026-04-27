import '../services/id_generator.dart';

class FakeIdGenerator implements IdGenerator {
  int _counter = 0;

  @override
  String generate() {
    _counter++;
    return 'fake_id_$_counter';
  }

  /// Reset counter for testing
  void reset() {
    _counter = 0;
  }
}
