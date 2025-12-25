import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:cloud_panel/l10n/app_localizations.dart';

class RollbackConfirmDialog extends StatefulWidget {
  final String funcUuid;
  final String depUuid;
  final VoidCallback onConfirm;

  const RollbackConfirmDialog({
    super.key,
    required this.funcUuid,
    required this.depUuid,
    required this.onConfirm,
  });

  @override
  State<RollbackConfirmDialog> createState() => _RollbackConfirmDialogState();
}

class _RollbackConfirmDialogState extends State<RollbackConfirmDialog> {
  late TextEditingController _funcUuidController;
  late TextEditingController _depUuidController;

  @override
  void initState() {
    super.initState();
    _funcUuidController = TextEditingController();
    _depUuidController = TextEditingController();
  }

  @override
  void dispose() {
    _funcUuidController.dispose();
    _depUuidController.dispose();
    super.dispose();
  }

  bool get _isConfirmEnabled =>
      _funcUuidController.text == widget.funcUuid &&
      _depUuidController.text == widget.depUuid;

  @override
  Widget build(BuildContext context) {
    return FDialog(
      title: Text(AppLocalizations.of(context)!.confirmRollback),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Text(
            AppLocalizations.of(context)!.rollbackWarning,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.theme.colors.background,
              border: Border.all(color: context.theme.colors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(
                      "${AppLocalizations.of(context)!.functionUuid}:",
                      style: context.theme.typography.xs.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.theme.colors.foreground,
                      ),
                    ),
                    SelectableText(
                      widget.funcUuid,
                      style: context.theme.typography.sm.copyWith(
                        fontFamily: 'monospace',
                        color: context.theme.colors.foreground,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(
                      "${AppLocalizations.of(context)!.deploymentUuid}:",
                      style: context.theme.typography.xs.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.theme.colors.foreground,
                      ),
                    ),
                    SelectableText(
                      widget.depUuid,
                      style: context.theme.typography.sm.copyWith(
                        fontFamily: 'monospace',
                        color: context.theme.colors.foreground,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Text(
            'To confirm, please re-enter both UUIDs below:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Text(
                    'Function UUID',
                    style: context.theme.typography.xs.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ListenableBuilder(
                    listenable: _funcUuidController,
                    builder: (context, _) => FTextField(
                      control: .managed(controller: _funcUuidController),
                      hint: 'Enter function UUID',
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Text(
                    'Deployment UUID',
                    style: context.theme.typography.xs.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ListenableBuilder(
                    listenable: _depUuidController,
                    builder: (context, _) => FTextField(
                      control: .managed(controller: _depUuidController),
                      hint: 'Enter deployment UUID',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        FButton(
          onPress: () => Navigator.pop(context),
          style: FButtonStyle.secondary(),
          child: const Text('Cancel'),
        ),
        FButton(
          onPress: _isConfirmEnabled ? widget.onConfirm : null,
          style: FButtonStyle.destructive(),
          child: const Text('Confirm Rollback'),
        ),
      ],
    );
  }
}
