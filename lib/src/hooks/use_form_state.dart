import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../core/form_controller.dart';
import '../core/form_scope.dart';

@immutable
class ZardFormSnapshot {
  const ZardFormSnapshot({
    required this.isValid,
    required this.isDirty,
    required this.isTouched,
    required this.isSubmitting,
    required this.isValidating,
    required this.submitCount,
    required this.disabled,
    required this.formErrors,
  });

  final bool isValid;
  final bool isDirty;
  final bool isTouched;
  final bool isSubmitting;
  final bool isValidating;
  final int submitCount;
  final bool disabled;
  final List<String> formErrors;

  static ZardFormSnapshot from(ZardFormController f) => ZardFormSnapshot(
        isValid: f.isValid,
        isDirty: f.isDirty,
        isTouched: f.isTouched,
        isSubmitting: f.isSubmitting,
        isValidating: f.isValidating,
        submitCount: f.submitCount,
        disabled: f.disabled,
        formErrors: f.formErrors,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ZardFormSnapshot &&
          other.isValid == isValid &&
          other.isDirty == isDirty &&
          other.isTouched == isTouched &&
          other.isSubmitting == isSubmitting &&
          other.isValidating == isValidating &&
          other.submitCount == submitCount &&
          other.disabled == disabled &&
          listEquals(other.formErrors, formErrors);

  @override
  int get hashCode => Object.hash(
        isValid,
        isDirty,
        isTouched,
        isSubmitting,
        isValidating,
        submitCount,
        disabled,
        Object.hashAll(formErrors),
      );
}

/// Subscribes to form-level state. Pass [listen] to limit which fields of the
/// snapshot trigger a rebuild — e.g. `listen: (s) => [s.isSubmitting]`. The
/// returned tuple's equality drives rebuild decisions, so listing only what
/// your UI uses keeps it cheap.
ZardFormSnapshot useFormState({
  ZardFormController? form,
  List<Object?> Function(ZardFormSnapshot snapshot)? listen,
}) {
  final context = useContext();
  final resolved = form ?? ZardFormScope.of(context);
  final snapshot = useState<ZardFormSnapshot>(ZardFormSnapshot.from(resolved));
  useEffect(() {
    void onChange() {
      final next = ZardFormSnapshot.from(resolved);
      if (listen == null) {
        if (snapshot.value != next) snapshot.value = next;
        return;
      }
      final prev = listen(snapshot.value);
      final now = listen(next);
      if (!listEquals(prev, now)) {
        snapshot.value = next;
      }
    }
    resolved.addListener(onChange);
    return () => resolved.removeListener(onChange);
  }, [resolved]);
  return snapshot.value;
}
