import 'package:flutter/widgets.dart';

class ZardDescription extends StatelessWidget {
  const ZardDescription(
    this.text, {
    this.style,
    this.padding = const EdgeInsets.only(top: 4),
    super.key,
  });

  final String text;
  final TextStyle? style;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        text,
        style: DefaultTextStyle.of(context).style.merge(style),
      ),
    );
  }
}
