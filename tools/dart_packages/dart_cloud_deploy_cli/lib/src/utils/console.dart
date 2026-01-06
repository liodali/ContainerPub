import 'dart:io';

class Console {
  static const String _reset = '\x1B[0m';
  static const String _green = '\x1B[32m';
  static const String _blue = '\x1B[34m';
  static const String _yellow = '\x1B[33m';
  static const String _red = '\x1B[31m';
  static const String _cyan = '\x1B[36m';
  static const String _bold = '\x1B[1m';

  static void header(String message) {
    print('\n$_blue━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$_reset');
    print('$_blue$_bold$message$_reset');
    print('$_blue━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$_reset\n');
  }

  static void info(String message) {
    print('$_blue ℹ$_reset $message');
  }

  static void success(String message) {
    print('$_green ✓$_reset $message');
  }

  static void warning(String message) {
    print('$_yellow ⚠$_reset $message');
  }

  static void error(String message) {
    print('$_red ✗$_reset $message');
  }

  static void step(String message) {
    print('$_cyan ▸$_reset $message');
  }

  static void keyValue(String key, String value) {
    print('  $_bold$key:$_reset $value');
  }

  static void divider() {
    print('$_blue────────────────────────────────────────$_reset');
  }

  static String? prompt(String message, {bool hidden = false}) {
    stdout.write('$_cyan?$_reset $message: ');
    if (hidden) {
      stdin.echoMode = false;
      final input = stdin.readLineSync();
      stdin.echoMode = true;
      print('');
      return input;
    }
    return stdin.readLineSync();
  }

  static bool confirm(String message, {bool defaultValue = false}) {
    final defaultStr = defaultValue ? 'Y/n' : 'y/N';
    stdout.write('$_cyan?$_reset $message [$defaultStr]: ');
    final input = stdin.readLineSync()?.toLowerCase().trim();
    if (input == null || input.isEmpty) return defaultValue;
    return input == 'y' || input == 'yes';
  }

  static int? menu(String title, List<String> options) {
    print('\n$_blue$title$_reset');
    for (var i = 0; i < options.length; i++) {
      print('  ${i + 1}) ${options[i]}');
    }
    print('');
    stdout.write('$_cyan?$_reset Enter your choice (1-${options.length}): ');
    final input = stdin.readLineSync();
    if (input == null) return null;
    final choice = int.tryParse(input);
    if (choice == null || choice < 1 || choice > options.length) return null;
    return choice - 1;
  }
}
