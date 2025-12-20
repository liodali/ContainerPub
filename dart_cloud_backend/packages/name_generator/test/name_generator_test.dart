import 'package:name_generator/name_generator.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('First Test', () {
      final name = NameGenerator();
      print(name.value);
      expect(name.length, 32);
    });
    test('Second Test', () {
      final name = NameGenerator.secure();
      print(name.value);
      expect(name.length, 32);
    });
  });
}
