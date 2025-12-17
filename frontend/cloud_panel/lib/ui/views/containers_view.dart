import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

@RoutePage()
class ContainersView extends StatelessWidget {
  const ContainersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.layers,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'Containers',
            style: context.theme.typography.lg.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Container management coming soon',
            style: context.theme.typography.sm.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
