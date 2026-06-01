import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'field_state.dart';
import 'form_controller.dart';

class ZardFieldController<T> {
  ZardFieldController._({
    required this.form,
    required String path,
    required T? initialValue,
    required bool disabled,
  })  : _path = path,
        _notifier = ValueNotifier<ZardFieldState<T>>(
          ZardFieldState<T>(value: initialValue, disabled: disabled),
        );

  /// Internal factory used by [ZardFormController.register]. Not part of the
  /// public API — users always create field controllers through the form.
  factory ZardFieldController.internal({
    required ZardFormController form,
    required String path,
    required T? initialValue,
    required bool disabled,
  }) =>
      ZardFieldController<T>._(
        form: form,
        path: path,
        initialValue: initialValue,
        disabled: disabled,
      );

  final ZardFormController form;
  String _path;
  final ValueNotifier<ZardFieldState<T>> _notifier;

  TextEditingController? _textController;
  FocusNode? _focusNode;
  bool _writingFromExternal = false;
  VoidCallback? _textListener;
  VoidCallback? _focusListener;

  String get path => _path;

  ValueListenable<ZardFieldState<T>> get state => _notifier;

  ZardFieldState<T> get currentState => _notifier.value;

  T? get value => _notifier.value.value;

  /// Returns true when this field has a lazily-allocated [TextEditingController].
  bool get hasTextController => _textController != null;

  /// Returns true when this field has a lazily-allocated [FocusNode].
  bool get hasFocusNode => _focusNode != null;

  /// Lazily allocates a [TextEditingController]. Only valid when [T] is
  /// [String] (or [Object]/`dynamic`). Throws if used with a different type.
  TextEditingController get textController {
    assert(
      T == String || T == dynamic || T == Object,
      'TextEditingController is only valid for ZardFieldController<String>. '
      'For non-string fields, use ZardField(builder:) and wire your own input.',
    );
    if (_textController != null) return _textController!;
    final initial = value;
    final controller = TextEditingController(
      text: initial == null ? '' : initial.toString(),
    );
    _textListener = () {
      if (_writingFromExternal) return;
      // Push the new text into the form. setValue will route back through
      // [_applyExternalValue] which honors [_writingFromExternal] to avoid
      // cursor-jump loops.
      form.setValue(
        path,
        controller.text,
        shouldDirty: true,
        // touch is driven by focus, not typing.
      );
    };
    controller.addListener(_textListener!);
    _textController = controller;
    return controller;
  }

  /// Lazily allocates a [FocusNode]. Subscribed by the controller so blur
  /// transitions can drive validation in `onBlur` / `onTouched` modes.
  FocusNode get focusNode {
    if (_focusNode != null) return _focusNode!;
    final node = FocusNode();
    _focusListener = () {
      if (!node.hasFocus) {
        if (!currentState.isTouched) {
          setTouched(true);
        }
        form.onFieldBlur(path);
      }
    };
    node.addListener(_focusListener!);
    _focusNode = node;
    return node;
  }

  /// Public setter — writes through the form for consistent dirty/touched
  /// bookkeeping and validation.
  void setValue(T? value, {bool shouldValidate = true, bool shouldTouch = false}) {
    form.setValue(path, value, shouldValidate: shouldValidate, shouldDirty: true, shouldTouch: shouldTouch);
  }

  void setTouched(bool touched) {
    final s = _notifier.value;
    if (s.isTouched == touched) return;
    _notifier.value = s.copyWith(isTouched: touched);
  }

  void setDirty(bool dirty) {
    final s = _notifier.value;
    if (s.isDirty == dirty) return;
    _notifier.value = s.copyWith(isDirty: dirty);
  }

  void setError(String? message) {
    final s = _notifier.value;
    final next = message == null ? const <String>[] : <String>[message];
    if (s.errors.length == next.length &&
        (next.isEmpty || s.errors.first == next.first)) {
      return;
    }
    _notifier.value = s.copyWith(errors: next);
  }

  void setErrors(List<String> errors) {
    final s = _notifier.value;
    if (s.errors.length == errors.length) {
      var same = true;
      for (var i = 0; i < errors.length; i++) {
        if (s.errors[i] != errors[i]) {
          same = false;
          break;
        }
      }
      if (same) return;
    }
    _notifier.value = s.copyWith(errors: List.unmodifiable(errors));
  }

  void setDisabled(bool disabled) {
    final s = _notifier.value;
    if (s.disabled == disabled) return;
    _notifier.value = s.copyWith(disabled: disabled);
  }

  void setValidating(bool validating) {
    final s = _notifier.value;
    if (s.isValidating == validating) return;
    _notifier.value = s.copyWith(isValidating: validating);
  }

  // -----------------------------------------------------------------------
  // Internal — called only by ZardFormController.
  // -----------------------------------------------------------------------

  /// Internal: rename path (used by ZardFieldArray on move/swap).
  void renameInternal(String newPath) {
    _path = newPath;
  }

  /// Internal: apply a value coming from the form (setValue, reset, array
  /// mutation) without re-entering setValue.
  void applyExternalValue(T? value, {required bool isDirty}) {
    final s = _notifier.value;
    final unchanged = s.value == value && s.isDirty == isDirty;
    if (!unchanged) {
      _notifier.value = s.copyWith(value: value, isDirty: isDirty);
    }
    // Sync TextEditingController if allocated.
    if (_textController != null) {
      final desired = value == null ? '' : value.toString();
      if (_textController!.text != desired) {
        _writingFromExternal = true;
        try {
          _textController!.value = TextEditingValue(
            text: desired,
            selection: TextSelection.collapsed(offset: desired.length),
          );
        } finally {
          _writingFromExternal = false;
        }
      }
    }
  }

  /// Internal: replace just the state (used for diff-then-notify validation).
  void replaceStateInternal(ZardFieldState<T> next) {
    if (_notifier.value == next) return;
    _notifier.value = next;
  }

  void dispose() {
    if (_textListener != null) {
      _textController?.removeListener(_textListener!);
    }
    _textController?.dispose();
    _textController = null;
    if (_focusListener != null) {
      _focusNode?.removeListener(_focusListener!);
    }
    _focusNode?.dispose();
    _focusNode = null;
    _notifier.dispose();
  }
}
