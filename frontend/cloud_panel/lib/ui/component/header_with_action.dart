import 'package:flutter/material.dart'
    show
        StatelessWidget,
        Row,
        VoidCallback,
        BuildContext,
        Widget,
        MainAxisAlignment,
        FontWeight,
        Text,
        MainAxisSize,
        Icons,
        Icon,
        SizedBox;
import 'package:forui/forui.dart';

class HeaderWithAction extends StatelessWidget {
  final String title;
  final VoidCallback onActionPress;

  const HeaderWithAction({
    super.key,
    required this.title,
    required this.onActionPress,
    this.hideAction = false,
  });

  final bool hideAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: context.theme.typography.base.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (!hideAction) ...[
          FButton(
            onPress: onActionPress,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 16),
                SizedBox(width: 8),
                Text('Create'),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
