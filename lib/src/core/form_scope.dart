import 'package:flutter/widgets.dart';

import 'form_controller.dart';

/// Provides a [ZardFormController] to descendants via [InheritedNotifier].
///
/// Subscribers (via `ZardFormScope.of(context)`) rebuild on form-level
/// notifications. Field widgets should resolve the controller once via
/// [maybeOf] and then subscribe to the per-field [ValueListenable] instead
/// — that keeps per-keystroke rebuilds scoped to the affected field's
/// subtree.
class ZardFormScope extends InheritedNotifier<ZardFormController> {
  const ZardFormScope({
    required ZardFormController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static ZardFormController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ZardFormScope>();
    assert(scope != null, 'No ZardFormScope found in context. Wrap with ZardForm.');
    return scope!.notifier!;
  }

  static ZardFormController? maybeOf(BuildContext context, {bool listen = false}) {
    if (listen) {
      return context.dependOnInheritedWidgetOfExactType<ZardFormScope>()?.notifier;
    }
    final el = context.getElementForInheritedWidgetOfExactType<ZardFormScope>();
    return (el?.widget as ZardFormScope?)?.notifier;
  }
}
