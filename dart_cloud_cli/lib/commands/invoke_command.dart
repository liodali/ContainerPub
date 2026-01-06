import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dart_cloud_cli/api/api_client.dart';
import 'package:dart_cloud_cli/commands/base_command.dart' show BaseCommand;
import 'package:dart_cloud_cli/services/api_key_storage.dart';

class InvokeCommand extends BaseCommand {
  Future<void> execute(List<String> args) async {
    await config.loadConfig();

    if (!config.isAuthenticated) {
      print('Error: Not authenticated. Please run "dart_cloud login" first.');
      exit(1);
    }

    if (args.isEmpty) {
      print('Error: Please specify the function ID');
      print(
        'Usage: dart_cloud invoke <function-id> [--data \'{"key": "value"}\'] [--sign]',
      );
      exit(1);
    }

    final functionId = args[0];
    Map<String, dynamic>? data;
    bool useSignature = false;

    // Parse optional arguments
    if (args.contains('--sign')) {
      useSignature = true;
    }
    // Parse optional arguments
    if (args.contains('--skip-sign')) {
      useSignature = false;
    }

    if (args.contains('--data')) {
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

    String? signature;
    int? timestamp;
    ApiKeyStorageData? secretKey;
    // Try to sign the request if --sign flag is used
    if (useSignature) {
      // First, try to get from Hive storage using function ID
      try {
        secretKey = await ApiKeyStorage.getApiKey(functionId);
        if (secretKey != null && secretKey.uuid.isEmpty) {
          print(
            'Warning: API key UUID is empty. Please run "dart_cloud apikey generate" first.',
          );
          exit(1);
        }
      } catch (e, trace) {
        print('Warning: Failed to retrieve API key');
      }

      // // Fallback: try to load from function config directory
      // if (secretKey == null) {
      //   final currentDir = Directory.current;
      //   secretKey = await FunctionConfig.loadPrivateKey(currentDir.path);
      // }

      if (secretKey == null) {
        print(
          'Warning: --sign flag used but no secret key found',
        );
        print(
          'Generate an API key first with: dart_cloud apikey generate',
        );
        exit(1);
      } else {
        // Create signature
        timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final payload = data != null ? jsonEncode(data) : '';
        signature = _createSignature(
          secretKey.privateKey,
          payload,
          timestamp,
        );
        print('✓ Request signed with API key');
      }
    }

    try {
      print('Invoking function: $functionId');
      final response = await ApiClient.invokeFunction(
        functionId,
        data,
        signature: signature,
        keyUUID: useSignature ? secretKey!.uuid : null,
        timestamp: timestamp,
      );

      print('\nFunction Response:');
      print('─' * 80);
      print(const JsonEncoder.withIndent('  ').convert(response));
      print('─' * 80);
      exit(0);
    } catch (e, trace) {
      print('✗ Failed to invoke function: $e');
      print(trace);
      exit(1);
    }
  }

  /// Create a signature for the payload using HMAC-SHA256
  String _createSignature(String secretKey, String payload, int timestamp) {
    final dataToSign = '$timestamp:$payload';
    final hmac = Hmac(sha256, utf8.encode(secretKey));
    final digest = hmac.convert(utf8.encode(dataToSign));
    return base64Encode(digest.bytes);
  }
}
