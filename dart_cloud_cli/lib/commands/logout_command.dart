import 'dart:io';
import 'package:dart_cloud_cli/commands/base_command.dart' show BaseCommand;

class LogoutCommand extends BaseCommand {
  Future<void> execute(List<String> args) async {
    await config.loadConfig();

    if (!config.isAuthenticated) {
      print('You are not logged in.');
      return;
    }

    try {
      print('Logging out...');
      await config.clearAuth();
      print('✓ Successfully logged out!');
      print('Your authentication token has been removed.');
    } catch (e) {
      print('✗ Logout failed: $e');
      exit(1);
    }
  }
}
