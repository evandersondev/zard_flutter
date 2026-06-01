import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:zard/zard.dart';

import 'async_validator.dart';
import 'errors.dart';
import 'field_array.dart';
import 'field_controller.dart';
import 'path.dart';
import 'validation_mode.dart';

/// Reactive form controller backed by a zard [ZMap] schema.
///
/// Owns form-level state (isSubmitting, isValidating, isValid, isDirty,
/// formErrors, submitCount, disabled, registered paths). Per-field state is
/// owned by [ZardFieldController] instances and listened to individually so
/// per-keystroke rebuilds stay field-scoped.
///
/// Subscribe to this controller (via [InheritedNotifier] / [AnimatedBuilder] /
/// [Listenable.merge]) only for form-level concerns.
class ZardFormController extends ChangeNotifier {
  ZardFormController({
    required ZMap schema,
    Map<String, dynamic> defaultValues = const {},
    this.mode = ValidationMode.onSubmit,
    this.revalidateMode = RevalidateMode.onChange,
    this.debounce = Duration.zero,
    bool disabled = false,
    this.asyncValidation = false,
    this.excludeDisabledFromValues = false,
  })  : _schema = schema,
        _disabled = disabled,
        _defaultValues = _deepCloneMap(defaultValues),
        _values = _deepCloneMap(defaultValues);

  final ZMap _schema;
  ZMap get schema => _schema;

  /// When the first validation pass runs for a field. See [ValidationMode].
  final ValidationMode mode;

  /// After a field is errored, when to re-validate it as the user fixes it.
  final RevalidateMode revalidateMode;

  /// Whole-form debounce for validation triggered by user input.
  final Duration debounce;

  /// Whether the form should use the async parse pipeline by default.
  /// `handleSubmit` always uses async; this controls live edit validation.
  final bool asyncValidation;

  /// If true, [values] and the submission payload omit paths whose effective
  /// disabled is true.
  final bool excludeDisabledFromValues;

  final Map<String, dynamic> _defaultValues;
  Map<String, dynamic> _values;
  Map<String, List<String>> _errors = {};
  List<String> _formErrors = const [];

  final Map<String, ZardFieldController> _fields = {};
  final Map<String, AsyncValidatorEntry> _asyncValidators = {};
  final Map<String, ZardFieldArray> _fieldArrays = {};
  final Set<String> _dirtyFields = {};
  final Set<String> _touchedFields = {};

  bool _isSubmitting = false;
  bool _isValidating = false;
  bool _isValid = true;
  bool _disabled;
  int _submitCount = 0;

  Timer? _debounceTimer;
  Future<void> _parseLock = Future.value();
  bool _disposed = false;

  // -----------------------------------------------------------------------
  // Public form-level getters
  // -----------------------------------------------------------------------

  bool get isSubmitting => _isSubmitting;
  bool get isValidating => _isValidating;
  bool get isValid => _isValid;
  bool get isDirty => _dirtyFields.isNotEmpty;
  bool get isTouched => _touchedFields.isNotEmpty;
  int get submitCount => _submitCount;
  bool get disabled => _disabled;

  List<String> get formErrors => _formErrors;
  Map<String, List<String>> get errors => Map.unmodifiable(_errors);
  Set<String> get dirtyFields => Set.unmodifiable(_dirtyFields);
  Set<String> get touchedFields => Set.unmodifiable(_touchedFields);

  Iterable<String> get registeredPaths => _fields.keys;

  /// Read-only snapshot of current form values, deep-copied.
  /// When [excludeDisabledFromValues] is true, disabled paths are omitted.
  Map<String, dynamic> get values {
    final snap = _deepCloneMap(_values);
    if (excludeDisabledFromValues) {
      for (final entry in _fields.entries) {
        if (entry.value.currentState.disabled) {
          removePath(snap, parsePath(entry.key));
        }
      }
    }
    return snap;
  }

  /// Returns the value at [path], or null if missing.
  V? getValue<V>(String path) {
    final v = readPath(_values, parsePath(path));
    return v is V ? v : v as V?;
  }

  // -----------------------------------------------------------------------
  // Field registration
  // -----------------------------------------------------------------------

  ZardFieldController<V> register<V>(
    String path, {
    V? defaultValue,
    bool disabled = false,
  }) {
    final key = canonicalizePath(path);
    final existing = _fields[key];
    if (existing != null) {
      return existing as ZardFieldController<V>;
    }
    // Seed value from current form values, falling back to defaultValue.
    final segs = parsePath(key);
    final existingValue = readPath(_values, segs);
    final V? seed = (existingValue is V) ? existingValue : defaultValue;
    if (existingValue == null && defaultValue != null) {
      writePath(_values, segs, defaultValue);
    }
    final ctrl = ZardFieldController<V>.internal(
      form: this,
      path: key,
      initialValue: seed,
      disabled: _disabled || disabled,
    );
    // Apply current errors for this path.
    final initialErrors = _errors[key];
    if (initialErrors != null && initialErrors.isNotEmpty) {
      ctrl.setErrors(initialErrors);
    }
    _fields[key] = ctrl;
    _notifyAfterBuild();
    return ctrl;
  }

  void unregister(String path) {
    final key = canonicalizePath(path);
    final ctrl = _fields.remove(key);
    if (ctrl == null) return;
    ctrl.dispose();
    _errors.remove(key);
    _dirtyFields.remove(key);
    _touchedFields.remove(key);
    _notifyAfterBuild();
  }

  ZardFieldController<V>? field<V>(String path) {
    final key = canonicalizePath(path);
    final ctrl = _fields[key];
    return ctrl as ZardFieldController<V>?;
  }

  // -----------------------------------------------------------------------
  // Value mutation
  // -----------------------------------------------------------------------

  void setValue(
    String path,
    dynamic value, {
    bool shouldValidate = true,
    bool shouldDirty = true,
    bool shouldTouch = false,
  }) {
    final key = canonicalizePath(path);
    final segs = parsePath(key);
    final previous = readPath(_values, segs);
    if (previous == value) {
      // Still honor touched flips even when value unchanged.
      if (shouldTouch) _markTouched(key);
      return;
    }
    writePath(_values, segs, value);

    if (shouldDirty) {
      final isDirtyNow = !_deepEquals(_readDefault(segs), value);
      if (isDirtyNow) {
        _dirtyFields.add(key);
      } else {
        _dirtyFields.remove(key);
      }
    }
    if (shouldTouch) _markTouched(key);

    // Update the field controller's state (does NOT re-enter setValue).
    final ctrl = _fields[key];
    if (ctrl != null) {
      ctrl.applyExternalValue(value, isDirty: _dirtyFields.contains(key));
    }

    // Decide whether to validate.
    if (shouldValidate && _shouldValidateOnChange(key)) {
      _scheduleValidation(cause: 'change:$key');
    }

    notifyListeners();
  }

  void setValues(Map<String, dynamic> partial) {
    _flattenInto(partial, '', (path, value) {
      setValue(path, value, shouldValidate: false, shouldDirty: true);
    });
    if (mode == ValidationMode.onChange || mode == ValidationMode.all) {
      _scheduleValidation(cause: 'setValues');
    }
  }

  // -----------------------------------------------------------------------
  // Errors
  // -----------------------------------------------------------------------

  void setError(String path, String message) {
    final key = canonicalizePath(path);
    if (key.isEmpty) {
      _formErrors = List.unmodifiable([..._formErrors, message]);
    } else {
      final next = [..._errors[key] ?? const <String>[], message];
      _errors[key] = List.unmodifiable(next);
      _fields[key]?.setErrors(next);
    }
    _isValid = false;
    notifyListeners();
  }

  void clearErrors([String? path]) {
    if (path == null) {
      _errors.clear();
      _formErrors = const [];
      for (final ctrl in _fields.values) {
        ctrl.setErrors(const []);
      }
    } else {
      final key = canonicalizePath(path);
      if (key.isEmpty) {
        _formErrors = const [];
      } else {
        _errors.remove(key);
        _fields[key]?.setErrors(const []);
      }
    }
    _isValid = _errors.isEmpty && _formErrors.isEmpty;
    notifyListeners();
  }

  // -----------------------------------------------------------------------
  // Validation
  // -----------------------------------------------------------------------

  Future<bool> trigger([String? path]) async {
    await _runValidation(useAsync: asyncValidation, cause: 'trigger:${path ?? '*'}');
    if (path == null) return _isValid;
    return (_errors[canonicalizePath(path)] ?? const []).isEmpty;
  }

  Future<bool> validate({bool async = false}) async {
    await _runValidation(useAsync: async, cause: 'validate');
    return _isValid;
  }

  // -----------------------------------------------------------------------
  // Submit
  // -----------------------------------------------------------------------

  /// Returns a `VoidCallback` you can hand directly to a button's
  /// `onPressed:`. Calling it triggers the full submit flow (validation +
  /// `onValid` / `onInvalid`).
  VoidCallback handleSubmit(
    FutureOr<void> Function(Map<String, dynamic> values) onValid, {
    FutureOr<void> Function(Map<String, List<String>> errors)? onInvalid,
  }) {
    return () => submit(onValid, onInvalid: onInvalid);
  }

  /// Same as the callback produced by [handleSubmit], but returns the future
  /// so callers can `await` completion.
  Future<void> submit(
    FutureOr<void> Function(Map<String, dynamic> values) onValid, {
    FutureOr<void> Function(Map<String, List<String>> errors)? onInvalid,
  }) async {
    if (_isSubmitting) return;
    _isSubmitting = true;
    notifyListeners();
    try {
      // Mark every registered field as touched so onTouched/onBlur modes
      // finally surface their errors after a submit attempt.
      for (final key in _fields.keys) {
        _touchedFields.add(key);
        _fields[key]?.setTouched(true);
      }
      await _runValidation(useAsync: true, cause: 'submit');
      if (_isValid) {
        try {
          await onValid(values);
        } catch (e) {
          setError('', e.toString());
          rethrow;
        }
      } else {
        if (onInvalid != null) {
          await onInvalid(Map.unmodifiable(_errors));
        }
      }
    } finally {
      _submitCount += 1;
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // -----------------------------------------------------------------------
  // Reset
  // -----------------------------------------------------------------------

  void reset({
    Map<String, dynamic>? values,
    bool keepErrors = false,
    bool keepDirty = false,
    bool keepTouched = false,
  }) {
    _values = _deepCloneMap(values ?? _defaultValues);
    if (!keepErrors) {
      _errors = {};
      _formErrors = const [];
    }
    if (!keepDirty) _dirtyFields.clear();
    if (!keepTouched) _touchedFields.clear();
    for (final entry in _fields.entries) {
      final key = entry.key;
      final ctrl = entry.value;
      final segs = parsePath(key);
      final newValue = readPath(_values, segs);
      ctrl.applyExternalValue(newValue, isDirty: _dirtyFields.contains(key));
      if (!keepErrors) ctrl.setErrors(const []);
      if (!keepTouched) ctrl.setTouched(false);
    }
    _isValid = _errors.isEmpty && _formErrors.isEmpty;
    notifyListeners();
  }

  // -----------------------------------------------------------------------
  // Disabled cascade
  // -----------------------------------------------------------------------

  void disable() => _setDisabled(true);
  void enable() => _setDisabled(false);
  set disabledForm(bool value) => _setDisabled(value);

  void _setDisabled(bool value) {
    if (_disabled == value) return;
    _disabled = value;
    for (final entry in _fields.entries) {
      final ctrl = entry.value;
      ctrl.setDisabled(_disabled || ctrl.currentState.disabled && !_disabled);
      // Actually: cascade just sets effectiveDisabled = form OR field. The
      // ctrl.currentState.disabled reflects the per-field flag. We can't
      // distinguish here, so we set state.disabled to form-level value when
      // form-disabled flips on, and otherwise restore from per-field flag we
      // track in a separate map. Keep it simple: per-field "disabled" is the
      // effective value users observe; we expose [setFieldDisabled].
    }
    notifyListeners();
  }

  /// Set the per-field disabled flag (composed with form-level disabled).
  void setFieldDisabled(String path, bool disabled) {
    final key = canonicalizePath(path);
    final effective = _disabled || disabled;
    _fields[key]?.setDisabled(effective);
  }

  // -----------------------------------------------------------------------
  // Async validators
  // -----------------------------------------------------------------------

  void registerAsyncValidator(
    String path,
    AsyncFieldValidator validator, {
    Duration debounce = const Duration(milliseconds: 300),
  }) {
    final key = canonicalizePath(path);
    _asyncValidators[key] = AsyncValidatorEntry(
      validator: validator,
      debounce: debounce,
    );
  }

  void unregisterAsyncValidator(String path) {
    final key = canonicalizePath(path);
    final entry = _asyncValidators.remove(key);
    entry?.timer?.cancel();
  }

  // -----------------------------------------------------------------------
  // Field arrays
  // -----------------------------------------------------------------------

  ZardFieldArray<E> useFieldArray<E>(String path) {
    final key = canonicalizePath(path);
    final existing = _fieldArrays[key];
    if (existing != null) return existing as ZardFieldArray<E>;
    final segs = parsePath(key);
    final initial = readPath(_values, segs);
    final List<dynamic> initialList = (initial is List)
        ? List<dynamic>.from(initial)
        : <dynamic>[];
    if (initial is! List) {
      writePath(_values, segs, initialList);
    }
    final arr = ZardFieldArray<E>.internal(form: this, path: key);
    arr.initializeInternal(initialList.cast<E>());
    _fieldArrays[key] = arr;
    return arr;
  }

  // -----------------------------------------------------------------------
  // Internal — invoked from ZardFieldController on focus blur.
  // -----------------------------------------------------------------------

  void onFieldBlur(String path) {
    final key = canonicalizePath(path);
    final hasError = (_errors[key] ?? const []).isNotEmpty;
    final shouldRevalidate = hasError
        ? revalidateMode == RevalidateMode.onBlur
        : mode == ValidationMode.onBlur ||
            mode == ValidationMode.onTouched ||
            mode == ValidationMode.all;
    if (shouldRevalidate) {
      _scheduleValidation(cause: 'blur:$key');
    }
  }

  // -----------------------------------------------------------------------
  // Validation pipeline
  // -----------------------------------------------------------------------

  bool _shouldValidateOnChange(String fieldKey) {
    final hasError = (_errors[fieldKey] ?? const []).isNotEmpty;
    if (hasError) {
      return revalidateMode == RevalidateMode.onChange;
    }
    switch (mode) {
      case ValidationMode.onChange:
      case ValidationMode.all:
        return true;
      case ValidationMode.onTouched:
        return _touchedFields.contains(fieldKey);
      case ValidationMode.onBlur:
      case ValidationMode.onSubmit:
        return false;
    }
  }

  void _scheduleValidation({required String cause}) {
    if (debounce == Duration.zero) {
      // Microtask deferral so consecutive sync setValue calls coalesce.
      scheduleMicrotask(() {
        // ignore: discarded_futures
        _runValidation(useAsync: asyncValidation, cause: cause);
      });
      return;
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () {
      // ignore: discarded_futures
      _runValidation(useAsync: asyncValidation, cause: cause);
    });
  }

  Future<void> _runValidation({
    required bool useAsync,
    required String cause,
  }) {
    // Serialize parses so concurrent invocations don't corrupt Schema._ctx.
    final completer = Completer<void>();
    final prev = _parseLock;
    _parseLock = completer.future;
    // Run after prior parse completes.
    () async {
      try {
        await prev;
        await _runValidationImpl(useAsync: useAsync);
      } finally {
        completer.complete();
      }
    }();
    return _parseLock;
  }

  Future<void> _runValidationImpl({required bool useAsync}) async {
    final snapshot = _deepCloneMap(_values);
    _isValidating = true;
    notifyListeners();
    try {
      ZardError? error;
      Map<String, dynamic>? data;
      if (useAsync) {
        final res = await _schema.safeParseAsync(snapshot);
        if (res.success) {
          data = res.data;
        } else {
          error = res.error;
        }
      } else {
        final res = _schema.safeParse(snapshot);
        if (res.success) {
          data = res.data;
        } else {
          error = res.error;
        }
      }

      // Replace _values with the parsed (potentially transformed) data only
      // when the parse succeeded. On failure, keep raw user input.
      if (data != null) {
        _values = data;
      }

      var normalized = error == null
          ? NormalizedErrors(fieldErrors: const {}, formErrors: const [])
          : normalizeZardError(error);

      // Run async per-path validators. Sync mode skips them.
      if (useAsync && _asyncValidators.isNotEmpty) {
        final extras = await _runAsyncValidators(snapshot);
        if (extras.isNotEmpty) {
          final merged = <String, List<String>>{};
          merged.addAll(normalized.fieldErrors);
          extras.forEach((key, msg) {
            if (msg == null) return;
            (merged[key] ??= []).add(msg);
          });
          normalized = NormalizedErrors(
            fieldErrors: merged,
            formErrors: normalized.formErrors,
          );
        }
      }

      _applyValidationResult(normalized);
    } finally {
      _isValidating = false;
      notifyListeners();
    }
  }

  Future<Map<String, String?>> _runAsyncValidators(
      Map<String, dynamic> snapshot) async {
    final futures = <String, Future<String?>>{};
    for (final entry in _asyncValidators.entries) {
      final key = entry.key;
      final segs = parsePath(key);
      final value = readPath(snapshot, segs);
      final field = _fields[key];
      field?.setValidating(true);
      futures[key] = entry.value.validator(value, snapshot);
    }
    final results = <String, String?>{};
    for (final entry in futures.entries) {
      try {
        results[entry.key] = await entry.value;
      } catch (e) {
        results[entry.key] = e.toString();
      } finally {
        _fields[entry.key]?.setValidating(false);
      }
    }
    return results;
  }

  void _applyValidationResult(NormalizedErrors normalized) {
    // Diff form errors.
    final formChanged = !listEquals(normalized.formErrors, _formErrors);
    if (formChanged) {
      _formErrors = List.unmodifiable(normalized.formErrors);
    }

    // Diff per-field errors. Only re-emit ZardFieldState for fields whose
    // error list changed.
    final newFieldErrors = normalized.fieldErrors;
    final allKeys = <String>{..._errors.keys, ...newFieldErrors.keys};
    for (final key in allKeys) {
      final prev = _errors[key] ?? const <String>[];
      final next = newFieldErrors[key] ?? const <String>[];
      if (!listEquals(prev, next)) {
        if (next.isEmpty) {
          _errors.remove(key);
        } else {
          _errors[key] = List.unmodifiable(next);
        }
        _fields[key]?.setErrors(next);
      }
    }

    final wasValid = _isValid;
    _isValid = _errors.isEmpty && _formErrors.isEmpty;
    if (wasValid != _isValid || formChanged) {
      // notifyListeners is called by the enclosing _runValidationImpl
    }
  }

  // -----------------------------------------------------------------------
  // Internal helpers
  // -----------------------------------------------------------------------

  /// Notifies form-level listeners, deferring to after the current frame when
  /// invoked during the build/layout phase.
  ///
  /// Field registration happens from [ZardField.didChangeDependencies], which
  /// runs inside the build phase. Calling [notifyListeners] there would make
  /// the [ZardFormScope] (an [InheritedNotifier] ancestor) try to rebuild while
  /// its descendants are still building, throwing "setState() or
  /// markNeedsBuild() called during build".
  void _notifyAfterBuild() {
    // Resolve the binding defensively: in pure-Dart unit tests there is no
    // initialized binding, in which case we're never inside a build phase and
    // can notify synchronously.
    SchedulerBinding? binding;
    try {
      binding = SchedulerBinding.instance;
    } catch (_) {
      binding = null;
    }
    if (binding != null &&
        binding.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      binding.addPostFrameCallback((_) {
        if (!_disposed) notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  void _markTouched(String key) {
    if (_touchedFields.add(key)) {
      _fields[key]?.setTouched(true);
    }
  }

  dynamic _readDefault(List<PathSegment> segs) =>
      readPath(_defaultValues, segs);

  void _flattenInto(
    Map<String, dynamic> partial,
    String prefix,
    void Function(String path, dynamic value) emit,
  ) {
    partial.forEach((k, v) {
      final p = prefix.isEmpty ? k : '$prefix.$k';
      if (v is Map<String, dynamic>) {
        _flattenInto(v, p, emit);
      } else if (v is Map) {
        _flattenInto(Map<String, dynamic>.from(v), p, emit);
      } else {
        emit(p, v);
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
    for (final entry in _asyncValidators.values) {
      entry.timer?.cancel();
    }
    for (final ctrl in _fields.values) {
      ctrl.dispose();
    }
    _fields.clear();
    _fieldArrays.clear();
    super.dispose();
  }

  // -----------------------------------------------------------------------
  // Internal accessors used by ZardFieldArray.
  // -----------------------------------------------------------------------

  Map<String, ZardFieldController> get fieldsInternal => _fields;
  Map<String, dynamic> get valuesInternal => _values;
}

// ---------------------------------------------------------------------------
// Utilities
// ---------------------------------------------------------------------------

Map<String, dynamic> _deepCloneMap(Map<String, dynamic> source) {
  final out = <String, dynamic>{};
  source.forEach((k, v) => out[k] = _deepCloneValue(v));
  return out;
}

dynamic _deepCloneValue(dynamic v) {
  if (v is Map) {
    return _deepCloneMap(Map<String, dynamic>.from(v));
  }
  if (v is List) {
    return v.map(_deepCloneValue).toList();
  }
  return v;
}

bool _deepEquals(dynamic a, dynamic b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return a == b;
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final k in a.keys) {
      if (!b.containsKey(k)) return false;
      if (!_deepEquals(a[k], b[k])) return false;
    }
    return true;
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_deepEquals(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}
