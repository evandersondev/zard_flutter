import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:zard/zard.dart';

import '../core/form_controller.dart';
import '../core/validation_mode.dart';

/// React-Hook-Form-style `useForm` hook. Creates a [ZardFormController] tied
/// to the calling widget's lifecycle (disposed on unmount). Subscribes to the
/// controller so form-level state flips (isSubmitting, isValid, etc.) cause
/// a rebuild.
///
/// Pair with a `ZardForm(form: form, ...)` so descendant widgets/hooks can
/// resolve the form via context. If your tree doesn't need that scoping,
/// you can use the returned controller directly.
ZardFormController useForm({
  required ZMap schema,
  Map<String, dynamic> defaultValues = const {},
  ValidationMode mode = ValidationMode.onSubmit,
  RevalidateMode revalidateMode = RevalidateMode.onChange,
  Duration debounce = Duration.zero,
  bool disabled = false,
  bool asyncValidation = false,
  bool excludeDisabledFromValues = false,
}) {
  final form = useMemoized(
    () => ZardFormController(
      schema: schema,
      defaultValues: defaultValues,
      mode: mode,
      revalidateMode: revalidateMode,
      debounce: debounce,
      disabled: disabled,
      asyncValidation: asyncValidation,
      excludeDisabledFromValues: excludeDisabledFromValues,
    ),
    const [],
  );
  useEffect(() => form.dispose, [form]);
  useListenable(form);
  return form;
}
