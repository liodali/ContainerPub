import 'dart:io';
import 'package:dart_cloud_cli/commands/base_command.dart' show BaseCommand;

class LogoutCommand extends BaseCommand {
  Future<void> execute(List<String> args) async {
    await loadConfig();

    if (!isAuthenticated) {
      print('You are not logged in.');
      return;
    }

    try {
      print('Logging out...');
      await clearAuth();
      print('✓ Successfully logged out!');
      print('Your authentication token has been removed.');
    } catch (e) {
      print('✗ Logout failed: $e');
      exit(1);
    }
  }
}
