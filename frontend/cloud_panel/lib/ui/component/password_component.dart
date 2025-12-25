import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

class PasswordComponent extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final Widget? suffix;
  final Widget? prefix;
  const PasswordComponent({
    required this.controller,
    required this.hint,
    this.suffix,
    this.prefix,
    super.key,
  });

  @override
  State<PasswordComponent> createState() => _PasswordComponentState();
}

class _PasswordComponentState extends State<PasswordComponent> {
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    return FTextField(
      control: .managed(controller: widget.controller),
      obscureText: !_showPassword,
      hint: widget.hint,
      autofocus: true,
      suffixBuilder: (context, style, states) =>
          widget.suffix ??
          FTappable(
            onPress: () => setState(() => _showPassword = !_showPassword),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                _showPassword ? FIcons.eye : FIcons.eyeOff,
                color: context.theme.colors.foreground,
              ),
            ),
          ),
      prefixBuilder: widget.prefix != null
          ? (context, style, states) => widget.prefix!
          : null,
    );
  }
}
