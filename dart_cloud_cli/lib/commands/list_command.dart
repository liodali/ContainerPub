import 'dart:io';
import 'package:dart_cloud_cli/api/api_client.dart';
import 'package:dart_cloud_cli/commands/base_command.dart' show BaseCommand;

class ListCommand extends BaseCommand {
  Future<void> execute(List<String> args) async {
    await loadConfig();

    if (!isAuthenticated) {
      print('Error: Not authenticated. Please run "dart_cloud login" first.');
      exit(1);
    }

    try {
      print('Fetching functions...');
      final functions = await ApiClient.listFunctions();

      if (functions.isEmpty) {
        print('No functions deployed yet.');
        return;
      }

      print('\nDeployed Functions:');
      print('─' * 80);
      print(
        '${'ID'.padRight(20)} ${'Name'.padRight(25)} ${'Status'.padRight(15)} Created',
      );
      print('─' * 80);

      for (final func in functions) {
        final id = (func['id'] as String).padRight(20);
        final name = (func['name'] as String).padRight(25);
        final status = (func['status'] as String).padRight(15);
        final created = func['createdAt'] as String;

        print('$id $name $status $created');
      }

      print('─' * 80);
      print('Total: ${functions.length} function(s)');
    } catch (e) {
      print('✗ Failed to list functions: $e');
      exit(1);
    }
  }
}
