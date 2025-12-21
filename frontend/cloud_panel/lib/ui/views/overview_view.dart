import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:auto_route/auto_route.dart';
import 'package:cloud_panel/l10n/app_localizations.dart';

@RoutePage()
class OverviewView extends StatelessWidget {
  const OverviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.overview,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: FCard(
                title: Text(AppLocalizations.of(context)!.totalFunctions),
                subtitle: Text(AppLocalizations.of(context)!.activeFunctionsRunning),
                child: const Text(
                  '0',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FCard(
                title: Text(AppLocalizations.of(context)!.totalInvocations),
                subtitle: Text(AppLocalizations.of(context)!.inTheLast30Days),
                child: const Text(
                  '0',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FCard(
                title: Text(AppLocalizations.of(context)!.errors),
                subtitle: Text(AppLocalizations.of(context)!.inTheLast24Hours),
                child: const Text(
                  '0',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
