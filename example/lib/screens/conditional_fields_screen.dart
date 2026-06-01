import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:zard/zard.dart';
import 'package:zard_flutter/hooks.dart';
import 'package:zard_flutter/zard_flutter.dart';

import '../shared/screen_scaffold.dart';

/// Screen 13 — show/hide fields conditionally based on another field's value.
class ConditionalFieldsScreen extends HookWidget {
  const ConditionalFieldsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final form = useForm(
      schema: z.map({
        'subscribe': z.bool(),
        'email': z.string().optional(),
      }),
      defaultValues: const {'subscribe': false, 'email': ''},
      mode: ValidationMode.onChange,
    );
    return ScreenScaffold(
      title: 'Conditional Fields',
      description:
          'Show the email input only when the user opts in. ZardWatch keeps '
          'the dependency surgical.',
      child: ZardForm(
        form: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ZardCheckbox(
              name: 'subscribe',
              label: 'Subscribe to newsletter',
            ),
            const SizedBox(height: 12),
            ZardWatch<bool>(
              name: 'subscribe',
              builder: (ctx, on) {
                if (on != true) return const SizedBox.shrink();
                return const ZardInput(name: 'email', label: 'Email');
              },
            ),
            ZardDevtools(form: form),
          ],
        ),
      ),
    );
  }
}
