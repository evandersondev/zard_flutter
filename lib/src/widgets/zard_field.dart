import 'package:flutter/widgets.dart';

import '../core/field_controller.dart';
import '../core/field_state.dart';
import '../core/form_controller.dart';
import '../core/form_scope.dart';

/// Signature for the `builder:` form of [ZardField].
typedef ZardFieldBuilder<T> = Widget Function(
  BuildContext context,
  ZardFieldController<T> field,
  ZardFieldState<T> state,
);

/// Headless field binder. Registers a [ZardFieldController] for the given
/// [name] against the nearest [ZardFormScope] and exposes it to descendants
/// via a non-generic [ZardFieldBinding] so headless widgets like [ZardLabel]
/// and [ZardErrorMessage] can resolve it without knowing the field's type.
class ZardField<T> extends StatefulWidget {
  const ZardField({
    required this.name,
    required Widget this.child,
    this.defaultValue,
    this.disabled = false,
    super.key,
  }) : builder = null;

  const ZardField.builder({
    required this.name,
    required ZardFieldBuilder<T> this.builder,
    this.defaultValue,
    this.disabled = false,
    super.key,
  }) : child = null;

  final String name;
  final T? defaultValue;
  final bool disabled;
  final Widget? child;
  final ZardFieldBuilder<T>? builder;

  @override
  State<ZardField<T>> createState() => _ZardFieldState<T>();
}

class _ZardFieldState<T> extends State<ZardField<T>> {
  ZardFieldController<T>? _controller;
  ZardFormController? _form;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final form = ZardFormScope.maybeOf(context);
    assert(form != null,
        'ZardField("${widget.name}") needs a ZardFormScope (use ZardForm).');
    if (form != _form) {
      _form = form;
      _controller = form!.register<T>(
        widget.name,
        defaultValue: widget.defaultValue,
        disabled: widget.disabled,
      );
    }
  }

  @override
  void didUpdateWidget(covariant ZardField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When this element is reused at the same tree position with a different
    // [name] (e.g. a step wizard that swaps which field renders here), rebind
    // to the new field's controller. Without this, the widget keeps pointing
    // at the previous field and reads/writes the wrong path.
    if (oldWidget.name != widget.name) {
      final form = _form;
      if (form != null) {
        _controller = form.register<T>(
          widget.name,
          defaultValue: widget.defaultValue,
          disabled: widget.disabled,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _controller!;
    final inner = widget.builder != null
        ? ValueListenableBuilder<ZardFieldState<T>>(
            valueListenable: ctrl.state,
            builder: (ctx, state, _) => widget.builder!(ctx, ctrl, state),
          )
        : widget.child!;
    return ZardFieldBinding(controller: ctrl, child: inner);
  }
}

/// Inherited binding inserted by [ZardField] so descendants can resolve the
/// field controller without depending on its generic type argument.
///
/// Use [ZardFieldBinding.of] / [ZardFieldBinding.maybeOf] to access it.
class ZardFieldBinding extends InheritedWidget {
  const ZardFieldBinding({
    required this.controller,
    required super.child,
    super.key,
  });

  final ZardFieldController controller;

  static ZardFieldController of(BuildContext context) {
    final result = maybeOf(context);
    assert(result != null,
        'No ZardFieldBinding found. Place this widget inside a ZardField.');
    return result!;
  }

  static ZardFieldController? maybeOf(BuildContext context) {
    final el =
        context.getElementForInheritedWidgetOfExactType<ZardFieldBinding>();
    return (el?.widget as ZardFieldBinding?)?.controller;
  }

  @override
  bool updateShouldNotify(covariant ZardFieldBinding old) =>
      old.controller != controller;
}
