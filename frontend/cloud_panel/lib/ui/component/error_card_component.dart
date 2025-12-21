import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

class ErrorCardComponent extends StatelessWidget {
  const ErrorCardComponent({
    super.key,
    required String this.title,
    required String this.subtitle,
    this.titleStyle,
    this.subtitleStyle,
  }) : titleWidget = null,
       subtitleWidget = null;

  const ErrorCardComponent.raw({
    super.key,
    required Widget this.titleWidget,
    required Widget this.subtitleWidget,
  }) : title = null,
       subtitle = null,
       titleStyle = null,
       subtitleStyle = null;

  final String? title;
  final String? subtitle;

  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  final Widget? titleWidget;
  final Widget? subtitleWidget;

  @override
  Widget build(BuildContext context) {
    return FAlert(
      title:
          titleWidget ??
          Text(
            title!,
            style: titleStyle,
          ),
      subtitle:
          subtitleWidget ??
          Text(
            subtitle!,
            style: subtitleStyle,
          ),
      style: FAlertStyle.destructive(),
    );
  }
}
