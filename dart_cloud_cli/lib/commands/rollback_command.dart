import 'dart:io';
import 'package:dart_cloud_cli/commands/base_command.dart' show BaseCommand;
import 'package:dart_cloud_cli/api/api_client.dart';
import 'package:dart_cloud_cli/common/function_config.dart';

class RollbackCommand extends BaseCommand {
  Future<void> execute(List<String> args) async {
    await config.loadConfig();

    if (!config.isAuthenticated) {
      print('Error: Not authenticated. Please run "dart_cloud login" first.');
      exit(1);
    }

    String? functionId;
    int? targetVersion;

    // Parse arguments: rollback [function_uuid] [version]
    if (args.isNotEmpty) {
      functionId = args[0];
    }
    if (args.length > 1) {
      targetVersion = int.tryParse(args[1]);
      if (targetVersion == null) {
        print('Error: Invalid version number: ${args[1]}');
        exit(1);
      }
    }

    // If no function ID provided, try to get from local config
    if (functionId == null) {
      final currentDir = Directory.current;
      final existingConfig = await FunctionConfig.load(currentDir.path);

      if (existingConfig?.functionId != null) {
        functionId = existingConfig!.functionId!;
        print('Using function ID from config: $functionId');
      } else {
        print(
            'Error: No function ID provided and no function_config.json found.');
        print('Usage: dart_cloud rollback <function_uuid> [version]');
        exit(1);
      }
    }

    try {
      // Fetch deployment versions
      print('Fetching deployment versions...');
      final deploymentsResponse = await ApiClient.getDeployments(functionId);

      final functionName = deploymentsResponse['function_name'] as String?;
      final deployments = deploymentsResponse['deployments'] as List<dynamic>;

      if (deployments.isEmpty) {
        print('No deployments found for this function.');
        exit(1);
      }

      // Find active deployment version
      int? activeVersion;
      for (final deploy in deployments) {
        if (deploy['is_active'] == true) {
          activeVersion = deploy['version'] as int;
          break;
        }
      }

      // Filter out active version from available rollback targets
      final availableVersions =
          deployments.where((d) => d['is_active'] != true).toList();

      if (availableVersions.isEmpty) {
        print('No previous versions available for rollback.');
        print('Current active version: $activeVersion');
        exit(1);
      }

      // If version not provided, show interactive selection
      if (targetVersion == null) {
        print('');
        print('📦 Function: ${functionName ?? functionId}');
        print('${'─' * 60}');
        print('');
        print('Available versions for rollback:');
        print('');

        // Display versions in a table format
        print('  Version  │  Status    │  Deployed At');
        print('  ${'─' * 9}┼${'─' * 12}┼${'─' * 25}');

        for (final deploy in deployments) {
          final version = deploy['version'] as int;
          final isActive = deploy['is_active'] == true;
          final status = deploy['status'] as String? ?? 'unknown';
          final deployedAt = deploy['deployed_at'] as String? ?? 'unknown';

          final activeMarker = isActive ? ' (active)' : '';
          final versionStr = 'v$version'.padRight(7);
          final statusStr = status.padRight(10);

          if (isActive) {
            print('  $versionStr │  $statusStr │  $deployedAt$activeMarker');
          } else {
            print('  $versionStr │  $statusStr │  $deployedAt');
          }
        }

        print('');
        print('Current active version: v$activeVersion');
        print('');

        // Prompt for version selection
        stdout.write('Enter version number to rollback to (or "q" to quit): ');
        final input = stdin.readLineSync()?.trim();

        if (input == null || input.isEmpty || input.toLowerCase() == 'q') {
          print('Rollback cancelled.');
          exit(0);
        }

        targetVersion = int.tryParse(input);
        if (targetVersion == null) {
          print('Error: Invalid version number: $input');
          exit(1);
        }
      }

      // Validate target version
      if (targetVersion == activeVersion) {
        print(
            'Error: Cannot rollback to the currently active version (v$activeVersion).');
        exit(1);
      }

      // Check if target version exists
      final targetExists =
          deployments.any((d) => d['version'] == targetVersion);
      if (!targetExists) {
        print('Error: Version $targetVersion not found.');
        print(
            'Available versions: ${deployments.map((d) => 'v${d['version']}').join(', ')}');
        exit(1);
      }

      // Confirm rollback
      print('');
      print('⚠️  You are about to rollback:');
      print('   Function: ${functionName ?? functionId}');
      print('   From: v$activeVersion → To: v$targetVersion');
      print('');
      stdout.write('Proceed with rollback? (y/N): ');
      final confirm = stdin.readLineSync()?.trim().toLowerCase();

      if (confirm != 'y' && confirm != 'yes') {
        print('Rollback cancelled.');
        exit(0);
      }

      // Perform rollback
      print('');
      print('Rolling back to version $targetVersion...');

      final result =
          await ApiClient.rollbackFunction(functionId, targetVersion);

      print('');
      print('✓ Rollback successful!');
      print('  ${result['message']}');
      print('  Deployment ID: ${result['deploymentId']}');
      exit(0);
    } catch (e) {
      print('✗ Rollback failed: $e');
      exit(1);
    }
  }
}
