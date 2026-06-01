import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/field_controller.dart';
import '../core/field_state.dart';
import '../core/form_scope.dart';
import '../widgets/zard_field.dart';

/// A Material text input wired to a [ZardFieldController]. Exposes every
/// relevant [TextField]/[InputDecoration] knob so styling is not hidden.
///
/// Resolves the field from the surrounding [ZardField] when possible; pass
/// [name] to bind to a different path explicitly.
class ZardInput extends StatelessWidget {
  const ZardInput({
    this.name,
    this.label,
    this.placeholder,
    this.helperText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.autocorrect = true,
    this.autofocus = false,
    this.readOnly = false,
    this.decoration,
    this.style,
    this.padding,
    this.prefixIcon,
    this.suffixIcon,
    this.prefix,
    this.suffix,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.loadingBuilder,
    this.errorBuilder,
    super.key,
  });

  final String? name;
  final String? label;
  final String? placeholder;
  final String? helperText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int? maxLength;
  final int? maxLines;
  final int? minLines;
  final bool autocorrect;
  final bool autofocus;
  final bool readOnly;
  final InputDecoration? decoration;
  final TextStyle? style;
  final EdgeInsetsGeometry? padding;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Widget? prefix;
  final Widget? suffix;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;

  /// Custom widget shown in the suffix position while async validation runs.
  /// Defaults to a small circular progress indicator.
  final Widget Function(BuildContext context)? loadingBuilder;

  /// Custom rendering for error text. Falls back to Flutter's default.
  final Widget Function(BuildContext context, String? error)? errorBuilder;

  ZardFieldController<String>? _resolve(BuildContext context) {
    if (name != null) {
      final form = ZardFormScope.maybeOf(context);
      if (form == null) return null;
      return form.register<String>(name!);
    }
    final ctrl = ZardFieldBinding.maybeOf(context);
    return ctrl is ZardFieldController<String> ? ctrl : null;
  }

  @override
  Widget build(BuildContext context) {
    final field = _resolve(context);
    assert(field != null,
        'ZardInput could not resolve a field — wrap in ZardField or pass name:.');
    final ctrl = controller ?? field!.textController;
    final focus = focusNode ?? field!.focusNode;
    return ValueListenableBuilder<ZardFieldState<String>>(
      valueListenable: field!.state,
      builder: (ctx, state, _) {
        final base = decoration ?? const InputDecoration();
        final showLoader = state.isValidating;
        final effectiveSuffixIcon = showLoader
            ? (loadingBuilder?.call(ctx) ??
                const SizedBox(
                  height: 16,
                  width: 16,
                  child: Padding(
                    padding: EdgeInsets.all(2),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ))
            : suffixIcon;
        final effectiveDecoration = base.copyWith(
          labelText: base.labelText ?? label,
          hintText: base.hintText ?? placeholder,
          helperText: base.helperText ?? helperText,
          errorText: errorBuilder == null ? state.error : null,
          prefixIcon: base.prefixIcon ?? prefixIcon,
          suffixIcon: base.suffixIcon ?? effectiveSuffixIcon,
          prefix: base.prefix ?? prefix,
          suffix: base.suffix ?? suffix,
          enabled: !state.disabled,
          contentPadding: base.contentPadding ?? padding,
        );
        final input = TextField(
          controller: ctrl,
          focusNode: focus,
          enabled: !state.disabled,
          readOnly: readOnly,
          obscureText: obscureText,
          autocorrect: autocorrect,
          autofocus: autofocus,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          maxLength: maxLength,
          maxLines: maxLines,
          minLines: minLines,
          style: style,
          decoration: effectiveDecoration,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          inputFormatters: inputFormatters,
        );
        if (errorBuilder == null) return input;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [input, errorBuilder!(ctx, state.error)],
        );
      },
    );
  }
}
