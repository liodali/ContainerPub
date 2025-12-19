import 'package:cloud_panel/common/commons.dart';
import 'package:cloud_panel/providers/function_details_provider.dart';
import 'package:cloud_panel/ui/component/header_with_action.dart';
import 'package:cloud_panel/ui/widgets/overview_function_tab.dart';
import 'package:cloud_panel/ui/widgets/deployments_tab.dart';
import 'package:cloud_panel/ui/widgets/api_keys_tab.dart';
import 'package:cloud_panel/ui/widgets/invoke_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

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
  late final FTabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = FTabController(length: 4, vsync: this, initialIndex: 0);
  }

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
        actions: [
          FTappable(
            onPress: () {
              switch (_tabController.index) {
                case 0:
                  ref.invalidate(functionStatsProvider(widget.uuid));
                  break;
                case 1:
                  ref.invalidate(functionDeploymentsProvider(widget.uuid));
                  break;
                case 2:
                  ref.invalidate(functionApiKeysProvider(widget.uuid));
                  break;
                case 3:
                  break;
              }
            },
            child: const Icon(FIcons.refreshCcw),
          ),
        ],
      ),
      child: funcAsync.when(
        data: (func) => SizedBox(
          height: MediaQuery.sizeOf(context).height,
          child: FTabs(
            controller: _tabController,
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
                child: ApiKeysTab(uuid: func.uuid),
              ),
              FTabEntry(
                label: Text('Invoke'),
                child: InvokeTab(uuid: func.uuid),
              ),
            ],
          ),
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
