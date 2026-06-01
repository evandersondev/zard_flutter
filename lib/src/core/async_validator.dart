import 'dart:async';

/// User-supplied async validator for a single field path.
///
/// Receives the current field value and the full form values. Return `null`
/// for "valid" or a non-empty string message for "invalid".
typedef AsyncFieldValidator = Future<String?> Function(
  dynamic value,
  Map<String, dynamic> values,
);

class AsyncValidatorEntry {
  AsyncValidatorEntry({
    required this.validator,
    required this.debounce,
  });

  final AsyncFieldValidator validator;
  final Duration debounce;
  Timer? timer;
  int generation = 0;
}
