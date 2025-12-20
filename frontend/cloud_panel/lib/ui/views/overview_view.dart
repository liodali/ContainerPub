import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class OverviewView extends StatelessWidget {
  const OverviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: FCard(
                title: const Text('Total Functions'),
                subtitle: const Text('Active functions running'),
                child: const Text(
                  '0',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FCard(
                title: const Text('Total Invocations'),
                subtitle: const Text('In the last 30 days'),
                child: const Text(
                  '0',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FCard(
                title: const Text('Errors'),
                subtitle: const Text('In the last 24 hours'),
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
