import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show BuildContext, Column, FontWeight, StatelessWidget, Text, Widget, Align;
import 'package:forui/forui.dart';

class HeaderWithAction extends StatelessWidget {
  const HeaderWithAction({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.subTitle,
    this.prefix,
    this.hideAction = false,
  }) : assert(
         (title != null) ^ (titleWidget != null),
         'Either title or titleWidget must be provided, but not both.',
       );

  final bool hideAction;
  final String? title;
  final Widget? titleWidget;
  final Widget? prefix;
  final List<Widget>? actions;
  final Widget? subTitle;
  @override
  Widget build(BuildContext context) {
    return FHeader(
      style: (style) => style.copyWith(
        actionStyle: (style) => style.copyWith(
          tappableStyle: (style) => style.copyWith(
            cursor: FWidgetStateMap.all(SystemMouseCursors.click),
          ),
        ),
      ),
      title: Row(
        spacing: 12,
        children: [
          ?prefix,
          Expanded(
            child: Column(
              mainAxisSize: .min,
              crossAxisAlignment: .start,
              children: [
                Align(
                  alignment: .centerLeft,
                  child:
                      titleWidget ??
                      Text(
                        title!,
                        style: context.theme.typography.base.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                ),
                ?subTitle,
              ],
            ),
          ),
        ],
      ),
      suffixes: [
        if (!hideAction && actions != null) ...[
          ...?actions,
        ],
      ],
    );
  }
}
