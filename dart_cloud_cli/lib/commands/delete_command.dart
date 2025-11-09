import 'dart:io';
import 'package:dart_cloud_cli/api/api_client.dart';
import 'package:dart_cloud_cli/config/config.dart';

class DeleteCommand {
  Future<void> execute(List<String> args) async {
    await Config.load();

    if (!Config.isAuthenticated) {
      print('Error: Not authenticated. Please run "dart_cloud login" first.');
      exit(1);
    }

    if (args.isEmpty) {
      print('Error: Please specify the function ID');
      print('Usage: dart_cloud delete <function-id>');
      exit(1);
    }

    final functionId = args[0];

    stdout.write(
      'Are you sure you want to delete function "$functionId"? (y/N): ',
    );
    final confirmation = stdin.readLineSync()?.toLowerCase() ?? 'n';

    if (confirmation != 'y' && confirmation != 'yes') {
      print('Deletion cancelled.');
      return;
    }

    try {
      print('Deleting function...');
      await ApiClient.deleteFunction(functionId);
      print('✓ Function deleted successfully!');
    } catch (e) {
      print('✗ Failed to delete function: $e');
      exit(1);
    }
  }
}
