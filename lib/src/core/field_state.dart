import 'package:flutter/foundation.dart';

@immutable
class ZardFieldState<T> {
  const ZardFieldState({
    this.value,
    this.errors = const [],
    this.isTouched = false,
    this.isDirty = false,
    this.isValidating = false,
    this.disabled = false,
  });

  final T? value;
  final List<String> errors;
  final bool isTouched;
  final bool isDirty;
  final bool isValidating;
  final bool disabled;

  String? get error => errors.isEmpty ? null : errors.first;
  bool get hasError => errors.isNotEmpty;

  ZardFieldState<T> copyWith({
    Object? value = _unset,
    List<String>? errors,
    bool? isTouched,
    bool? isDirty,
    bool? isValidating,
    bool? disabled,
  }) {
    return ZardFieldState<T>(
      value: identical(value, _unset) ? this.value : value as T?,
      errors: errors ?? this.errors,
      isTouched: isTouched ?? this.isTouched,
      isDirty: isDirty ?? this.isDirty,
      isValidating: isValidating ?? this.isValidating,
      disabled: disabled ?? this.disabled,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ZardFieldState<T> &&
        other.value == value &&
        other.isTouched == isTouched &&
        other.isDirty == isDirty &&
        other.isValidating == isValidating &&
        other.disabled == disabled &&
        listEquals(other.errors, errors);
  }

  @override
  int get hashCode => Object.hash(
        value,
        Object.hashAll(errors),
        isTouched,
        isDirty,
        isValidating,
        disabled,
      );

  @override
  String toString() =>
      'ZardFieldState(value: $value, errors: $errors, touched: $isTouched, dirty: $isDirty, validating: $isValidating, disabled: $disabled)';
}

const Object _unset = Object();
