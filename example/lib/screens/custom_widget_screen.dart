import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:zard/zard.dart';
import 'package:zard_flutter/hooks.dart';
import 'package:zard_flutter/zard_flutter.dart';

import '../shared/screen_scaffold.dart';

/// Screen 14 — wrap a non-Material widget (a slider) using the builder form
/// of ZardField. This proves the package isn't tied to text inputs.
class CustomWidgetScreen extends HookWidget {
  const CustomWidgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final form = useForm(
      schema: z.map({
        'volume': z.double().min(0).max(100).transform(
          (value) {
            return value.round();
          },
        ),
      }),
      defaultValues: const {'volume': 50.0},
      mode: ValidationMode.onChange,
    );
    return ScreenScaffold(
      title: 'Custom Widget (Slider)',
      description:
          'Use ZardField.builder for any custom UI. Here, a Material Slider '
          'is bound to a numeric field.',
      child: ZardForm(
        form: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ZardField<double>.builder(
              name: 'volume',
              defaultValue: 50,
              builder: (ctx, field, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Volume: ${(state.value ?? 0).toStringAsFixed(0)}'),
                    Slider(
                      value: state.value ?? 0,
                      min: 0,
                      max: 100,
                      divisions: 50,
                      onChanged:
                          state.disabled ? null : (v) => field.setValue(v),
                    ),
                    if (state.error != null)
                      Text(state.error!,
                          style: const TextStyle(color: Color(0xFFB91C1C))),
                  ],
                );
              },
            ),
            ZardDevtools(form: form),
          ],
        ),
      ),
    );
  }
}
