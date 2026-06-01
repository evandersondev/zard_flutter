import 'package:flutter_hooks/flutter_hooks.dart';

import '../core/field_controller.dart';
import '../core/field_state.dart';
import '../core/form_controller.dart';
import '../core/form_scope.dart';

/// Registers (or resolves) a [ZardFieldController] for [name] against the
/// nearest [ZardForm]. Subscribes to the field's state so the calling hook
/// widget rebuilds whenever the field's value/error/touched/etc. changes.
ZardFieldController<T> useController<T>(
  String name, {
  T? defaultValue,
  bool disabled = false,
  ZardFormController? form,
}) {
  final context = useContext();
  final resolved = form ?? ZardFormScope.of(context);
  final controller = useMemoized(
    () => resolved.register<T>(name, defaultValue: defaultValue, disabled: disabled),
    [resolved, name],
  );
  useValueListenable(controller.state);
  return controller;
}

/// Convenience: returns just the current [ZardFieldState] for [name].
ZardFieldState<T> useFieldState<T>(String name, {ZardFormController? form}) {
  final controller = useController<T>(name, form: form);
  return controller.currentState;
}
