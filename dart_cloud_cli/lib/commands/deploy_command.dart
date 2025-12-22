import 'dart:io';
import 'package:args/args.dart';
import 'package:dart_cloud_cli/commands/base_command.dart' show BaseCommand;
import 'package:path/path.dart' as path;
import 'package:dart_cloud_cli/api/api_client.dart';
import 'package:dart_cloud_cli/config/config.dart';
import 'package:dart_cloud_cli/services/function_analyzer.dart';
import 'package:dart_cloud_cli/services/deployment_validator.dart';
import 'package:dart_cloud_cli/services/function_hasher.dart';
import 'package:dart_cloud_cli/common/function_config.dart';
import 'package:dart_cloud_cli/common/archive_utils.dart';
import 'package:yaml/yaml.dart';

class DeployCommand extends BaseCommand {
  Future<void> execute(List<String> args) async {
    await config.loadConfig();

    if (!config.isAuthenticated) {
      print('Error: Not authenticated. Please run "dart_cloud login" first.');
      exit(1);
    }

    // Parse arguments properly
    final parser = ArgParser()
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Force deployment even if no changes detected',
      );

    final parsedArgs = parser.parse(args);
    final forceDeployment = parsedArgs['force'] as bool;
    final pathArgs = parsedArgs.rest;

    // Determine function path: use provided path or current directory
    String functionPath;
    if (pathArgs.isEmpty) {
      // Try to load from function_config.json first
      final currentDir = Directory.current;
      final existingConfig = await FunctionConfig.load(currentDir.path);

      if (existingConfig?.functionPath != null) {
        functionPath = existingConfig!.functionPath!;
        print('Using function path from config: $functionPath');
      } else {
        functionPath = currentDir.path;
        print('Using current directory: $functionPath');
      }
    } else {
      functionPath = pathArgs[0];
    }

    final functionDir = Directory(functionPath);

    if (!functionDir.existsSync()) {
      print('Error: Directory not found: $functionPath');
      exit(1);
    }

    // Check if function configuration exists
    final existingConfig = await FunctionConfig.load(functionDir.path);
    if (existingConfig?.functionId == null) {
      print('');
      print('✗ Function not initialized.');
      print(
        '  Please run "dart_cloud init" first to initialize your function.',
      );
      exit(1);
    }

    // Validate function structure
    final pubspecFile = File(path.join(functionDir.path, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      print('Error: pubspec.yaml not found in function directory');
      print('Please ensure you are in a valid Dart project directory');
      exit(1);
    }

    // Validate function entry point: must have bin/main.dart or lib/main.dart
    final binMainFile = File(path.join(functionDir.path, 'bin', 'main.dart'));
    final libMainFile = File(path.join(functionDir.path, 'lib', 'main.dart'));

    if (!binMainFile.existsSync() && !libMainFile.existsSync()) {
      print('Error: Function entry point not found');
      print('Expected: bin/main.dart or lib/main.dart');
      print('Please run "dart_cloud init" in your function directory first');
      exit(1);
    }

    // Extract function name from pubspec.yaml
    final pubspecContent = pubspecFile.readAsStringSync();
    final pubspec = loadYaml(pubspecContent) as Map;
    final functionName =
        pubspec['name'] as String? ?? path.basename(functionDir.path);
    print('Preparing to deploy function: $functionName');

    final functionId = existingConfig!.functionId!;
    print('Function ID: $functionId');

    // Generate hash of current function code
    print('Generating function hash...');
    final hasher = FunctionHasher(functionDir.path);
    final currentHash = await hasher.generateHash();
    print('Current hash: ${currentHash.substring(0, 16)}...');

    // Check hash for unchanged code
    if (!forceDeployment && existingConfig.hasUnchangedCode(currentHash)) {
      print('\n✓ No changes detected since last deployment.');
      print('  Last deployed: ${existingConfig.lastDeployedAt ?? 'unknown'}');
      print('  Version: ${existingConfig.deployVersion ?? 1}');
      print('  Hash: ${currentHash.substring(0, 16)}...');
      print('\nUse --force or -f to deploy anyway.');
      return;
    }

    final newVersion = existingConfig.nextVersion;
    print('Deploying version: $newVersion');

    File? archiveFile;
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

      // Create archive using extension method
      print('Creating archive...');
      archiveFile = await functionDir.createFunctionArchive(functionName);
      print(
        'Archive created: ${(archiveFile.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB',
      );
      print(
        'Included: lib/*.dart, bin/*.dart, pubspec.yaml, pubspec.lock, .env (if present)',
      );

      // Deploy using function UUID
      print('Deploying function...');
      final response = await ApiClient.deployFunction(
        archiveFile,
        functionId,
      );

      print('✓ Function deployed successfully!');
      print('  Function ID: $functionId');
      print('  Name: ${response['name']}');
      print('  Version: $newVersion');
      print(
        '  Endpoint: ${Config.serverUrl}/api/functions/$functionId/invoke',
      );

      // Update config with hash and version
      final updatedConfig = existingConfig.copyWith(
        functionPath: functionDir.path,
        lastDeployHash: currentHash,
        lastDeployedAt: DateTime.now().toIso8601String(),
        deployVersion: newVersion,
      );
      await updatedConfig.save(functionDir.path);
      print('✓ Config cached in .dart_tool/function_config.json');
      print('  Hash: ${currentHash.substring(0, 16)}...');
      archiveFile.deleteSync();
      archiveFile = null;
      exit(0);
    } catch (e) {
      print('✗ Deployment failed: $e');
      archiveFile?.deleteSync();
      archiveFile = null;
      exit(1);
    }
  }
}
