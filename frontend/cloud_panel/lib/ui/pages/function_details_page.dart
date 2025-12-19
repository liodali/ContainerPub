import 'dart:convert';
import 'package:cloud_panel/common/commons.dart';
import 'package:cloud_panel/providers/api_client_provider.dart';
import 'package:cloud_panel/providers/function_details_provider.dart';
import 'package:cloud_panel/ui/component/header_with_action.dart';
import 'package:cloud_panel/ui/component/overview_tab.dart';
import 'package:cloud_panel/ui/widgets/deployments_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:flutter/services.dart';

class FunctionDetailsPage extends ConsumerStatefulWidget {
  final String uuid;
  final String name;
  const FunctionDetailsPage({
    super.key,
    required this.uuid,
    required this.name,
  });

  @override
  ConsumerState<FunctionDetailsPage> createState() =>
      _FunctionDetailsPageState();
}

class _FunctionDetailsPageState extends ConsumerState<FunctionDetailsPage>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final funcAsync = ref.watch(functionDetailsProvider(widget.uuid));

    return FScaffold(
      header: HeaderWithAction(
        prefix: FTappable(
          onPress: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back),
        ),
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.name,
                  style: context.theme.typography.lg.copyWith(
                    fontSize: 20,
                  ),
                ),
                ?funcAsync.value?.statusWidget,
              ],
            ),
            SelectableText(
              widget.uuid,
              style: context.theme.typography.xs.copyWith(
                fontSize: 12,
                color: context.theme.colors.foreground,
              ),
            ),
          ],
        ),
      ),
      child: funcAsync.when(
        data: (func) => FTabs(
          children: [
            FTabEntry(
              label: Text('Overview'),
              child: OverviewTab(func: func),
            ),
            FTabEntry(
              label: Text('Deployments'),
              child: DeploymentsTab(
                uuid: func.uuid,
              ),
            ),
            FTabEntry(
              label: Text('API Keys'),
              child: _ApiKeysTab(uuid: func.uuid),
            ),
            FTabEntry(
              label: Text('Invoke'),
              child: _InvokeTab(uuid: func.uuid),
            ),
          ],
        ),
        loading: () => const Center(child: FCircularProgress()),
        error: (err, stack) => Center(
          child: FAlert(
            title: const Text('Oppssy!! Cannot load function details'),
            subtitle: Text('Something went wrong'),
            style: FAlertStyle.destructive(),
          ),
        ),
      ),
    );
  }
}

class _ApiKeysTab extends ConsumerWidget {
  final String uuid;
  const _ApiKeysTab({required this.uuid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keysAsync = ref.watch(functionApiKeysProvider(uuid));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: FButton(
            onPress: () => _generateKey(context, ref),
            child: const Text('Generate New API Key'),
          ),
        ),
        Expanded(
          child: keysAsync.when(
            data: (keys) {
              if (keys.isEmpty) return const Center(child: Text('No API keys'));
              return ListView.separated(
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
                          // style: FButtonStyle.destructive,
                          onPress: () => _revokeKey(context, ref, key.uuid),
                          child: const Text('Revoke'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  Future<void> _generateKey(BuildContext context, WidgetRef ref) async {
    final client = ref.read(apiClientProvider);
    try {
      final result = await client.generateApiKey(uuid, name: 'New Key');
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('API Key Generated'),
            content: Column(
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

class _InvokeTab extends ConsumerStatefulWidget {
  final String uuid;
  const _InvokeTab({required this.uuid});

  @override
  ConsumerState<_InvokeTab> createState() => _InvokeTabState();
}

class _InvokeTabState extends ConsumerState<_InvokeTab> {
  final _bodyController = TextEditingController(text: '{}');
  final _secretController = TextEditingController();
  bool _isLoading = false;
  String? _response;
  bool _isError = false;
  bool _useSigning = true;

  Future<void> _invoke() async {
    setState(() {
      _isLoading = true;
      _response = null;
      _isError = false;
    });

    try {
      final client = ref.read(apiClientProvider);
      Map<String, dynamic>? body;

      if (_bodyController.text.isNotEmpty) {
        try {
          body = jsonDecode(_bodyController.text) as Map<String, dynamic>;
        } catch (e) {
          setState(() {
            _response = 'Invalid JSON: $e';
            _isError = true;
            _isLoading = false;
          });
          return;
        }
      }

      final secretKey = _useSigning
          ? (_secretController.text.isNotEmpty ? _secretController.text : null)
          : null;

      final result = await client.invokeFunction(
        widget.uuid,
        body: body,
        secretKey: secretKey,
      );

      setState(() {
        _response = jsonEncode(result);
      });
    } catch (e) {
      setState(() {
        _response = e.toString();
        _isError = true;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              const Text(
                'Request Body (JSON)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              FTextField(
                controller: _bodyController,
                maxLines: 5,
                hint: '{"key": "value"}',
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Signing (--sign)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  FSwitch(
                    value: _useSigning,
                    onChange: (value) {
                      setState(() => _useSigning = value);
                    },
                  ),
                ],
              ),
              if (_useSigning) ...[
                const Text(
                  'Secret Key (for signed requests)',
                  style: TextStyle(fontSize: 12),
                ),
                FTextField(
                  controller: _secretController,
                  obscureText: true,
                  hint: 'Enter your API secret key',
                ),
              ],
            ],
          ),
          FButton(
            onPress: _isLoading ? null : _invoke,
            child: _isLoading
                ? const Text('Invoking...')
                : const Text('Invoke Function'),
          ),
          if (_response != null) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Response:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    FButton(
                      onPress: () {
                        Clipboard.setData(ClipboardData(text: _response!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard!')),
                        );
                      },
                      style: FButtonStyle.ghost(),
                      child: const Text('Copy'),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isError
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                    border: Border.all(
                      color: _isError ? Colors.red : Colors.green,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SelectableText(_response!),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bodyController.dispose();
    _secretController.dispose();
    super.dispose();
  }
}
