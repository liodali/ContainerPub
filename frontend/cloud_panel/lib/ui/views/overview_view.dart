import 'package:cloud_panel/providers/common_provider.dart';
import 'package:cloud_panel/ui/component/error_card_component.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:cloud_panel/l10n/app_localizations.dart';

class OverviewView extends ConsumerWidget {
  const OverviewView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewStats = ref.watch(overviewStatsProvider('30d'));
    if (overviewStats.isLoading) {
      return const Center(
        child: FCircularProgress(),
      );
    }
    if (overviewStats.hasError) {
      return Center(
        child: ErrorCardComponent(
          title: AppLocalizations.of(context)!.errorOverviewStats,
          subtitle: AppLocalizations.of(context)!.errorFetchOverviewStats,
        ),
      );
    }
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
                subtitle: Text(
                  AppLocalizations.of(context)!.activeFunctionsRunning,
                ),
                child: Text(
                  overviewStats.requireValue.totalFunctions.toString(),
                  style: context.theme.typography.sm.copyWith(
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
                child: Text(
                  overviewStats.requireValue.invocationsCount.toString(),
                  style: context.theme.typography.sm.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FCard(
                title: Text(AppLocalizations.of(context)!.errors),
                subtitle: Text(AppLocalizations.of(context)!.inTheLast24Hours),
                child: Text(
                  overviewStats.requireValue.errorCount.toString(),
                  style: context.theme.typography.sm.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
