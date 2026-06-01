import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:zard/zard.dart';
import 'package:zard_flutter/hooks.dart';
import 'package:zard_flutter/zard_flutter.dart';

import '../shared/screen_scaffold.dart';

/// Screen 7 — default values + reset variants (clean, keep dirty/touched/errors).
class DefaultsResetScreen extends HookWidget {
  const DefaultsResetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final form = useForm(
      schema: z.map({
        'email': z.string().email(message: 'Invalid email'),
        'nickname': z.string(),
      }),
      defaultValues: const {
        'email': 'default@zard.dev',
        'nickname': 'guest',
      },
      mode: ValidationMode.onTouched,
    );
    return ScreenScaffold(
      title: 'Defaults & Reset',
      description:
          'reset() restores defaults. reset({values: ...}) sets a brand new baseline. '
          'Pass keepDirty/keepTouched/keepErrors to preserve those flags.',
      child: ZardForm(
        form: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ZardInput(name: 'email', label: 'Email'),
            const SizedBox(height: 12),
            const ZardInput(name: 'nickname', label: 'Nickname'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => form.reset(),
                  child: const Text('reset()'),
                ),
                OutlinedButton(
                  onPressed: () => form.reset(values: const {
                    'email': 'rebooted@zard.dev',
                    'nickname': 'rebooted',
                  }),
                  child: const Text('reset(values: ...)'),
                ),
                OutlinedButton(
                  onPressed: () => form.reset(keepDirty: true),
                  child: const Text('reset(keepDirty: true)'),
                ),
                OutlinedButton(
                  onPressed: () => form.reset(keepErrors: true),
                  child: const Text('reset(keepErrors: true)'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ZardDevtools(form: form),
          ],
        ),
      ),
    );
  }
}
