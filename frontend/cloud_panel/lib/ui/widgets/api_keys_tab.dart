import 'package:cloud_panel/providers/api_client_provider.dart';
import 'package:cloud_panel/providers/function_details_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

class ApiKeysTab extends ConsumerWidget {
  final String uuid;
  const ApiKeysTab({required this.uuid, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keysAsync = ref.watch(functionApiKeysProvider(uuid));

    return SizedBox(
      height: MediaQuery.sizeOf(context).height - 120,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FButton(
              onPress: () => _generateKey(context, ref),
              child: const Text('Generate New API Key'),
            ),
          ),
          keysAsync.when(
            data: (keys) {
              if (keys.isEmpty) {
                return const Center(
                  child: Text('No API keys'),
                );
              }

              return Expanded(
                child: ListView.separated(
                  itemCount: keys.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final key = keys[index];
                    return FCard(
                      title: Text(key.name ?? 'Unnamed Key'),
                      subtitle: Text(
                        'Prefix: ${key.uuid.substring(0, 8)}... • Active: ${key.isActive}',
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FButton(
                            onPress: () => _revokeKey(context, ref, key.uuid),
                            child: const Text('Revoke'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: FCircularProgress()),
            error: (e, s) => Center(
              child: FAlert(
                title: const Text('Oppssy!! Cannot load apikey function'),
                subtitle: Text('Something went wrong'),
                style: FAlertStyle.destructive(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateKey(BuildContext context, WidgetRef ref) async {
    final client = ref.read(apiClientProvider);
    try {
      final result = await client.generateApiKey(uuid, name: 'New Key');
      if (context.mounted) {
        showFDialog(
          context: context,
          builder: (ctx, style, _) => FDialog(
            style: (_) => style,
            title: const Text('API Key Generated'),
            body: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 10,
              children: [
                const Text(
                  'Please copy your secret key. It will not be shown again.',
                ),
                SelectableText(
                  result.secretKey,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                FButton(
                  onPress: () {
                    Clipboard.setData(ClipboardData(text: result.secretKey));
                    ScaffoldMessenger.of(
                      ctx,
                    ).showSnackBar(const SnackBar(content: Text('Copied!')));
                  },
                  child: const Text('Copy to Clipboard'),
                ),
              ],
            ),
            actions: [
              FButton(
                onPress: () => Navigator.pop(ctx),
                style: FButtonStyle.ghost(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
      ref.invalidate(functionApiKeysProvider(uuid));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
          ),
        );
      }
    }
  }

  Future<void> _revokeKey(
    BuildContext context,
    WidgetRef ref,
    String keyUuid,
  ) async {
    try {
      await ref.read(apiClientProvider).revokeApiKey(keyUuid);
      ref.invalidate(functionApiKeysProvider(uuid));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
          ),
        );
      }
    }
  }
}
