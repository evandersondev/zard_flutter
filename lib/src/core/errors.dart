import 'package:zard/zard.dart';

import 'path.dart';

/// Result of normalizing a [ZardError] into per-path errors.
class NormalizedErrors {
  NormalizedErrors({
    required this.fieldErrors,
    required this.formErrors,
  });

  /// Canonicalized (dot-only) path → list of error messages.
  /// Root-level errors live in [formErrors] instead.
  final Map<String, List<String>> fieldErrors;

  /// Errors with null/empty path — surfaced as form-level errors.
  final List<String> formErrors;

  static const empty = _emptyNormalized;
}

const NormalizedErrors _emptyNormalized = _Empty();

class _Empty implements NormalizedErrors {
  const _Empty();
  @override
  Map<String, List<String>> get fieldErrors => const {};
  @override
  List<String> get formErrors => const [];
}

/// Normalizes a [ZardError] into canonical (dot-only) paths.
///
/// zard's `ZMap` emits `a.b.c`-style paths while `ZList` emits `a.b[0].c`.
/// Both forms are routed through [parsePath] + [canonicalPath] so internal
/// keys are uniform.
NormalizedErrors normalizeZardError(ZardError error) {
  final fields = <String, List<String>>{};
  final form = <String>[];
  for (final issue in error.issues) {
    final raw = issue.path;
    if (raw == null || raw.isEmpty) {
      form.add(issue.message);
      continue;
    }
    final canonical = canonicalPath(parsePath(raw));
    if (canonical.isEmpty) {
      form.add(issue.message);
    } else {
      (fields[canonical] ??= []).add(issue.message);
    }
  }
  return NormalizedErrors(fieldErrors: fields, formErrors: form);
}
