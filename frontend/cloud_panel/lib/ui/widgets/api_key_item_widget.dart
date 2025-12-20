import 'package:cloud_api_client/cloud_api_client.dart';
import 'package:cloud_panel/providers/api_client_provider.dart';
import 'package:cloud_panel/providers/function_details_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

class ApiKeyItemWidget extends ConsumerStatefulWidget {
  const ApiKeyItemWidget({
    super.key,
    required this.apiKeyModel,
    required this.uuid,
  });
  final String uuid;
  final ApiKey apiKeyModel;
  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      ApiKeyItemWidgetState();
}

class ApiKeyItemWidgetState extends ConsumerState<ApiKeyItemWidget> {
  final ValueNotifier<bool> loadingRollNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> loadingRevokeNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> loadingEnableNotifier = ValueNotifier<bool>(false);
  bool isExpired = false;
  String expirationText = '';
  String creationText = '';
  Color statusColor = Colors.orange;
  String statusText = 'Inactive';

  Color getStatusColor() {
    if (isExpired) return Colors.red;
    if (widget.apiKeyModel.isActive) return Colors.green;
    return Colors.orange;
  }

  String getStatusText() {
    if (isExpired) return 'Expired';
    if (widget.apiKeyModel.isActive) return 'Active';
    return 'Inactive';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    isExpired =
        widget.apiKeyModel.expiresAt != null &&
        widget.apiKeyModel.expiresAt!.isBefore(DateTime.now());
    expirationText = widget.apiKeyModel.expiresAt != null
        ? dateFormatter.format(widget.apiKeyModel.expiresAt!)
        : 'Never';
    creationText = dateFormatter.format(widget.apiKeyModel.createdAt);

    statusColor = getStatusColor();
    statusText = getStatusText();
  }

  @override
  void dispose() {
    loadingRollNotifier.dispose();
    loadingRevokeNotifier.dispose();
    loadingEnableNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FCard(
      title: Text(widget.apiKeyModel.name ?? 'Unnamed Key'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prefix: ${widget.apiKeyModel.uuid.substring(0, 8)}...',
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  border: Border.all(color: statusColor),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Created: $creationText',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            'Expires: $expirationText',
            style: TextStyle(
              fontSize: 12,
              color: isExpired ? Colors.red : null,
              fontWeight: isExpired ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        spacing: 8,
        children: [
          FButton(
            onPress: () => _deleteKey(
              context,
              ref,
              widget.apiKeyModel.uuid,
              widget.apiKeyModel.name ?? 'Unnamed Key',
            ),
            style: FButtonStyle.destructive(),
            child: const Text('Delete'),
          ),
          if (widget.apiKeyModel.isActive && !isExpired) ...[
            ValueListenableBuilder(
              valueListenable: loadingRevokeNotifier,
              builder: (context, isLoading, child) {
                return FButton(
                  onPress: isLoading
                      ? null
                      : () => _revokeKey(
                          context,
                          widget.apiKeyModel.uuid,
                        ),
                  style: FButtonStyle.secondary(),
                  child: isLoading
                      ? const FCircularProgress()
                      : const Text('Revoke'),
                );
              },
            ),
            if (widget.apiKeyModel.expiresAt != null) ...[
              ValueListenableBuilder(
                valueListenable: loadingRollNotifier,
                builder: (context, isLoading, child) {
                  return FButton(
                    onPress: isLoading
                        ? null
                        : () => _rollKey(
                            context,
                            widget.apiKeyModel.uuid,
                          ),
                    style: FButtonStyle.primary(),
                    prefix: isLoading ? const FCircularProgress() : null,
                    child: const Text('Roll'),
                  );
                },
              ),
            ],
          ] else if (!isExpired) ...[
            ValueListenableBuilder(
              valueListenable: loadingEnableNotifier,
              builder: (context, isLoading, child) {
                return FButton(
                  onPress: isLoading
                      ? null
                      : () => _enableKey(
                          context,
                          widget.apiKeyModel.uuid,
                          widget.apiKeyModel.name,
                        ),
                  style: FButtonStyle.primary(),
                  prefix: isLoading ? const FCircularProgress() : null,
                  child: const Text('Activate'),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _enableKey(
    BuildContext context,
    String keyUuid,
    String? currentName,
  ) async {
    if (!context.mounted) return;

    final nameController = TextEditingController();
    final newName = await showFDialog<String>(
      context: context,
      builder: (ctx, style, _) => _EnableKeyDialog(
        keyName: currentName ?? '',
        controller: nameController,
        style: style,
      ),
    );

    nameController.dispose();

    if (newName == null) return;

    try {
      loadingEnableNotifier.value = true;
      await ref
          .read(apiClientProvider)
          .enableApiKey(
            keyUuid,
            name: newName,
          );
      ref.invalidate(functionApiKeysProvider(widget.uuid));
      if (context.mounted) {
        showFToast(
          context: context,
          style: (style) => style.copyWith(
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(200),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          title: Text(
            'API key activated successfully',
            style: context.theme.typography.sm.copyWith(
              color: context.theme.colors.background,
            ),
          ),
          alignment: FToastAlignment.bottomCenter,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showFToast(
          context: context,
          style: (style) => style.copyWith(
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(100),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          title: const Text('Oppssy!! Cannot activate apikey function'),
          alignment: FToastAlignment.bottomCenter,
        );
      }
    } finally {
      loadingEnableNotifier.value = false;
    }
  }

  Future<void> _revokeKey(
    BuildContext context,
    String keyUuid,
  ) async {
    try {
      loadingRevokeNotifier.value = true;
      await ref.read(apiClientProvider).revokeApiKey(keyUuid);
      ref.invalidate(functionApiKeysProvider(widget.uuid));
    } catch (e) {
      if (context.mounted) {
        showFToast(
          context: context,
          style: (style) => style.copyWith(
            decoration: BoxDecoration(
              color: context.theme.colors.background.withAlpha(100),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: context.theme.colors.error),
            ),
          ),
          title: Text(
            'Oppssy!! Cannot revoke apikey function',
            style: context.theme.typography.sm.copyWith(
              color: context.theme.colors.error,
            ),
          ),
          alignment: FToastAlignment.bottomCenter,
        );
      }
    } finally {
      loadingRevokeNotifier.value = false;
    }
  }

  Future<void> _rollKey(
    BuildContext context,
    String keyUuid,
  ) async {
    try {
      loadingRollNotifier.value = true;
      await ref.read(apiClientProvider).rollApiKey(keyUuid);
      ref.invalidate(functionApiKeysProvider(widget.uuid));
      if (context.mounted) {
        showFToast(
          context: context,
          style: (style) => style.copyWith(
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(200),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          title: Text(
            'API key rolled successfully',
            style: context.theme.typography.sm.copyWith(
              color: context.theme.colors.background,
            ),
          ),
          alignment: FToastAlignment.bottomCenter,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showFToast(
          context: context,
          style: (style) => style.copyWith(
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(100),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          title: const Text('Oppssy!! Cannot roll apikey function'),
          alignment: FToastAlignment.bottomCenter,
        );
      }
    } finally {
      loadingRollNotifier.value = false;
    }
  }

  Future<void> _deleteKey(
    BuildContext context,
    WidgetRef ref,
    String keyUuid,
    String keyName,
  ) async {
    if (!context.mounted) return;

    final nameController = TextEditingController();
    final confirmed = await showFDialog<bool>(
      context: context,
      builder: (ctx, style, _) => _DeleteKeyDialog(
        keyName: keyName,
        controller: nameController,
        style: style,
      ),
    );

    nameController.dispose();

    if (confirmed != true) return;

    if (!context.mounted) return;

    try {
      await ref.read(apiClientProvider).deleteApiKey(keyUuid);
      ref.invalidate(functionApiKeysProvider(widget.uuid));
      if (context.mounted) {
        showFToast(
          context: context,
          alignment: FToastAlignment.bottomCenter,
          title: const Text('API key deleted successfully'),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _DeleteKeyDialog extends StatefulWidget {
  final String keyName;
  final TextEditingController controller;
  final FDialogStyle style;

  const _DeleteKeyDialog({
    required this.keyName,
    required this.controller,
    required this.style,
  });

  @override
  State<_DeleteKeyDialog> createState() => _DeleteKeyDialogState();
}

class _DeleteKeyDialogState extends State<_DeleteKeyDialog> {
  bool get _isValid => widget.controller.text.trim() == widget.keyName;

  @override
  Widget build(BuildContext context) {
    return FDialog(
      style: (_) => widget.style,
      direction: Axis.horizontal,
      title: const Text('Delete API Key'),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This action cannot be undone. To confirm deletion, please enter the API key name:',
              style: TextStyle(fontSize: 13),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Key Name: ${widget.keyName}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) => FTextField(
                controller: widget.controller,
                hint: 'Enter key name to confirm',
                autofocus: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        FButton(
          onPress: () => Navigator.pop(context, false),
          style: FButtonStyle.secondary(),
          child: const Text('Cancel'),
        ),
        ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) => FButton(
            onPress: _isValid ? () => Navigator.pop(context, true) : null,
            style: FButtonStyle.destructive(),
            child: const Text('Delete'),
          ),
        ),
      ],
    );
  }
}

class _EnableKeyDialog extends StatelessWidget {
  final String keyName;
  final TextEditingController controller;
  final FDialogStyle style;

  const _EnableKeyDialog({
    required this.keyName,
    required this.controller,
    required this.style,
  });

  bool get _isValid => controller.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return FDialog(
      style: (_) => style.copyWith(
        verticalStyle: (style) => style.copyWith(),
      ),
      direction: Axis.horizontal,
      title: const Text('Enable API Key'),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please enter the API key name to enable it:',
              style: TextStyle(fontSize: 13),
            ),
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) => FTextField(
                controller: controller,
                hint: keyName,
                autofocus: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        FButton(
          onPress: () => Navigator.pop(context, null),
          style: FButtonStyle.secondary(),
          child: const Text('Cancel'),
        ),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => FButton(
            onPress: _isValid
                ? () => Navigator.pop(context, controller.text.trim())
                : null,
            style: FButtonStyle.primary(),
            child: const Text('Enable'),
          ),
        ),
      ],
    );
  }
}
