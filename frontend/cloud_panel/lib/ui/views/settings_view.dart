import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Settings',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        FCard(
          title: const Text('Developer Settings'),
          child: Column(
            children: [
              FButton(
                style: FButtonStyle.outline(),
                onPress: () {},
                child: const Text('Manage API Keys'),
              ),
              const SizedBox(height: 12),
              FButton(
                style: FButtonStyle.outline(),
                onPress: () {},
                child: const Text('Billing'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
