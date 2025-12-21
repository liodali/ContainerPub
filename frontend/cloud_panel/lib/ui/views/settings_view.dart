import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_panel/providers/locale_provider.dart';
import 'package:cloud_panel/l10n/app_localizations.dart';

@RoutePage()
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
          title: Text(AppLocalizations.of(context)!.changeLanguage),
          child: Row(
            children: [
              FButton(
                style: ref.watch(localeProvider).languageCode == 'en'
                    ? FButtonStyle.primary()
                    : FButtonStyle.outline(),
                onPress: () => ref
                    .read(localeProvider.notifier)
                    .setLocale(const Locale('en')),
                child: const Text('English'),
              ),
              const SizedBox(width: 12),
              FButton(
                style: ref.watch(localeProvider).languageCode == 'fr'
                    ? FButtonStyle.primary()
                    : FButtonStyle.outline(),
                onPress: () => ref
                    .read(localeProvider.notifier)
                    .setLocale(const Locale('fr')),
                child: const Text('Français'),
              ),
            ],
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
