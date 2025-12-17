import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

@RoutePage()
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
              'Webhooks',
              style: context.theme.typography.lg.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Webhook management coming soon',
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
