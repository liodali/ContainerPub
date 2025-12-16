import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:auto_route/auto_route.dart';
import '../../providers/functions_provider.dart';
import '../../providers/api_client_provider.dart';
import '../../router.dart';

@RoutePage()
class FunctionsView extends ConsumerStatefulWidget {
  const FunctionsView({super.key});

  @override
  ConsumerState<FunctionsView> createState() => _FunctionsViewState();
}

class _FunctionsViewState extends ConsumerState<FunctionsView> {
  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: const CreateFunctionCard(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final functionsAsync = ref.watch(functionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Functions',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            FButton(
              onPress: () => _showCreateDialog(context),
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
        ),
        const SizedBox(height: 24),
        Expanded(
          child: functionsAsync.when(
            data: (functions) {
              if (functions.isEmpty) {
                return FunctionsEmptyWidget(
                  openCreateDialog: _showCreateDialog,
                );
              }
              return ListView.separated(
                itemCount: functions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final func = functions[index];
                  return FTappable(
                    onPress: () {
                      context.router.push(
                        FunctionDetailsRoute(uuid: func.uuid, name: func.name),
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
            error: (err, stack) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Error: $err'),
                  const SizedBox(height: 16),
                  FButton(
                    onPress: () => ref.refresh(functionsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CreateFunctionCard extends ConsumerStatefulWidget {
  const CreateFunctionCard({super.key});

  @override
  ConsumerState<CreateFunctionCard> createState() => _CreateFunctionCardState();
}

class _CreateFunctionCardState extends ConsumerState<CreateFunctionCard> {
  final _nameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _create() async {
    if (_nameController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final client = ref.read(apiClientProvider);
      await client.createFunction(_nameController.text);
      ref.invalidate(functionsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        // Since we are in a dialog, snackbar might show behind or on parent scaffold.
        // It should work.
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
    return FCard(
      title: const Text('Create Function'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FTextField(
            controller: _nameController,
            label: const Text('Function Name'),
            hint: 'my-function',
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FButton(
                onPress: _isLoading ? null : _create,
                child: _isLoading
                    ? const Text('Creating...')
                    : const Text('Create'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FunctionsEmptyWidget extends StatelessWidget {
  const FunctionsEmptyWidget({
    super.key,
    required this.openCreateDialog,
  });

  final Function(BuildContext) openCreateDialog;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.code, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No functions found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first function to get started',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          FButton(
            onPress: () => openCreateDialog(context),
            child: const Text('Create Function'),
          ),
        ],
      ),
    );
  }
}
