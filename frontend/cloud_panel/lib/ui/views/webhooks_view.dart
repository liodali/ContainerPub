import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:cloud_panel/l10n/app_localizations.dart';

class WebhooksView extends StatelessWidget {
  const WebhooksView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.webhook,
            size: 48,
            color: Colors.grey,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(
              AppLocalizations.of(context)!.webhooks,
              style: context.theme.typography.lg.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              AppLocalizations.of(context)!.webhookManagementComingSoon,
              style: context.theme.typography.sm.copyWith(
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
