import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final BuildContext context;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return FCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text(
            label,
            style: context.theme.typography.sm.copyWith(
              color: context.theme.colors.foreground,
            ),
          ),
          Text(
            value,
            style: context.theme.typography.lg.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
