import 'dart:io';
import 'package:archive/archive.dart';
import 'package:dart_cloud_cli/commands/base_command.dart' show BaseCommand;
import 'package:path/path.dart' as path;
import 'package:dart_cloud_cli/api/api_client.dart';
import 'package:dart_cloud_cli/config/config.dart';
import 'package:dart_cloud_cli/services/function_analyzer.dart';
import 'package:dart_cloud_cli/services/deployment_validator.dart';
import 'package:dart_cloud_cli/common/function_config.dart';
import 'package:yaml/yaml.dart';

class DeployCommand extends BaseCommand {
  /// Creates a tar.gz archive containing only allowed files and directories
  /// Includes: lib/, bin/, pubspec.yaml, pubspec.lock, .env
  Future<File> _createFunctionArchive(
    Directory functionDir,
    String functionName,
  ) async {
    final tempDir = Directory.systemTemp.createTempSync('dart_cloud_');
    final archivePath = path.join(tempDir.path, '$functionName.tar.gz');

    final archive = Archive();

    // Allowed files and directories
    final allowedItems = [
      'lib',
      'bin',
      'pubspec.yaml',
      'pubspec.lock',
      '.env',
    ];

    int filesAdded = 0;
    for (final itemName in allowedItems) {
      final itemPath = path.join(functionDir.path, itemName);
      final item = FileSystemEntity.typeSync(itemPath);

      if (item == FileSystemEntityType.directory) {
        // Add directory recursively
        await _addDirectoryToArchive(
          archive,
          Directory(itemPath),
          functionDir.path,
        );
        filesAdded++;
      } else if (item == FileSystemEntityType.file) {
        // Add single file
        await _addFileToArchive(
          archive,
          File(itemPath),
          functionDir.path,
        );
        filesAdded++;
      }
      // Skip if item doesn't exist
    }

    if (filesAdded == 0) {
      throw Exception(
          'No files found to archive. Ensure lib/ or bin/ directories exist.');
    }

    // Encode to tar.gz
    final tarData = TarEncoder().encode(archive);
    final gzipData = GZipEncoder().encode(tarData);

    // Write to file
    final archiveFile = File(archivePath);
    await archiveFile.writeAsBytes(gzipData!);

    return archiveFile;
  }

  /// Recursively adds a directory to the archive
  Future<void> _addDirectoryToArchive(
    Archive archive,
    Directory directory,
    String basePath,
  ) async {
    final entities = directory.listSync(recursive: false);

    for (final entity in entities) {
      if (entity is File) {
        await _addFileToArchive(archive, entity, basePath);
      } else if (entity is Directory) {
        await _addDirectoryToArchive(archive, entity, basePath);
      }
    }
  }

  /// Adds a single file to the archive
  Future<void> _addFileToArchive(
    Archive archive,
    File file,
    String basePath,
  ) async {
    final relativePath = path.relative(file.path, from: basePath);
    final bytes = await file.readAsBytes();

    final archiveFile = ArchiveFile(
      relativePath,
      bytes.length,
      bytes,
    );

    // Set file permissions (0644 for files)
    archiveFile.mode = 420; // 0644 in octal
    archiveFile.lastModTime =
        file.lastModifiedSync().millisecondsSinceEpoch ~/ 1000;

    archive.addFile(archiveFile);
  }

  Future<void> execute(List<String> args) async {
    await config.loadConfig();

    if (!config.isAuthenticated) {
      print('Error: Not authenticated. Please run "dart_cloud login" first.');
      exit(1);
    }

    // Determine function path: use provided path or current directory
    String functionPath;
    if (args.isEmpty) {
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
      functionPath = args[0];
    }

    final functionDir = Directory(functionPath);

    if (!functionDir.existsSync()) {
      print('Error: Directory not found: $functionPath');
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
      final archiveFile = await _createFunctionArchive(
        functionDir,
        functionName,
      );
      print(
        'Archive created: ${(archiveFile.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB',
      );
      print(
          'Included: lib/, bin/, pubspec.yaml, pubspec.lock, .env (if present)');

      // Deploy
      print('Deploying function...');
      final response = await ApiClient.deployFunction(
        archiveFile,
        functionName,
      );

      final functionId = response['id'] as String;

      print('✓ Function deployed successfully!');
      print('  Function ID: $functionId');
      print('  Name: ${response['name']}');
      print(
        '  Endpoint: ${Config.serverUrl}/api/functions/$functionId/invoke',
      );

      // Save function ID and path to config
      final existingConfig = await FunctionConfig.load(functionDir.path);
      final updatedConfig =
          (existingConfig ?? FunctionConfig(functionName: functionName))
              .copyWith(functionId: functionId, functionPath: functionDir.path);
      await updatedConfig.save(functionDir.path);
      print('✓ Function ID cached in .dart_tool/function_config.json');

      // Cleanup
      final tempDir = archiveFile.parent;
      tempDir.deleteSync(recursive: true);
    } catch (e) {
      print('✗ Deployment failed: $e');
      exit(1);
    }
  }
}
