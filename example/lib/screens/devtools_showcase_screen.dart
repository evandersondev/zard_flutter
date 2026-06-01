import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:zard/zard.dart';
import 'package:zard_flutter/hooks.dart';
import 'package:zard_flutter/zard_flutter.dart';

import '../shared/screen_scaffold.dart';

/// Screen 15 — kitchen-sink form that exists to show off [ZardDevtools].
class DevtoolsShowcaseScreen extends HookWidget {
  const DevtoolsShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final form = useForm(
      schema: z.map({
        'name': z.string().min(2),
        'role': z.string(),
        'newsletter': z.bool(),
        'tier': z.string(),
        'rating': z.int().min(1).max(5),
      }),
      defaultValues: const {
        'name': '',
        'role': 'engineer',
        'newsletter': false,
        'tier': 'free',
        'rating': 3,
      },
      mode: ValidationMode.onChange,
    );
    return ScreenScaffold(
      title: 'DevTools Showcase',
      description:
          'A grab-bag of widgets; open the DevTools panel below to inspect '
          'every field live as you interact with the form.',
      child: ZardForm(
        form: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ZardInput(name: 'name', label: 'Name'),
            const SizedBox(height: 12),
            const ZardSelect<String>(
              name: 'role',
              label: 'Role',
              options: [
                ZardSelectOption(value: 'engineer', label: 'Engineer'),
                ZardSelectOption(value: 'designer', label: 'Designer'),
                ZardSelectOption(value: 'pm', label: 'Product Manager'),
              ],
            ),
            const SizedBox(height: 12),
            const ZardSwitch(
              name: 'newsletter',
              label: 'Subscribe to newsletter',
            ),
            const SizedBox(height: 12),
            const ZardRadioGroup<String>(
              name: 'tier',
              options: [
                ZardRadioOption(value: 'free', label: 'Free'),
                ZardRadioOption(value: 'pro', label: 'Pro'),
                ZardRadioOption(value: 'team', label: 'Team'),
              ],
            ),
            const SizedBox(height: 12),
            ZardField<int>.builder(
              name: 'rating',
              defaultValue: 3,
              builder: (ctx, field, state) => Row(
                children: [
                  const Text('Rating:'),
                  const SizedBox(width: 8),
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      icon: Icon(
                        i <= (state.value ?? 0)
                            ? Icons.star
                            : Icons.star_border,
                      ),
                      onPressed: () => field.setValue(i),
                    ),
                ],
              ),
            ),
            ZardDevtools(form: form),
          ],
        ),
      ),
    );
  }
}
