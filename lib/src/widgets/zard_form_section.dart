import 'package:flutter/widgets.dart';

/// Presentational grouping with an optional title and description.
class ZardFormSection extends StatelessWidget {
  const ZardFormSection({
    required this.child,
    this.title,
    this.description,
    this.titleStyle,
    this.descriptionStyle,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
    this.spacing = 12,
    super.key,
  });

  final String? title;
  final String? description;
  final TextStyle? titleStyle;
  final TextStyle? descriptionStyle;
  final EdgeInsetsGeometry padding;
  final double spacing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final defaults = DefaultTextStyle.of(context).style;
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Text(
              title!,
              style: defaults.merge(titleStyle ??
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
          if (description != null) ...[
            const SizedBox(height: 2),
            Text(
              description!,
              style: defaults.merge(descriptionStyle ??
                  const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            ),
          ],
          SizedBox(height: spacing),
          child,
        ],
      ),
    );
  }
}
