/// Reactive forms for Flutter, powered by the [zard](../zard) validation
/// library.
///
/// Inspired by React Hook Form + Zod + Radix UI / shadcn:
/// - granular per-field subscriptions, low rebuilds
/// - nested paths (`user.address.0.street`)
/// - validation modes (onChange / onBlur / onSubmit / onTouched / all)
/// - field arrays with stable row ids
/// - async per-path validators
/// - typed output via `z.map(...).transformTyped<T>(...)`
/// - headless primitives + Material-friendly ready-made widgets
///
/// The optional hooks layer lives at `package:zard_flutter/hooks.dart` and
/// is the only file that imports `flutter_hooks`.
library;

// Core
export 'src/core/async_validator.dart' show AsyncFieldValidator;
export 'src/core/field_array.dart' show ZardFieldArray, ZardFieldArrayRow;
export 'src/core/field_controller.dart' show ZardFieldController;
export 'src/core/field_state.dart' show ZardFieldState;
export 'src/core/form_controller.dart' show ZardFormController;
export 'src/core/form_scope.dart' show ZardFormScope;
export 'src/core/path.dart'
    show PathSegment, KeySegment, IndexSegment, parsePath, canonicalPath, canonicalizePath;
export 'src/core/validation_mode.dart' show ValidationMode, RevalidateMode;

// Headless widgets
export 'src/widgets/zard_description.dart';
export 'src/widgets/zard_error_message.dart';
export 'src/widgets/zard_field.dart';
export 'src/widgets/zard_form.dart';
export 'src/widgets/zard_form_section.dart';
export 'src/widgets/zard_label.dart';
export 'src/widgets/zard_watch.dart';

// Material-friendly ready-made widgets
export 'src/material/zard_button.dart';
export 'src/material/zard_checkbox.dart';
export 'src/material/zard_devtools.dart';
export 'src/material/zard_input.dart';
export 'src/material/zard_radio_group.dart';
export 'src/material/zard_select.dart';
export 'src/material/zard_switch.dart';
export 'src/material/zard_textarea.dart';
