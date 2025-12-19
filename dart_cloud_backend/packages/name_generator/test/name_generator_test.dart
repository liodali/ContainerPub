import 'package:name_generator/name_generator.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('First Test', () {
      final name = NameGenerator();
      expect(name.length, 32);
    });
  });
}
