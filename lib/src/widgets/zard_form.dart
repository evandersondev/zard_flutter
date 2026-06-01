import 'package:flutter/widgets.dart';
import 'package:zard/zard.dart';

import '../core/form_controller.dart';
import '../core/form_scope.dart';
import '../core/validation_mode.dart';

/// Owns or wraps a [ZardFormController] and exposes it to descendants via
/// [ZardFormScope].
///
/// Two construction modes:
///
/// 1. **External controller** — supply [form]. Lifecycle is yours.
/// 2. **Inline schema** — supply [schema] (and optionally [defaultValues],
///    [mode], etc.). The widget creates a controller on first build and
///    disposes it on unmount.
///
/// Children can either consume the controller via `ZardFormScope.of(context)`
/// or via the [builder] callback, which receives `(context, form)`.
class ZardForm extends StatefulWidget {
  const ZardForm({
    required this.child,
    this.form,
    this.schema,
    this.defaultValues = const {},
    this.mode = ValidationMode.onSubmit,
    this.revalidateMode = RevalidateMode.onChange,
    this.debounce = Duration.zero,
    this.disabled = false,
    this.asyncValidation = false,
    this.excludeDisabledFromValues = false,
    super.key,
  })  : builder = null,
        assert(form != null || schema != null,
            'ZardForm requires either form: or schema:');

  const ZardForm.builder({
    required this.builder,
    this.form,
    this.schema,
    this.defaultValues = const {},
    this.mode = ValidationMode.onSubmit,
    this.revalidateMode = RevalidateMode.onChange,
    this.debounce = Duration.zero,
    this.disabled = false,
    this.asyncValidation = false,
    this.excludeDisabledFromValues = false,
    super.key,
  })  : child = const SizedBox.shrink(),
        assert(form != null || schema != null,
            'ZardForm requires either form: or schema:');

  final ZardFormController? form;
  final ZMap? schema;
  final Map<String, dynamic> defaultValues;
  final ValidationMode mode;
  final RevalidateMode revalidateMode;
  final Duration debounce;
  final bool disabled;
  final bool asyncValidation;
  final bool excludeDisabledFromValues;
  final Widget child;
  final Widget Function(BuildContext context, ZardFormController form)? builder;

  @override
  State<ZardForm> createState() => _ZardFormState();
}

class _ZardFormState extends State<ZardForm> {
  ZardFormController? _owned;

  ZardFormController get _controller => widget.form ?? _owned!;

  @override
  void initState() {
    super.initState();
    if (widget.form == null) {
      _owned = ZardFormController(
        schema: widget.schema!,
        defaultValues: widget.defaultValues,
        mode: widget.mode,
        revalidateMode: widget.revalidateMode,
        debounce: widget.debounce,
        disabled: widget.disabled,
        asyncValidation: widget.asyncValidation,
        excludeDisabledFromValues: widget.excludeDisabledFromValues,
      );
    }
  }

  @override
  void didUpdateWidget(covariant ZardForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.disabled != widget.disabled) {
      widget.disabled ? _controller.disable() : _controller.enable();
    }
  }

  @override
  void dispose() {
    _owned?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.builder != null
        ? Builder(builder: (ctx) => widget.builder!(ctx, _controller))
        : widget.child;
    return ZardFormScope(controller: _controller, child: child);
  }
}
