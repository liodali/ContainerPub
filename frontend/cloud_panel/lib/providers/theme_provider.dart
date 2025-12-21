import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:hive_ce/hive.dart';

enum AppThemeMode {
  light,
  dark,
  system;

  String get name {
    switch (this) {
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.dark:
        return 'dark';
      case AppThemeMode.system:
        return 'system';
    }
  }

  static AppThemeMode fromString(String value) {
    switch (value) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      case 'system':
      default:
        return AppThemeMode.system;
    }
  }
}

class ThemeNotifier extends Notifier<AppThemeMode> {
  static const _boxName = 'settings';
  static const _keyName = 'theme_mode';

  @override
  AppThemeMode build() {
    _loadTheme();
    return AppThemeMode.system;
  }

  Future<void> _loadTheme() async {
    final box = await Hive.openBox(_boxName);
    final savedTheme = box.get(_keyName);
    if (savedTheme != null) {
      state = AppThemeMode.fromString(savedTheme);
    }
  }

  Future<void> setTheme(AppThemeMode mode) async {
    final box = await Hive.openBox(_boxName);
    await box.put(_keyName, mode.name);
    state = mode;
  }

  Future<void> toggleTheme() async {
    if (state == AppThemeMode.light) {
      await setTheme(AppThemeMode.dark);
    } else {
      await setTheme(AppThemeMode.light);
    }
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, AppThemeMode>(ThemeNotifier.new);

final fThemeDataProvider = Provider<FThemeData>((ref) {
  final mode = ref.watch(themeProvider);
  if (mode == AppThemeMode.system) {
    // In a real app, you might want to listen to platform brightness changes.
    // However, since this provider is watched, if we want it to update on system change,
    // we should technically watch a provider that listens to WidgetsBindingObserver.
    // For now, this suffices for initial load and explicit toggles.
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark ? FThemes.zinc.dark : FThemes.zinc.light;
  }
  return mode == AppThemeMode.dark ? FThemes.zinc.dark : FThemes.zinc.light;
});
