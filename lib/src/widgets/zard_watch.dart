import 'package:flutter/widgets.dart';

import '../core/field_state.dart';
import '../core/form_controller.dart';
import '../core/form_scope.dart';

/// Rebuilds whenever the value of [name] changes. Subscribes only to that
/// field's [ValueListenable] — other field changes do not trigger a rebuild.
class ZardWatch<T> extends StatefulWidget {
  const ZardWatch({
    required this.name,
    required this.builder,
    super.key,
  });

  final String name;
  final Widget Function(BuildContext context, T? value) builder;

  @override
  State<ZardWatch<T>> createState() => _ZardWatchState<T>();
}

class _ZardWatchState<T> extends State<ZardWatch<T>> {
  ZardFormController? _form;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _form = ZardFormScope.maybeOf(context);
  }

  @override
  Widget build(BuildContext context) {
    final form = _form;
    if (form == null) return const SizedBox.shrink();
    // Register the field implicitly so users can ZardWatch without an
    // enclosing ZardField. If a ZardField already registered it, this is
    // a no-op (returns the existing controller).
    final field = form.register<T>(widget.name);
    return ValueListenableBuilder<ZardFieldState<T>>(
      valueListenable: field.state,
      builder: (ctx, state, _) => widget.builder(ctx, state.value),
    );
  }
}

/// Rebuilds on any form-level change. Use this sparingly — prefer the
/// scoped [ZardWatch] when you only care about a single field.
class ZardWatchAll extends StatelessWidget {
  const ZardWatchAll({required this.builder, super.key});

  final Widget Function(BuildContext context, Map<String, dynamic> values)
      builder;

  @override
  Widget build(BuildContext context) {
    final form = ZardFormScope.of(context);
    return AnimatedBuilder(
      animation: form,
      builder: (ctx, _) => builder(ctx, form.values),
    );
  }
}
