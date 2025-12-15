import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dart_cloud_cli/api/api_client.dart';
import 'package:dart_cloud_cli/commands/base_command.dart' show BaseCommand;
import 'package:dart_cloud_cli/common/function_config.dart';

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

    // Try to sign the request if --sign flag is used or if we have a private key
    if (useSignature) {
      final currentDir = Directory.current;
      final privateKey = await FunctionConfig.loadPrivateKey(currentDir.path);

      if (privateKey == null) {
        print(
            'Warning: --sign flag used but no private key found in .dart_tool/api_key.secret');
        print('Generate an API key first with: dart_cloud apikey generate');
      } else {
        // Create signature
        timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final payload = data != null ? jsonEncode(data) : '';
        signature = _createSignature(privateKey, payload, timestamp);
        print('✓ Request signed with API key');
      }
    }

    try {
      print('Invoking function: $functionId');
      final response = await ApiClient.invokeFunction(
        functionId,
        data,
        signature: signature,
        timestamp: timestamp,
      );

      print('\nFunction Response:');
      print('─' * 80);
      print(const JsonEncoder.withIndent('  ').convert(response));
      print('─' * 80);
    } catch (e) {
      print('✗ Failed to invoke function: $e');
      exit(1);
    }
  }

  /// Create a signature for the payload using HMAC-SHA256
  String _createSignature(String privateKey, String payload, int timestamp) {
    final dataToSign = '$timestamp:$payload';
    final hmac = Hmac(sha256, utf8.encode(privateKey));
    final digest = hmac.convert(utf8.encode(dataToSign));
    return base64Encode(digest.bytes);
  }
}
