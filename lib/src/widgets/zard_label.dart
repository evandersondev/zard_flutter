import 'package:flutter/widgets.dart';

import 'zard_field.dart';

/// Headless label that displays [text] and forwards taps to its associated
/// field's [FocusNode] (matching Radix's `Form.Label` behavior).
///
/// Place inside a [ZardField] so it resolves the field automatically — no
/// `name:` needed.
class ZardLabel extends StatelessWidget {
  const ZardLabel(
    this.text, {
    this.style,
    this.requiredMarker,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final String text;
  final TextStyle? style;

  /// Suffix shown after the label (e.g. ` *` for required fields). Provide
  /// any widget — common pattern is `Text(' *', style: TextStyle(color: ...))`.
  final Widget? requiredMarker;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final field = ZardFieldBinding.maybeOf(context);
    final inheritedStyle =
        DefaultTextStyle.of(context).style.merge(style);
    return Padding(
      padding: padding,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: field != null && field.hasFocusNode
            ? () => field.focusNode.requestFocus()
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: inheritedStyle),
            if (requiredMarker != null) requiredMarker!,
          ],
        ),
      ),
    );
  }
}
