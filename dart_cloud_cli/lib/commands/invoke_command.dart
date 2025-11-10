import 'dart:io';
import 'dart:convert';
import 'package:dart_cloud_cli/api/api_client.dart';
import 'package:dart_cloud_cli/commands/base_command.dart' show BaseCommand;

class InvokeCommand extends BaseCommand {
  Future<void> execute(List<String> args) async {
    await loadConfig();

    if (!isAuthenticated) {
      print('Error: Not authenticated. Please run "dart_cloud login" first.');
      exit(1);
    }

    if (args.isEmpty) {
      print('Error: Please specify the function ID');
      print(
        'Usage: dart_cloud invoke <function-id> [--data \'{"key": "value"}\']',
      );
      exit(1);
    }

    final functionId = args[0];
    Map<String, dynamic>? data;

    // Parse optional data argument
    if (args.length > 1 && args.contains('--data')) {
      final dataIndex = args.indexOf('--data');
      if (dataIndex + 1 < args.length) {
        try {
          data = jsonDecode(args[dataIndex + 1]) as Map<String, dynamic>;
        } catch (e) {
          print('Error: Invalid JSON data format');
          exit(1);
        }
      }
    }

    try {
      print('Invoking function: $functionId');
      final response = await ApiClient.invokeFunction(functionId, data);

      print('\nFunction Response:');
      print('─' * 80);
      print(const JsonEncoder.withIndent('  ').convert(response));
      print('─' * 80);
    } catch (e) {
      print('✗ Failed to invoke function: $e');
      exit(1);
    }
  }
}
