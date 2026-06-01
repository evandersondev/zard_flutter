/// When the form runs its first validation for a given field.
///
/// Mirrors React Hook Form's `mode` option.
enum ValidationMode {
  /// Validate every change. Aggressive — every keystroke triggers validation.
  onChange,

  /// Validate when a field loses focus.
  onBlur,

  /// Validate only on submit. First-time UX is permissive.
  onSubmit,

  /// Validate after the field has been touched at least once.
  onTouched,

  /// Validate on every event (touch, change, blur, submit).
  all,
}

/// After a field has produced an error, when to re-validate while the user
/// fixes it. Mirrors React Hook Form's `reValidateMode`.
enum RevalidateMode {
  onChange,
  onBlur,
  onSubmit,
}
