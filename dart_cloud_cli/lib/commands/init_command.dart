import 'dart:io';
import 'package:args/args.dart';
import 'package:dart_cloud_cli/commands/base_command.dart' show BaseCommand;
import 'package:dart_cloud_cli/common/function_config.dart';
import 'package:dart_cloud_cli/common/api_key_validity.dart';
import 'package:dart_cloud_cli/api/api_client.dart';
import 'package:dart_cloud_cli/services/api_key_storage.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

class InitCommand extends BaseCommand {
  Future<void> execute(List<String> args) async {
    await config.loadConfig();

    if (!config.isAuthenticated) {
      print('Error: Not authenticated. Please run "dart_cloud login" first.');
      exit(1);
    }

    // Parse arguments
    final parser = ArgParser()
      ..addOption(
        'apikey',
        help:
            'Generate API key with validity: 1h, 1d, 1w, 1m, or forever (empty)',
        valueHelp: 'validity',
      )
      ..addFlag(
        'revoke',
        help: 'Revoke existing API key and generate new one with same validity',
        negatable: false,
      );

    final parsedArgs = parser.parse(args);
    final apiKeyValidity = parsedArgs['apikey'] as String?;
    final revokeApiKey = parsedArgs['revoke'] as bool;

    // Validate --apikey and --revoke usage
    if (revokeApiKey && apiKeyValidity == null) {
      print('✗ Error: --revoke must be used together with --apikey');
      print('  Example: dart_cloud init --apikey 1d --revoke');
      exit(1);
    }

    // Validate API key validity value
    if (apiKeyValidity != null && apiKeyValidity.isNotEmpty) {
      if (!ApiKeyValidity.isValid(apiKeyValidity)) {
        print('✗ Error: Invalid API key validity: $apiKeyValidity');
        print('  Valid options: ${ApiKeyValidity.validOptions.join(', ')}');
        exit(1);
      }
    }

    try {
      // Get the current working directory
      final currentDir = Directory.current;

      // Check if pubspec.yaml exists
      final pubspecFile = File(path.join(currentDir.path, 'pubspec.yaml'));
      if (!pubspecFile.existsSync()) {
        print('✗ Error: pubspec.yaml not found in current directory');
        exit(1);
      }

      // Validate function structure: must have bin/main.dart or lib/main.dart
      final binMainFile = File(path.join(currentDir.path, 'bin', 'main.dart'));
      final libMainFile = File(path.join(currentDir.path, 'lib', 'main.dart'));

      if (!binMainFile.existsSync() && !libMainFile.existsSync()) {
        print('✗ Error: Function entry point not found');
        print('  Expected: bin/main.dart or lib/main.dart');
        exit(1);
      }

      // Parse pubspec.yaml to get the project name
      final pubspecContent = pubspecFile.readAsStringSync();
      final pubspec = loadYaml(pubspecContent) as Map;
      final projectName = pubspec['name'] as String? ?? 'function';

      // Check if function is already initialized
      final existingConfig = await FunctionConfig.load(currentDir.path);
      String functionId;
      FunctionConfig functionConfig;

      if (existingConfig?.functionId != null) {
        // Function already initialized - handle API key options only
        functionId = existingConfig!.functionId!;
        functionConfig = existingConfig;

        if (apiKeyValidity == null) {
          print('✓ Function already initialized');
          print('  Function ID: $functionId');
          print('  Function name: ${existingConfig.functionName}');
          print('  Use "dart_cloud deploy" to deploy your function.');
          print('');
          print(
            '  To generate an API key, use: dart_cloud init --apikey <validity>',
          );
          print(
            '  To revoke and regenerate, use: dart_cloud init --apikey <validity> --revoke',
          );
          return;
        }
      } else {
        // Initialize function on the backend
        print('Initializing function: $projectName');
        final response = await ApiClient.initFunction(projectName);

        functionId = response['id'] as String;
        final status = response['status'] as String;

        // Create function config with path and function ID
        functionConfig = FunctionConfig(
          functionName: projectName,
          functionId: functionId,
          createdAt: DateTime.now().toIso8601String(),
          functionPath: currentDir.path,
        );

        // Save the config
        await functionConfig.save(currentDir.path);

        print('');
        print('✓ Function initialized successfully!');
        print('');
        print('  Function ID: $functionId');
        print('  Function name: $projectName');
        print('  Status: $status');
        print('  Function path: ${currentDir.path}');
        print(
          '  Entry point: ${binMainFile.existsSync() ? 'bin/main.dart' : 'lib/main.dart'}',
        );
        print('');
        print('  Config saved to: .dart_tool/function_config.json');
      }

      // Handle API key generation/revocation if requested
      if (apiKeyValidity != null) {
        final validityEnum = ApiKeyValidity.fromString(
          apiKeyValidity.isEmpty ? 'forever' : apiKeyValidity,
        );
        final validity = validityEnum.value;

        // Revoke existing API key if --revoke flag is set
        if (revokeApiKey && functionConfig.apiKeyUuid != null) {
          print('');
          print('Revoking existing API key...');
          try {
            await ApiClient.revokeApiKey(functionConfig.apiKeyUuid!);
            await ApiKeyStorage.deleteApiKey(functionId);
            print('✓ Existing API key revoked');
          } catch (e) {
            print('⚠️  Warning: Failed to revoke existing API key: $e');
          }
        }

        // Generate new API key
        print('');
        print('Generating API key with validity: $validity');
        final apiKeyResponse = await ApiClient.generateApiKey(
          functionId: functionId,
          validity: validity,
          name: 'init-generated',
        );

        final keyUuid = apiKeyResponse['uuid'] as String;
        final publicKey = apiKeyResponse['public_key'] as String;
        final privateKey = apiKeyResponse['private_key'] as String;
        final expiresAt = apiKeyResponse['expires_at'] as String?;

        // Store private key in Hive
        await ApiKeyStorage.storeApiKey(functionId, privateKey);

        // Update function config with API key info
        final updatedConfig = functionConfig.copyWith(
          apiKeyUuid: keyUuid,
          apiKeyPublicKey: publicKey,
          apiKeyValidity: validity,
          apiKeyExpiresAt: expiresAt,
        );
        await updatedConfig.save(currentDir.path);

        print('');
        print(
          '╔════════════════════════════════════════════════════════════════════╗',
        );
        print(
          '║                    🔑 API KEY GENERATED                            ║',
        );
        print(
          '║                                                                    ║',
        );
        print(
          '║  ⚠️  SAVE THIS PRIVATE KEY - IT WILL NOT BE SHOWN AGAIN!           ║',
        );
        print(
          '╚════════════════════════════════════════════════════════════════════╝',
        );
        print('');
        print('Key UUID: $keyUuid');
        print('Public Key: ${publicKey.substring(0, 20)}...');
        print('Private Key: $privateKey');
        print('Validity: $validity');
        if (expiresAt != null) print('Expires At: $expiresAt');
        print('');
        print('✓ Private key stored securely in Hive database');
        print('  Location: ~/.containerpub/api_keys/');
      }

      if (existingConfig?.functionId == null) {
        print('');
        print('Next steps:');
        print('  1. Implement your function in the entry point');
        print('  2. Run "dart_cloud deploy" to deploy your function');
        if (apiKeyValidity != null) {
          print('  3. Use "dart_cloud invoke --sign" to invoke with signature');
        }
      }
    } catch (e) {
      print('✗ Initialization failed: $e');
      exit(1);
    }
  }
}
