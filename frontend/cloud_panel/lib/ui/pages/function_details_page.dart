import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:cloud_api_client/cloud_api_client.dart';
import 'package:flutter/services.dart';
import '../../providers/function_details_provider.dart';
import '../../providers/api_client_provider.dart';

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
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final funcAsync = ref.watch(functionDetailsProvider(widget.uuid));

    return FScaffold(
      child: Column(
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Function Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                FButton(
                  // style: FButtonStyle.outline,
                  onPress: () =>
                      ref.refresh(functionDetailsProvider(widget.uuid)),
                  child: const Icon(Icons.refresh, size: 16),
                ),
              ],
            ),
          ),
          Expanded(
            child: funcAsync.when(
              data: (func) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          func.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText('UUID: ${func.uuid}'),
                        const SizedBox(height: 4),
                        Text('Status: ${func.status}'),
                        if (func.endpoint != null) ...[
                          const SizedBox(height: 4),
                          SelectableText('Endpoint: ${func.endpoint}'),
                        ],
                      ],
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Deployments'),
                      Tab(text: 'API Keys'),
                      Tab(text: 'Invoke'),
                    ],
                    labelColor: Colors.black,
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _OverviewTab(func: func),
                        _DeploymentsTab(uuid: func.uuid),
                        _ApiKeysTab(uuid: func.uuid),
                        _InvokeTab(uuid: func.uuid),
                      ],
                    ),
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final CloudFunction func;
  const _OverviewTab({required this.func});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Function ${func.name} is ${func.status}'));
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
        if (deployments.isEmpty)
          return const Center(child: Text('No deployments'));
        return ListView.separated(
          itemCount: deployments.length,
          padding: const EdgeInsets.all(16),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final dep = deployments[index];
            return FCard(
              title: Text('Version ${dep.version}'),
              subtitle: Text('${dep.status} • ${dep.createdAt}'),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FButton(
                    // style: FButtonStyle.secondary,
                    onPress: () => _rollback(context, ref, uuid, dep.uuid),
                    child: const Text('Rollback'),
                  ),
                ],
              ),
            );
          },
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
    try {
      await ref.read(apiClientProvider).rollbackFunction(funcUuid, depUuid);
      if (context.mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Rollback initiated')));
      ref.refresh(functionDeploymentsProvider(funcUuid));
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
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
                separatorBuilder: (_, __) => const SizedBox(height: 12),
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
              children: [
                const Text(
                  'Please copy your secret key. It will not be shown again.',
                ),
                const SizedBox(height: 10),
                SelectableText(
                  result.secretKey,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
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
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
      ref.refresh(functionApiKeysProvider(uuid));
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _revokeKey(
    BuildContext context,
    WidgetRef ref,
    String keyUuid,
  ) async {
    try {
      await ref.read(apiClientProvider).revokeApiKey(keyUuid);
      ref.refresh(functionApiKeysProvider(uuid));
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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

      final result = await client.invokeFunction(
        widget.uuid,
        body: body,
        secretKey: _secretController.text.isNotEmpty
            ? _secretController.text
            : null,
      );

      setState(() {
        _response = result.toString();
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
        children: [
          const Text(
            'Request Body (JSON)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          FTextField(
            controller: _bodyController,
            maxLines: 5,
            hint: '{"key": "value"}',
          ),
          const SizedBox(height: 16),
          const Text(
            'Secret Key (Optional - for signed requests)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          FTextField(
            controller: _secretController,
            obscureText: true,
            hint: 'Enter function secret key',
          ),
          const SizedBox(height: 16),
          FButton(
            onPress: _isLoading ? null : _invoke,
            child: _isLoading
                ? const Text('Invoking...')
                : const Text('Invoke Function'),
          ),
          const SizedBox(height: 24),
          if (_response != null) ...[
            const Text(
              'Response:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isError
                    ? Colors.red.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
                border: Border.all(color: _isError ? Colors.red : Colors.green),
                borderRadius: BorderRadius.circular(4),
              ),
              child: SelectableText(_response!),
            ),
          ],
        ],
      ),
    );
  }
}
