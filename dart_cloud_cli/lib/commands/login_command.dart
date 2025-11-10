import 'dart:io';
import 'package:dart_cloud_cli/api/api_client.dart';
import 'package:dart_cloud_cli/commands/base_command.dart' show BaseCommand;

class LoginCommand extends BaseCommand {
  Future<void> execute(List<String> args) async {
    await config.loadConfig();

    stdout.write('Email: ');
    final email = stdin.readLineSync() ?? '';

    stdout.write('Password: ');
    stdin.echoMode = false;
    final password = stdin.readLineSync() ?? '';
    stdin.echoMode = true;
    print('');

    if (email.isEmpty || password.isEmpty) {
      print('Error: Email and password are required');
      exit(1);
    }

    try {
      print('Authenticating...');
      final response = await ApiClient.login(email, password);
      final token = response['token'] as String;
      final refreshToken = response['refreshToken'] as String;

      await config.saveAuth(token: token, refreshToken: refreshToken);
      print('✓ Successfully logged in!');
    } catch (e) {
      print('✗ Login failed: $e');
      exit(1);
    }
  }
}
