import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_panel/providers/locale_provider.dart';
import 'package:cloud_panel/providers/theme_provider.dart';
import 'package:cloud_panel/l10n/app_localizations.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.settings,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        FCard(
          title: Text(AppLocalizations.of(context)!.theme),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FButton(
                style: ref.watch(themeProvider) == AppThemeMode.light
                    ? FButtonStyle.primary()
                    : FButtonStyle.outline(),
                onPress: () => ref
                    .read(themeProvider.notifier)
                    .setTheme(AppThemeMode.light),
                prefix: const Icon(FIcons.sun, size: 16),
                child: Text(
                  AppLocalizations.of(context)!.lightMode,
                ),
              ),
              FButton(
                style: ref.watch(themeProvider) == AppThemeMode.dark
                    ? FButtonStyle.primary()
                    : FButtonStyle.outline(),
                onPress: () => ref
                    .read(themeProvider.notifier)
                    .setTheme(AppThemeMode.dark),
                prefix: const Icon(FIcons.moon, size: 16),
                child: Text(AppLocalizations.of(context)!.darkMode),
              ),
              FButton(
                style: ref.watch(themeProvider) == AppThemeMode.system
                    ? FButtonStyle.primary()
                    : FButtonStyle.outline(),
                onPress: () => ref
                    .read(themeProvider.notifier)
                    .setTheme(AppThemeMode.system),
                prefix: const Icon(FIcons.monitor, size: 16),
                child: Text(AppLocalizations.of(context)!.systemTheme),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FCard(
          title: Text(AppLocalizations.of(context)!.changeLanguage),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical:8.0),
            child: Row(
              children: [
                FButton(
                  style: ref.watch(localeProvider).languageCode == 'en'
                      ? FButtonStyle.primary()
                      : FButtonStyle.outline(),
                  onPress: () => ref
                      .read(localeProvider.notifier)
                      .setLocale(const Locale('en')),
                  child:  Text(AppLocalizations.of(context)!.english),
                ),
                const SizedBox(width: 12),
                FButton(
                  style: ref.watch(localeProvider).languageCode == 'fr'
                      ? FButtonStyle.primary()
                      : FButtonStyle.outline(),
                  onPress: () => ref
                      .read(localeProvider.notifier)
                      .setLocale(const Locale('fr')),
                  child:  Text(AppLocalizations.of(context)!.french),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FCard(
          title: Text(AppLocalizations.of(context)!.developerSettings),
          child: Column(
            children: [
              FButton(
                style: FButtonStyle.outline(),
                onPress: () {},
                child: Text(AppLocalizations.of(context)!.manageApiKeys),
              ),
              const SizedBox(height: 12),
              FButton(
                style: FButtonStyle.outline(),
                onPress: () {},
                child: Text(AppLocalizations.of(context)!.billing),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
