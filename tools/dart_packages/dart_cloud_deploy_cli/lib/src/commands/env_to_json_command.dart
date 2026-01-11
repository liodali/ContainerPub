import 'dart:convert';
import 'dart:io';
import 'package:args/command_runner.dart';
import '../utils/console.dart';

class EnvToJsonCommand extends Command<void> {
  @override
  final String name = 'env-to-json';

  @override
  final String description =
      'Convert .env file to JSON format and output to terminal';

  EnvToJsonCommand() {
    argParser.addOption(
      'file',
      abbr: 'f',
      help: '.env file path to convert',
      defaultsTo: '.env',
    );
  }

  @override
  Future<void> run() async {
    final filePath = argResults!['file'] as String;

    Console.header('Converting .env to JSON');

    final file = File(filePath);

    if (!file.existsSync()) {
      Console.error('File not found: $filePath');
      exit(1);
    }

    try {
      Console.info('Reading file: $filePath');
      final content = await file.readAsString();

      final jsonMap = _parseEnvToMap(content);

      final prettyJson = JsonEncoder.withIndent('  ').convert(jsonMap);

      Console.success('Conversion successful');
      Console.divider();
      print(prettyJson);
      Console.divider();
    } catch (e) {
      Console.error('Failed to convert file: $e');
      exit(1);
    }
  }

  Map<String, dynamic> _parseEnvToMap(String content) {
    final map = <String, dynamic>{};

    final lines = content.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed.isEmpty || trimmed.startsWith('#')) {
        continue;
      }

      final separatorIndex = trimmed.indexOf('=');
      if (separatorIndex == -1) {
        continue;
      }

      final key = trimmed.substring(0, separatorIndex).trim();
      var value = trimmed.substring(separatorIndex + 1).trim();

      if (key.isEmpty) {
        continue;
      }

      value = _unquoteValue(value);
      value = _expandEscapes(value);

      map[key] = value;
    }

    return map;
  }

  String _unquoteValue(String value) {
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      return value.substring(1, value.length - 1);
    }
    return value;
  }

  String _expandEscapes(String value) {
    return value
        .replaceAll('\\n', '\n')
        .replaceAll('\\r', '\r')
        .replaceAll('\\t', '\t')
        .replaceAll('\\\\', '\\')
        .replaceAll('\\"', '"')
        .replaceAll("\\'", "'");
  }
}
