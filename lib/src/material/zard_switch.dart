import 'package:flutter/material.dart';

import '../core/field_controller.dart';
import '../core/field_state.dart';
import '../core/form_scope.dart';
import '../widgets/zard_field.dart';

class ZardSwitch extends StatelessWidget {
  const ZardSwitch({
    this.name,
    this.label,
    this.activeColor,
    this.activeTrackColor,
    this.inactiveThumbColor,
    this.inactiveTrackColor,
    this.contentPadding = EdgeInsets.zero,
    super.key,
  });

  final String? name;
  final String? label;
  final Color? activeColor;
  final Color? activeTrackColor;
  final Color? inactiveThumbColor;
  final Color? inactiveTrackColor;
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
        'ZardSwitch could not resolve a field — wrap in ZardField or pass name:.');
    return ValueListenableBuilder<ZardFieldState<bool>>(
      valueListenable: field!.state,
      builder: (ctx, state, _) {
        final sw = Switch(
          value: state.value ?? false,
          activeColor: activeColor,
          activeTrackColor: activeTrackColor,
          inactiveThumbColor: inactiveThumbColor,
          inactiveTrackColor: inactiveTrackColor,
          onChanged: state.disabled ? null : (v) => field.setValue(v),
        );
        final child = label == null
            ? sw
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text(label!)),
                  const SizedBox(width: 8),
                  sw,
                ],
              );
        return Padding(padding: contentPadding, child: child);
      },
    );
  }
}
