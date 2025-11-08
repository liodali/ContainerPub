import 'dart:io';
import 'package:dart_cloud_cli/config/config.dart';

class LogoutCommand {
  Future<void> execute(List<String> args) async {
    await Config.load();

    if (!Config.isAuthenticated) {
      print('You are not logged in.');
      return;
    }

    try {
      print('Logging out...');
      await Config.clear();
      print('✓ Successfully logged out!');
      print('Your authentication token has been removed.');
    } catch (e) {
      print('✗ Logout failed: $e');
      exit(1);
    }
  }
}
