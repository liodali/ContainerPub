import 'dart:io';
import 'package:args/args.dart';
import 'package:dart_cloud_cli/commands/base_command.dart' show BaseCommand;
import 'package:dart_cloud_cli/api/api_client.dart';
import 'package:dart_cloud_cli/common/function_config.dart';
import 'package:dart_cloud_cli/common/api_key_validity.dart';
import 'package:dart_cloud_cli/services/api_key_storage.dart';

class ApiKeyCommand extends BaseCommand {
  Future<void> execute(List<String> args) async {
    await config.loadConfig();

    if (!config.isAuthenticated) {
      print('Error: Not authenticated. Please run "dart_cloud login" first.');
      exit(1);
    }

    if (args.isEmpty) {
      _printUsage();
      exit(1);
    }

    final subCommand = args[0];
    final subArgs = args.length > 1 ? args.sublist(1) : <String>[];

    switch (subCommand) {
      case 'generate':
        await _generateApiKey(subArgs);
        break;
      case 'info':
        await _getApiKeyInfo(subArgs);
        break;
      case 'revoke':
        await _revokeApiKey(subArgs);
        break;
      case 'list':
        await _listApiKeys(subArgs);
        break;
      default:
        print('Unknown subcommand: $subCommand');
        _printUsage();
        exit(1);
    }
  }

  void _printUsage() {
    print('Usage: dart_cloud apikey <subcommand> [options]');
    print('');
    print('Subcommands:');
    print('  generate  Generate a new API key for a function');
    print('  info      Get API key info for a function');
    print('  revoke    Revoke an API key');
    print('  list      List all API keys for a function');
    print('');
    print('Examples:');
    print('  dart_cloud apikey generate --validity 1d');
    print(
      '  dart_cloud apikey generate --function-id <uuid> --validity 1w --name "Production Key"',
    );
    print('  dart_cloud apikey info');
    print('  dart_cloud apikey revoke --key-id <uuid>');
    print('  dart_cloud apikey list');
    print('');
    print('Validity options: ${ApiKeyValidity.validOptions.join(', ')}');
  }

  Future<void> _generateApiKey(List<String> args) async {
    final parser = ArgParser()
      ..addOption(
        'function-id',
        abbr: 'f',
        help: 'Function ID (uses current directory config if not provided)',
      )
      ..addOption(
        'validity',
        abbr: 'v',
        help: 'Key validity: ${ApiKeyValidity.validOptions.join(', ')}',
        defaultsTo: '1d',
      )
      ..addOption(
        'name',
        abbr: 'n',
        help: 'Optional friendly name for the key',
      );

    final parsedArgs = parser.parse(args);
    final validity = parsedArgs['validity'] as String;
    final name = parsedArgs['name'] as String?;

    // Validate validity
    if (!ApiKeyValidity.isValid(validity)) {
      print(
        'Error: Invalid validity. Must be one of: ${ApiKeyValidity.validOptions.join(', ')}',
      );
      exit(1);
    }

    // Get function ID
    String? functionId = parsedArgs['function-id'] as String?;
    String? functionPath;

    if (functionId == null) {
      // Try to load from current directory config
      final currentDir = Directory.current;
      final existingConfig = await FunctionConfig.load(currentDir.path);

      if (existingConfig?.functionId == null) {
        print(
          'Error: No function ID provided and no function config found in current directory.',
        );
        print(
          'Either provide --function-id or run this command from a deployed function directory.',
        );
        exit(1);
      }

      functionId = existingConfig!.functionId!;
      functionPath = currentDir.path;
      print('Using function from config: ${existingConfig.functionName}');
    }

    try {
      print('Generating API key...');
      print('  Validity: $validity');
      if (name != null) print('  Name: $name');

      final response = await ApiClient.generateApiKey(
        functionId: functionId,
        validity: validity,
        name: name,
      );

      final apiKey = response['api_key'] as Map<String, dynamic>;
      final secretKey = apiKey['secret_key'] as String;
      final keyUuid = apiKey['uuid'] as String;
      final expiresAt = apiKey['expires_at'] as String?;

      print('');
      print('✓ API key generated successfully!');
      print('');
      print(
        '╔════════════════════════════════════════════════════════════════════╗',
      );
      print(
        '║  ⚠️  IMPORTANT: Store the secret key securely!                     ║',
      );
      print(
        '║  It will NOT be shown again.                                       ║',
      );
      print(
        '╚════════════════════════════════════════════════════════════════════╝',
      );
      print('');
      print('Key UUID: $keyUuid');
      print('Secret Key: $secretKey');
      print('Validity: $validity');
      if (expiresAt != null) print('Expires At: $expiresAt');
      print('');

      // Save to Hive storage
      try {
        await ApiKeyStorage.storeApiKey(functionId, secretKey);
        print('✓ Secret key stored securely in Hive database');
      } catch (e) {
        print('✗ Warning: Failed to store secret key in Hive: $e');
      }

      // Update function config with API key info (no secret key stored here)
      if (functionPath != null) {
        final existingConfig = await FunctionConfig.load(functionPath);
        if (existingConfig != null) {
          final updatedConfig = existingConfig.copyWith(
            apiKeyUuid: keyUuid,
            apiKeyValidity: validity,
            apiKeyExpiresAt: expiresAt,
          );
          await updatedConfig.save(functionPath);
          print('✓ Function config updated with API key info');
        }

        print('');
        print('The secret key has been stored securely in Hive database');
        print('Location: ~/.dart_cloud/hive/');
        print('');
        print(
          'Use "dart_cloud invoke --sign" to invoke the function with signature verification.',
        );
      } else {
        print('');
        print('The secret key has been stored securely in Hive database');
        print('Location: ~/.dart_cloud/hive/');
      }
    } catch (e) {
      print('✗ Failed to generate API key: $e');
      exit(1);
    }
  }

  Future<void> _getApiKeyInfo(List<String> args) async {
    final parser = ArgParser()
      ..addOption(
        'function-id',
        abbr: 'f',
        help: 'Function ID (uses current directory config if not provided)',
      );

    final parsedArgs = parser.parse(args);

    // Get function ID
    String? functionId = parsedArgs['function-id'] as String?;

    if (functionId == null) {
      final currentDir = Directory.current;
      final existingConfig = await FunctionConfig.load(currentDir.path);

      if (existingConfig?.functionId == null) {
        print('Error: No function ID provided and no function config found.');
        exit(1);
      }

      functionId = existingConfig!.functionId!;
      print('Using function: ${existingConfig.functionName}');
    }

    try {
      final response = await ApiClient.getApiKeyInfo(functionId);
      final hasApiKey = response['has_api_key'] as bool;

      if (!hasApiKey) {
        print('No active API key for this function.');
        print('Use "dart_cloud apikey generate" to create one.');
        return;
      }

      final apiKey = response['api_key'] as Map<String, dynamic>;
      print('');
      print('API Key Info:');
      print('  UUID: ${apiKey['uuid']}');
      print(
        '  Public Key: ${(apiKey['public_key'] as String).substring(0, 20)}...',
      );
      print('  Validity: ${apiKey['validity']}');
      print('  Active: ${apiKey['is_active']}');
      if (apiKey['expires_at'] != null) {
        print('  Expires At: ${apiKey['expires_at']}');
      }
      if (apiKey['name'] != null) {
        print('  Name: ${apiKey['name']}');
      }
      if (apiKey['created_at'] != null) {
        print('  Created At: ${apiKey['created_at']}');
      }
    } catch (e) {
      print('✗ Failed to get API key info: $e');
      exit(1);
    }
  }

  Future<void> _revokeApiKey(List<String> args) async {
    final parser = ArgParser()
      ..addOption(
        'key-id',
        abbr: 'k',
        help: 'API key UUID to revoke',
      );

    final parsedArgs = parser.parse(args);
    String? keyId = parsedArgs['key-id'] as String?;

    if (keyId == null) {
      // Try to get from current directory config
      final currentDir = Directory.current;
      final existingConfig = await FunctionConfig.load(currentDir.path);

      if (existingConfig?.apiKeyUuid == null) {
        print(
          'Error: No key ID provided and no API key found in current directory config.',
        );
        print('Use --key-id to specify the API key UUID to revoke.');
        exit(1);
      }

      keyId = existingConfig!.apiKeyUuid!;
      print('Revoking API key from config: $keyId');
    }

    try {
      await ApiClient.revokeApiKey(keyId);
      print('✓ API key revoked successfully.');

      // Clean up from Hive storage and function config
      final currentDir = Directory.current;
      final existingConfig = await FunctionConfig.load(currentDir.path);

      if (existingConfig?.apiKeyUuid == keyId &&
          existingConfig?.functionId != null) {
        // Delete from Hive storage
        try {
          await ApiKeyStorage.deleteApiKey(existingConfig!.functionId!);
          print('✓ Private key removed from Hive storage');
        } catch (e) {
          print('✗ Warning: Failed to remove private key from Hive: $e');
        }

        // Update config to remove API key info
        final updatedConfig = FunctionConfig(
          functionName: existingConfig!.functionName,
          functionId: existingConfig.functionId,
          createdAt: existingConfig.createdAt,
          functionPath: existingConfig.functionPath,
          lastDeployHash: existingConfig.lastDeployHash,
          lastDeployedAt: existingConfig.lastDeployedAt,
          deployVersion: existingConfig.deployVersion,
        );
        await updatedConfig.save(currentDir.path);
        print('✓ Function config updated.');
      }
    } catch (e) {
      print('✗ Failed to revoke API key: $e');
      exit(1);
    }
  }

  Future<void> _listApiKeys(List<String> args) async {
    final parser = ArgParser()
      ..addOption(
        'function-id',
        abbr: 'f',
        help: 'Function ID (uses current directory config if not provided)',
      );

    final parsedArgs = parser.parse(args);

    // Get function ID
    String? functionId = parsedArgs['function-id'] as String?;

    if (functionId == null) {
      final currentDir = Directory.current;
      final existingConfig = await FunctionConfig.load(currentDir.path);

      if (existingConfig?.functionId == null) {
        print('Error: No function ID provided and no function config found.');
        exit(1);
      }

      functionId = existingConfig!.functionId!;
      print('Using function: ${existingConfig.functionName}');
    }

    try {
      final response = await ApiClient.listApiKeys(functionId);
      final apiKeys = response['api_keys'] as List<dynamic>;

      if (apiKeys.isEmpty) {
        print('No API keys found for this function.');
        return;
      }

      print('');
      print('API Keys (${apiKeys.length}):');
      print('─' * 80);

      for (final key in apiKeys) {
        final keyMap = key as Map<String, dynamic>;
        final isActive = keyMap['is_active'] as bool;
        final status = isActive ? '✓ Active' : '✗ Revoked';

        print('');
        print('  $status');
        print('  UUID: ${keyMap['uuid']}');
        print('  Validity: ${keyMap['validity']}');
        if (keyMap['name'] != null) {
          print('  Name: ${keyMap['name']}');
        }
        if (keyMap['expires_at'] != null) {
          print('  Expires At: ${keyMap['expires_at']}');
        }
        if (keyMap['created_at'] != null) {
          print('  Created At: ${keyMap['created_at']}');
        }
      }

      print('');
      print('─' * 80);
    } catch (e) {
      print('✗ Failed to list API keys: $e');
      exit(1);
    }
  }
}
