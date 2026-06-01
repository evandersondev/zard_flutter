import 'package:flutter/widgets.dart';

import '../core/field_state.dart';
import '../core/form_scope.dart';
import 'zard_field.dart';

/// Headless error message. By default resolves the surrounding [ZardField]
/// and shows its first error. Pass [name] to bind to a different field, or
/// omit and rely on the inherited [ZardField].
class ZardErrorMessage extends StatelessWidget {
  const ZardErrorMessage({
    this.name,
    this.style,
    this.padding = const EdgeInsets.only(top: 4),
    this.builder,
    super.key,
  });

  final String? name;
  final TextStyle? style;
  final EdgeInsetsGeometry padding;

  /// Custom rendering. Receives the list of error messages (possibly empty).
  /// When null, renders the first error as a `Text` (red).
  final Widget Function(BuildContext context, List<String> errors)? builder;

  @override
  Widget build(BuildContext context) {
    final field = name == null
        ? ZardFieldBinding.maybeOf(context)
        : ZardFormScope.maybeOf(context)?.field(name!);
    if (field == null) return const SizedBox.shrink();
    return ValueListenableBuilder<ZardFieldState>(
      valueListenable: field.state,
      builder: (ctx, state, _) {
        if (state.errors.isEmpty) return const SizedBox.shrink();
        if (builder != null) return builder!(ctx, state.errors);
        return Padding(
          padding: padding,
          child: Text(
            state.errors.first,
            style: DefaultTextStyle.of(ctx).style.merge(
                  (style ?? const TextStyle()).copyWith(
                    color: style?.color ?? const Color(0xFFB91C1C),
                    fontSize: style?.fontSize ?? 12,
                  ),
                ),
          ),
        );
      },
    );
  }
}
