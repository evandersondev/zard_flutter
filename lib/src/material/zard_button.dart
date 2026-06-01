import 'package:flutter/material.dart';

/// Primary submit-style button with a built-in loading state.
///
/// Pair with `form.handleSubmit(onValid: ...)` for a one-liner submit:
///
/// ```dart
/// ZardButton(
///   loading: form.isSubmitting,
///   onPressed: form.handleSubmit(onValid: (data) async { ... }),
///   child: Text('Sign in'),
/// );
/// ```
class ZardButton extends StatelessWidget {
  const ZardButton({
    required this.onPressed,
    required this.child,
    this.loading = false,
    this.style,
    this.icon,
    this.fullWidth = false,
    super.key,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool loading;
  final ButtonStyle? style;
  final Widget? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final inner = loading
        ? const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : (icon == null
            ? child
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [icon!, const SizedBox(width: 6), child],
              ));
    final button = ElevatedButton(
      style: style,
      onPressed: loading ? null : onPressed,
      child: inner,
    );
    return fullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}
