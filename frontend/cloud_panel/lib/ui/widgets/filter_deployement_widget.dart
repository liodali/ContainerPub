import 'package:cloud_panel/common/commons.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:cloud_panel/l10n/app_localizations.dart';

class TitleSectionOtherDeployementWidget extends StatelessWidget {
  final ValueNotifier<String> sortByNotifier;
  final Function(String) onSortByChange;
  const TitleSectionOtherDeployementWidget({
    required this.sortByNotifier,
    required this.onSortByChange,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppLocalizations.of(context)!.previousDeployments,
          style: context.theme.typography.sm.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Flexible(
          child: FilterOtherDeployementWidget(
            sortByNotifier: sortByNotifier,
            onSortByChange: onSortByChange,
          ),
        ),
      ],
    );
  }
}

class FilterOtherDeployementWidget extends StatelessWidget {
  final ValueNotifier<String> sortByNotifier;
  final Function(String) onSortByChange;
  const FilterOtherDeployementWidget({
    required this.sortByNotifier,
    required this.onSortByChange,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: sortByNotifier,
      builder: (context, value, child) {
        return SizedBox(
          width: 180,
          child: FSelect<String>(
            initialValue: value,
            onChange: (sortV) {
              if (sortV != null) {
                onSortByChange(sortV);
              }
            },
            builder: (context, style, state, child) => child,
            items: SortDeploy.values.fold(
              <String, String>{},
              (previousValue, element) => previousValue
                ..addAll({
                  element.localized(context): element.value,
                }),
            ),
          ),
        );
      },
    );
  }
}
