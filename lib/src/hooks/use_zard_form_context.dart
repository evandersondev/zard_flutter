import 'package:flutter_hooks/flutter_hooks.dart';

import '../core/form_controller.dart';
import '../core/form_scope.dart';

/// Resolves the nearest [ZardFormController] from context. Throws if none is
/// found. Use inside a [HookWidget] descendant of [ZardForm].
ZardFormController useZardFormContext() {
  final context = useContext();
  return ZardFormScope.of(context);
}
