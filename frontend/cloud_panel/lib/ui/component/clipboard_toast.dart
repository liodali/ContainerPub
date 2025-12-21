import 'package:cloud_panel/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

void showClipboardToast(
  BuildContext context,
  String text, {
  FToastAlignment alignment = .bottomCenter,
}) {
  showFToast(
    context: context,
    alignment: alignment,
    title: Text(text),
    suffixBuilder:
        (
          context,
          entry,
        ) => IntrinsicHeight(
          child: FButton(
            style: context.theme.buttonStyles.primary
                .copyWith(
                  contentStyle: context.theme.buttonStyles.primary.contentStyle
                      .copyWith(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7.5,
                        ),
                        textStyle: FWidgetStateMap.all(
                          context.theme.typography.xs.copyWith(
                            color: context.theme.colors.primaryForeground,
                          ),
                        ),
                      )
                      .call,
                )
                .call,
            onPress: entry.dismiss,
            child: Text(AppLocalizations.of(context)!.undo),
          ),
        ),
  );
}
