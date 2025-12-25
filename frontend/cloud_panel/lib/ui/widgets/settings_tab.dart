import 'package:cloud_api_client/cloud_api_client.dart';
import 'package:cloud_panel/providers/api_client_provider.dart';
import 'package:cloud_panel/providers/common_provider.dart';
import 'package:cloud_panel/providers/functions_provider.dart';
import 'package:cloud_panel/ui/component/clipboard_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:auto_route/auto_route.dart';
import 'package:cloud_panel/l10n/app_localizations.dart';

class SettingsTab extends ConsumerWidget {
  final CloudFunction func;

  const SettingsTab({
    super.key,
    required this.func,
  });

  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: FCard(
            title: const Text('Delete Function'),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Are you sure you want to delete "${func.name}"? This action cannot be undone.',
                  style: context.theme.typography.base,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FButton.raw(
                      onPress: () => Navigator.of(dialogContext).pop(),
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                    const SizedBox(width: 8),
                    FButton(
                      style: FButtonStyle.destructive(),
                      onPress: () async {
                        try {
                          final client = ref.read(apiClientProvider);
                          await client.deleteFunction(func.uuid);
                          ref.invalidate(functionsProvider);
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                          if (context.mounted) {
                            context.router.pop();
                          }
                        } catch (e) {
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to delete function: $e'),
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseUrl = ref.watch(baseURLProvider);
    final publicUrl = '$baseUrl/api/functions/${func.uuid}/invoke';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FCard(
            title: const Text('General Settings'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Skip Signing',
                        style: context.theme.typography.base,
                      ),
                    ),
                    FCheckbox(
                      value: func.skipSigning,
                      onChange: null,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'This setting is configured during function creation and cannot be modified.',
                  style: context.theme.typography.sm.copyWith(
                    color: context.theme.colors.foreground.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FCard(
            title: const Text('Public URL'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Use this URL to invoke your function:',
                  style: context.theme.typography.sm.copyWith(
                    color: context.theme.colors.foreground.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.theme.colors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: context.theme.colors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          publicUrl,
                          style: context.theme.typography.sm.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FTappable(
                        onPress: () {
                          Clipboard.setData(ClipboardData(text: publicUrl));
                          showClipboardToast(
                            context,
                            AppLocalizations.of(
                              context,
                            )!.copiedToClipboard(publicUrl),
                          );
                        },
                        child: Icon(
                          Icons.copy,
                          size: 16,
                          color: context.theme.colors.foreground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FCard(
            title: Text(
              'Danger Zone',
              style: context.theme.typography.lg.copyWith(
                color: context.theme.colors.error,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delete Function',
                  style: context.theme.typography.base.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Once you delete a function, there is no going back. Please be certain.',
                  style: context.theme.typography.sm.copyWith(
                    color: context.theme.colors.foreground.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 16),
                FButton(
                  style: FButtonStyle.destructive(),
                  onPress: () => _showDeleteConfirmDialog(context, ref),
                  child: const Text('Delete Function'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
