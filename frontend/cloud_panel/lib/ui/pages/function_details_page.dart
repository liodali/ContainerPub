import 'dart:convert';
import 'package:cloud_panel/common/commons.dart';
import 'package:cloud_panel/providers/api_client_provider.dart';
import 'package:cloud_panel/providers/function_details_provider.dart';
import 'package:cloud_panel/ui/component/header_with_action.dart';
import 'package:cloud_panel/ui/component/overview_tab.dart';
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
        data: (func) => Column(
          children: [
            Expanded(
              child: FTabs(
                children: [
                  FTabEntry(
                    label: Text('Overview'),
                    child: OverviewTab(func: func),
                  ),
                  FTabEntry(
                    label: Text('Deployments'),
                    child: SizedBox(
                      height: MediaQuery.sizeOf(context).height - 120,
                      child: _DeploymentsTab(uuid: func.uuid),
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

class _DeploymentsTab extends ConsumerWidget {
  final String uuid;
  const _DeploymentsTab({required this.uuid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deploymentsAsync = ref.watch(functionDeploymentsProvider(uuid));

    return deploymentsAsync.when(
      data: (deployments) {
        if (deployments.isEmpty) {
          return const Center(
            child: Text('No deployments'),
          );
        }

        final activeDeployment = deployments.firstWhere(
          (d) => d.isLatest,
          orElse: () => deployments.first,
        );
        final otherDeployments = deployments
            .where((d) => d.uuid != activeDeployment.uuid)
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Text(
                    'Active Deployment',
                    style: context.theme.typography.sm.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  FCard(
                    title: Text(
                      activeDeployment.uuid,
                      style: context.theme.typography.lg,
                    ),
                    subtitle: Text(
                      '${activeDeployment.status} • ${activeDeployment.createdAt.formattedDate} • Version ${activeDeployment.version}',
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FButton(
                          onPress: null,
                          style: FButtonStyle.secondary(),
                          child: const Text('Active'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (otherDeployments.isNotEmpty) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    Text(
                      'Previous Deployments',
                      style: context.theme.typography.sm.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ListView.separated(
                      itemCount: otherDeployments.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final dep = otherDeployments[index];
                        return FCard(
                          title: Text(
                            dep.uuid,
                            style: context.theme.typography.lg,
                          ),
                          subtitle: Text(
                            '${dep.status} • ${dep.createdAt.formattedDate} • Version ${dep.version}',
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              FButton(
                                onPress: () =>
                                    _rollback(context, ref, uuid, dep.uuid),
                                style: FButtonStyle.destructive(),
                                child: const Text('Rollback'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Future<void> _rollback(
    BuildContext context,
    WidgetRef ref,
    String funcUuid,
    String depUuid,
  ) async {
    if (!context.mounted) return;

    showFDialog(
      context: context,
      builder: (context, style, animation) => _RollbackConfirmDialog(
        funcUuid: funcUuid,
        depUuid: depUuid,
        onConfirm: () async {
          Navigator.pop(context);
          try {
            await ref
                .read(apiClientProvider)
                .rollbackFunction(
                  funcUuid,
                  depUuid,
                );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Rollback initiated successfully'),
                ),
              );
            }
            ref.invalidate(functionDeploymentsProvider(funcUuid));
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                ),
              );
            }
          }
        },
      ),
    );
  }
}

class _RollbackConfirmDialog extends StatefulWidget {
  final String funcUuid;
  final String depUuid;
  final VoidCallback onConfirm;

  const _RollbackConfirmDialog({
    required this.funcUuid,
    required this.depUuid,
    required this.onConfirm,
  });

  @override
  State<_RollbackConfirmDialog> createState() => _RollbackConfirmDialogState();
}

class _RollbackConfirmDialogState extends State<_RollbackConfirmDialog> {
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
      title: const Text('Confirm Rollback'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          const Text(
            'This action will rollback the function to the selected deployment version. This is a destructive action.',
            style: TextStyle(
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
                      'Function UUID:',
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
                      'Deployment UUID:',
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
                      controller: _funcUuidController,
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
                      controller: _depUuidController,
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
