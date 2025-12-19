import 'package:name_generator/name_generator.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    final awesome = NameGenerator();

    setUp(() {
      // Additional setup goes here.
    });

    test('First Test', () {
      expect(awesome.length, 32);
    });
  });
}
