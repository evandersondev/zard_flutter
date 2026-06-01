import 'package:flutter_hooks/flutter_hooks.dart';

import '../core/form_controller.dart';
import '../core/form_scope.dart';

/// Reactive read of a single field's value. Subscribes only to that field's
/// [ValueListenable] — other field changes do not trigger a rebuild here.
T? useWatch<T>(String name, {ZardFormController? form, T? defaultValue}) {
  final context = useContext();
  final resolved = form ?? ZardFormScope.of(context);
  final controller = useMemoized(
    () => resolved.register<T>(name, defaultValue: defaultValue),
    [resolved, name],
  );
  final state = useValueListenable(controller.state);
  return state.value;
}
