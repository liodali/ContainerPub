import 'package:cloud_panel/common/commons.dart' show FunctionStatusExtension;
import 'package:cloud_panel/providers/api_client_provider.dart';
import 'package:cloud_panel/providers/functions_provider.dart';
import 'package:cloud_panel/router.dart';
import 'package:cloud_panel/ui/component/clipboard_toast.dart'
    show showClipboardToast;
import 'package:cloud_panel/ui/component/header_with_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:auto_route/auto_route.dart';

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
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: const CreateFunctionCard(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final functionsAsync = ref.watch(functionsProvider);

    return FScaffold(
      header: HeaderWithAction(
        title: 'Functions',
        actions: [
          FButton(
            onPress: () => _showCreateDialog(context),
            prefix: Icon(Icons.add, size: 16),
            child: Text('Create'),
          ),
        ],
        hideAction:
            functionsAsync.hasValue && functionsAsync.value?.isEmpty == true,
      ),
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
                    FunctionDetailsRoute(
                      uuid: func.uuid,
                      name: func.name,
                    ),
                  );
                },
                child: FCard(
                  title: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: .min,
                    children: [
                      SelectableText(
                        func.name,
                        style: context.theme.typography.lg.copyWith(
                          fontSize: 20,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: func.statusWidget,
                      ),
                    ],
                  ),
                  subtitle: SelectableText(
                    func.uuid,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: func.uuid));
                      showClipboardToast(
                        context,
                        '${func.uuid} Copied to Clipboard',
                      );
                    },
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
        loading: () => const Center(child: FCircularProgress()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Opps!Error to Load Functions'),
              const SizedBox(height: 16),
              FButton(
                onPress: () => ref.refresh(functionsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
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
        ).showSnackBar(
          SnackBar(
            content: Text('Opps!Error to Create Function'),
          ),
        );
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
              FButton.raw(
                onPress: () => Navigator.of(context).pop(),
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
          const Icon(
            Icons.code,
            size: 48,
            color: Colors.grey,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: const Text(
              'No functions found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Text(
            'Create your first function to get started',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          FButton(
            onPress: () => openCreateDialog(context),
            style: FButtonStyle.primary(),
            mainAxisSize: MainAxisSize.min,
            child: const Text('Create Function'),
          ),
        ],
      ),
    );
  }
}
