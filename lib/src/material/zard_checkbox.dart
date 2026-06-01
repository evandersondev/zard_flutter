import 'package:flutter/material.dart';

import '../core/field_controller.dart';
import '../core/field_state.dart';
import '../core/form_scope.dart';
import '../widgets/zard_field.dart';

class ZardCheckbox extends StatelessWidget {
  const ZardCheckbox({
    this.name,
    this.label,
    this.activeColor,
    this.checkColor,
    this.fillColor,
    this.tristate = false,
    this.contentPadding = EdgeInsets.zero,
    super.key,
  });

  final String? name;
  final String? label;
  final Color? activeColor;
  final Color? checkColor;
  final WidgetStateProperty<Color?>? fillColor;
  final bool tristate;
  final EdgeInsetsGeometry contentPadding;

  ZardFieldController<bool>? _resolve(BuildContext context) {
    if (name != null) {
      return ZardFormScope.maybeOf(context)?.register<bool>(name!);
    }
    final any = ZardFieldBinding.maybeOf(context);
    return any is ZardFieldController<bool> ? any : null;
  }

  @override
  Widget build(BuildContext context) {
    final field = _resolve(context);
    assert(field != null,
        'ZardCheckbox could not resolve a field — wrap in ZardField or pass name:.');
    return ValueListenableBuilder<ZardFieldState<bool>>(
      valueListenable: field!.state,
      builder: (ctx, state, _) {
        final checkbox = Checkbox(
          value: state.value,
          tristate: tristate,
          activeColor: activeColor,
          checkColor: checkColor,
          fillColor: fillColor,
          onChanged: state.disabled ? null : (v) => field.setValue(v ?? false),
        );
        final child = label == null
            ? checkbox
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  checkbox,
                  const SizedBox(width: 4),
                  Flexible(child: Text(label!)),
                ],
              );
        return Padding(padding: contentPadding, child: child);
      },
    );
  }
}
