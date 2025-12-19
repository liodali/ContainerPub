import 'package:cloud_api_client/cloud_api_client.dart';
import 'package:cloud_panel/common/commons.dart';
import 'package:cloud_panel/providers/api_client_provider.dart';
import 'package:cloud_panel/providers/function_details_provider.dart';
import 'package:cloud_panel/ui/widgets/filter_deployement_widget.dart';
import 'package:cloud_panel/ui/widgets/rollback_confirm_dialog.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

class DeploymentsTab extends ConsumerStatefulWidget {
  final String uuid;
  const DeploymentsTab({required this.uuid, super.key});

  @override
  ConsumerState<DeploymentsTab> createState() => _DeploymentsTabState();
}

class _DeploymentsTabState extends ConsumerState<DeploymentsTab> {
  late final ValueNotifier<String> sortByNotifier = ValueNotifier(
    'version_desc',
  );

  List<FunctionDeployment> _sortDeployments(
    List<FunctionDeployment> deployments,
  ) {
    final sorted = List<FunctionDeployment>.from(deployments);
    switch (sortByNotifier.value) {
      case 'version_asc':
        sorted.sort((a, b) => a.version.compareTo(b.version));
        break;
      case 'version_desc':
        sorted.sort((a, b) => b.version.compareTo(a.version));
        break;
      case 'date_asc':
        sorted.sort(
          (a, b) => a.createdAt.compareTo(b.createdAt),
        );
        break;
      case 'date_desc':
        sorted.sort(
          (a, b) => (b.createdAt).compareTo(a.createdAt),
        );
        break;
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final deploymentsAsync = ref.watch(
      functionDeploymentsProvider(widget.uuid),
    );

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
        final sortedOtherDeployments = _sortDeployments(otherDeployments);

        return SizedBox(
          height: MediaQuery.sizeOf(context).height - 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      TitleSectionOtherDeployementWidget(
                        sortByNotifier: sortByNotifier,
                        onSortByChange: (value) {
                          sortByNotifier.value = value;
                        },
                      ),
                      Expanded(
                        child: ListView.separated(
                          itemCount: sortedOtherDeployments.length,
                          shrinkWrap: true,
                          separatorBuilder: (_, _) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final dep = sortedOtherDeployments[index];
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
                                    onPress: () => _rollback(
                                      context,
                                      ref,
                                      widget.uuid,
                                      dep.uuid,
                                    ),
                                    style: FButtonStyle.destructive(),
                                    child: const Text('Rollback'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: FCircularProgress()),
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
      builder: (context, style, animation) => RollbackConfirmDialog(
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
              showFToast(
                context: context,
                alignment: FToastAlignment.bottomCenter,
                title: Text('Rollback initiated successfully'),
              );
            }
            ref.invalidate(functionDeploymentsProvider(funcUuid));
          } catch (e) {
            if (context.mounted) {
              showFToast(
                context: context,
                alignment: FToastAlignment.bottomCenter,
                title: Text('Ops!Rollback failed'),
              );
            }
          }
        },
      ),
    );
  }
}
