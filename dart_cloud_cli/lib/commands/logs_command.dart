import 'dart:io';
import 'package:dart_cloud_cli/api/api_client.dart';
import 'package:dart_cloud_cli/commands/base_command.dart' show BaseCommand;

class LogsCommand extends BaseCommand {
  Future<void> execute(List<String> args) async {
    await config.loadConfig();

    if (!config.isAuthenticated) {
      print('Error: Not authenticated. Please run "dart_cloud login" first.');
      exit(1);
    }

    if (args.isEmpty) {
      print('Error: Please specify the function ID');
      print('Usage: dart_cloud logs <function-id>');
      exit(1);
    }

    final functionId = args[0];

    try {
      print('Fetching logs for function: $functionId');
      final response = await ApiClient.getFunctionLogs(functionId);
      final logs = response['logs'] as List<dynamic>;

      if (logs.isEmpty) {
        print('No logs available for this function.');
        return;
      }

      print('\nFunction Logs:');
      print('─' * 80);

      for (final log in logs) {
        final timestamp = log['timestamp'] as String;
        final level = log['level'] as String;
        final message = log['message'] as String;

        print('[$timestamp] [$level] $message');
      }

      print('─' * 80);
      print('Total: ${logs.length} log entries');
    } catch (e) {
      print('✗ Failed to fetch logs: $e');
      exit(1);
    }
  }
}
