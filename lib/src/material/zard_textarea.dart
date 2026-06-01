import 'package:flutter/material.dart';

import 'zard_input.dart';

/// Multi-line variant of [ZardInput]. Same API; defaults to `minLines: 3`,
/// `maxLines: null` so the field grows with content.
class ZardTextarea extends StatelessWidget {
  const ZardTextarea({
    this.name,
    this.label,
    this.placeholder,
    this.helperText,
    this.minLines = 3,
    this.maxLines,
    this.maxLength,
    this.decoration,
    this.style,
    this.padding,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.errorBuilder,
    super.key,
  });

  final String? name;
  final String? label;
  final String? placeholder;
  final String? helperText;
  final int? minLines;
  final int? maxLines;
  final int? maxLength;
  final InputDecoration? decoration;
  final TextStyle? style;
  final EdgeInsetsGeometry? padding;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final Widget Function(BuildContext, String?)? errorBuilder;

  @override
  Widget build(BuildContext context) => ZardInput(
        name: name,
        label: label,
        placeholder: placeholder,
        helperText: helperText,
        minLines: minLines,
        maxLines: maxLines ?? 8,
        maxLength: maxLength,
        decoration: decoration,
        style: style,
        padding: padding,
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        errorBuilder: errorBuilder,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
      );
}
