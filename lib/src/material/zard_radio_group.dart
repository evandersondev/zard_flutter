import 'package:flutter/material.dart';

import '../core/field_controller.dart';
import '../core/field_state.dart';
import '../core/form_scope.dart';
import '../widgets/zard_field.dart';

class ZardRadioOption<T> {
  const ZardRadioOption({required this.value, required this.label});
  final T value;
  final String label;
}

class ZardRadioGroup<T> extends StatelessWidget {
  const ZardRadioGroup({
    required this.options,
    this.name,
    this.direction = Axis.vertical,
    this.activeColor,
    this.contentPadding = EdgeInsets.zero,
    this.itemSpacing = 8,
    super.key,
  });

  final String? name;
  final List<ZardRadioOption<T>> options;
  final Axis direction;
  final Color? activeColor;
  final EdgeInsetsGeometry contentPadding;
  final double itemSpacing;

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
        'ZardRadioGroup could not resolve a field — wrap in ZardField or pass name:.');
    return ValueListenableBuilder<ZardFieldState<T>>(
      valueListenable: field!.state,
      builder: (ctx, state, _) {
        final items = <Widget>[];
        for (var i = 0; i < options.length; i++) {
          final opt = options[i];
          items.add(
            InkWell(
              onTap: state.disabled ? null : () => field.setValue(opt.value),
              borderRadius: BorderRadius.circular(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Radio<T>(
                    value: opt.value,
                    groupValue: state.value,
                    activeColor: activeColor,
                    onChanged: state.disabled
                        ? null
                        : (v) => field.setValue(v),
                  ),
                  const SizedBox(width: 4),
                  Text(opt.label),
                ],
              ),
            ),
          );
          if (i < options.length - 1) {
            items.add(SizedBox(
              width: direction == Axis.horizontal ? itemSpacing : 0,
              height: direction == Axis.vertical ? itemSpacing : 0,
            ));
          }
        }
        final wrap = direction == Axis.horizontal
            ? Row(mainAxisSize: MainAxisSize.min, children: items)
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: items);
        return Padding(padding: contentPadding, child: wrap);
      },
    );
  }
}
