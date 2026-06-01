import 'package:flutter/material.dart';

import '../core/field_controller.dart';
import '../core/field_state.dart';
import '../core/form_scope.dart';
import '../widgets/zard_field.dart';

class ZardSelectOption<T> {
  const ZardSelectOption({required this.value, required this.label, this.child});
  final T value;
  final String label;
  final Widget? child;
}

class ZardSelect<T> extends StatelessWidget {
  const ZardSelect({
    required this.options,
    this.name,
    this.label,
    this.placeholder,
    this.decoration,
    this.style,
    this.itemHeight,
    this.isExpanded = true,
    super.key,
  });

  final String? name;
  final String? label;
  final String? placeholder;
  final List<ZardSelectOption<T>> options;
  final InputDecoration? decoration;
  final TextStyle? style;
  final double? itemHeight;
  final bool isExpanded;

  ZardFieldController<T>? _resolve(BuildContext context) {
    if (name != null) {
      return ZardFormScope.maybeOf(context)?.register<T>(name!);
    }
    final any = ZardFieldBinding.maybeOf(context);
    return any is ZardFieldController<T> ? any : null;
  }

  @override
  Widget build(BuildContext context) {
    final field = _resolve(context);
    assert(field != null,
        'ZardSelect could not resolve a field — wrap in ZardField or pass name:.');
    return ValueListenableBuilder<ZardFieldState<T>>(
      valueListenable: field!.state,
      builder: (ctx, state, _) {
        return DropdownButtonFormField<T>(
          value: state.value,
          isExpanded: isExpanded,
          itemHeight: itemHeight,
          style: style,
          decoration: (decoration ?? const InputDecoration()).copyWith(
            labelText: decoration?.labelText ?? label,
            hintText: decoration?.hintText ?? placeholder,
            errorText: state.error,
            enabled: !state.disabled,
          ),
          items: [
            for (final opt in options)
              DropdownMenuItem<T>(
                value: opt.value,
                child: opt.child ?? Text(opt.label),
              ),
          ],
          onChanged: state.disabled ? null : (v) => field.setValue(v),
        );
      },
    );
  }
}
