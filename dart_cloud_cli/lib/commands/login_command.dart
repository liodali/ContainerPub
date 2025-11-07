import 'dart:io';
import 'package:dart_cloud_cli/api/api_client.dart';
import 'package:dart_cloud_cli/config/config.dart';

class LoginCommand {
  Future<void> execute(List<String> args) async {
    await Config.load();

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

      await Config.save(authToken: token);
      print('✓ Successfully logged in!');
    } catch (e) {
      print('✗ Login failed: $e');
      exit(1);
    }
  }
}
