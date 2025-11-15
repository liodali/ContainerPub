import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:dart_cloud_cli/commands/base_command.dart' show BaseCommand;
import 'package:path/path.dart' as path;
import 'package:dart_cloud_cli/api/api_client.dart';
import 'package:dart_cloud_cli/config/config.dart';
import 'package:dart_cloud_cli/services/function_analyzer.dart';
import 'package:dart_cloud_cli/services/deployment_validator.dart';

class DeployCommand extends BaseCommand {
  Future<void> execute(List<String> args) async {
    await config.loadConfig();

    if (!config.isAuthenticated) {
      print('Error: Not authenticated. Please run "dart_cloud login" first.');
      exit(1);
    }

    if (args.isEmpty) {
      print('Error: Please specify the function directory path');
      print('Usage: dart_cloud deploy <path>');
      exit(1);
    }

    final functionPath = args[0];
    final functionDir = Directory(functionPath);

    if (!functionDir.existsSync()) {
      print('Error: Directory not found: $functionPath');
      exit(1);
    }

    // Validate function structure
    final pubspecFile = File(path.join(functionDir.path, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      print('Error: pubspec.yaml not found in function directory');
      exit(1);
    }

    final functionName = path.basename(functionDir.absolute.path);
    print('Preparing to deploy function: $functionName');

    try {
      // Step 1: Validate deployment restrictions
      print('Validating deployment restrictions...');
      final deploymentValidator = DeploymentValidator(functionDir.path);
      final deploymentResult = await deploymentValidator.validate();

      if (deploymentResult.warnings.isNotEmpty) {
        print('\n⚠️  Deployment Warnings:');
        for (final warning in deploymentResult.warnings) {
          print('  - $warning');
        }
      }

      if (!deploymentResult.isValid) {
        print('\n✗ Deployment validation failed:');
        for (final error in deploymentResult.errors) {
          print('  - $error');
        }
        exit(1);
      }

      print(
        '✓ Deployment restrictions passed (${deploymentResult.sizeInMB.toStringAsFixed(2)} MB)',
      );

      // Step 2: Analyze the function for security and compliance
      print('\nAnalyzing function code...');
      final analyzer = FunctionAnalyzer(functionDir.path);
      final analysisResult = await analyzer.analyze();

      // Display analysis results
      if (analysisResult.warnings.isNotEmpty) {
        print('\n⚠️  Code Analysis Warnings:');
        for (final warning in analysisResult.warnings) {
          print('  - $warning');
        }
      }

      if (analysisResult.detectedRisks.isNotEmpty) {
        print('\n⚠️  Detected Risks:');
        for (final risk in analysisResult.detectedRisks) {
          print('  - $risk');
        }
      }

      // Check if analysis passed
      if (!analysisResult.isValid) {
        print('\n✗ Code validation failed:');
        for (final error in analysisResult.errors) {
          print('  - $error');
        }
        exit(1);
      }

      print('✓ Code analysis passed');

      // Create archive
      print('Creating archive...');
      final tempDir = Directory.systemTemp.createTempSync('dart_cloud_');
      final archivePath = path.join(tempDir.path, '$functionName.tar.gz');

      final encoder = TarFileEncoder();
      encoder.create(archivePath);
      encoder.addDirectory(functionDir);
      encoder.close();

      final archiveFile = File(archivePath);
      print(
        'Archive created: ${(archiveFile.lengthSync() / 1024).toStringAsFixed(2)} KB',
      );

      // Deploy
      print('Deploying function...');
      final response =
          await ApiClient.deployFunction(archiveFile, functionName);

      print('✓ Function deployed successfully!');
      print('  Function ID: ${response['id']}');
      print('  Name: ${response['name']}');
      print(
        '  Endpoint: ${Config.serverUrl}/api/functions/${response['id']}/invoke',
      );

      // Cleanup
      tempDir.deleteSync(recursive: true);
    } catch (e) {
      print('✗ Deployment failed: $e');
      exit(1);
    }
  }
}
