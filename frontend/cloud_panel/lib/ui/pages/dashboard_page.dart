import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:cloud_api_client/cloud_api_client.dart';
import '../../providers/functions_provider.dart';
import '../../providers/api_client_provider.dart';
import '../../providers/auth_provider.dart';
import 'function_details_page.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final functionsAsync = ref.watch(functionsProvider);

    return FScaffold(
      // Replacing FHeader with a custom Row in the body or standard AppBar if FScaffold supports it.
      // Assuming FScaffold.child is the body.
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Functions',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    FButton(
                      onPress: () => _showCreateDialog(context, ref),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 16),
                          SizedBox(width: 8),
                          Text('Create'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FButton(
                      // style: FButtonStyle.outline, // Removed to avoid error
                      onPress: () => ref.read(authProvider.notifier).logout(),
                      child: const Icon(Icons.logout, size: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: functionsAsync.when(
              data: (functions) {
                if (functions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('No functions found'),
                        const SizedBox(height: 16),
                        FButton(
                          onPress: () => _showCreateDialog(context, ref),
                          child: const Text('Create your first function'),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: functions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final func = functions[index];
                    return FTappable(
                      onPress: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                FunctionDetailsPage(uuid: func.uuid),
                          ),
                        );
                      },
                      child: FCard(
                        title: Text(func.name),
                        subtitle: Text(
                          'Status: ${func.status} • UUID: ${func.uuid}',
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const CreateFunctionDialog(),
    );
  }
}

class CreateFunctionDialog extends ConsumerStatefulWidget {
  const CreateFunctionDialog({super.key});

  @override
  ConsumerState<CreateFunctionDialog> createState() =>
      _CreateFunctionDialogState();
}

class _CreateFunctionDialogState extends ConsumerState<CreateFunctionDialog> {
  final _nameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _create() async {
    if (_nameController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final client = ref.read(apiClientProvider);
      await client.createFunction(_nameController.text);
      ref.invalidate(functionsProvider); // Refresh list
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Function'),
      content: FTextField(
        controller: _nameController,
        label: const Text('Function Name'),
        hint: 'my-function',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FButton(
          onPress: _isLoading ? null : _create,
          child: _isLoading ? const Text('Creating...') : const Text('Create'),
        ),
      ],
    );
  }
}
