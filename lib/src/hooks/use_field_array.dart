import 'package:flutter_hooks/flutter_hooks.dart';

import '../core/field_array.dart';
import '../core/form_controller.dart';
import '../core/form_scope.dart';

/// Hook variant of [ZardFormController.useFieldArray]. Subscribes to the
/// array's rows so reorders/insertions trigger a rebuild.
ZardFieldArray<E> useFieldArray<E>(String name, {ZardFormController? form}) {
  final context = useContext();
  final resolved = form ?? ZardFormScope.of(context);
  final array = useMemoized(
    () => resolved.useFieldArray<E>(name),
    [resolved, name],
  );
  useValueListenable(array.rows);
  return array;
}
