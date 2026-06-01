import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:zard/zard.dart';
import 'package:zard_flutter/hooks.dart';
import 'package:zard_flutter/zard_flutter.dart';

import '../shared/screen_scaffold.dart';

/// Screen 8 — setError, clearErrors, trigger.
class ManualErrorsScreen extends HookWidget {
  const ManualErrorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final form = useForm(
      schema: z.map({
        'email': z.string().email(message: 'Invalid email'),
      }),
      defaultValues: const {'email': ''},
    );
    return ScreenScaffold(
      title: 'Manual Errors & Trigger',
      description:
          'setError / clearErrors set or clear errors programmatically. '
          'trigger(path) re-runs validation for the form (or a single path).',
      child: ZardForm(
        form: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ZardField<String>(
              name: 'email',
              child: ZardInput(label: 'Email'),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () =>
                      form.setError('email', 'Email already exists'),
                  child: const Text("setError('email', ...)"),
                ),
                OutlinedButton(
                  onPressed: () => form.clearErrors('email'),
                  child: const Text("clearErrors('email')"),
                ),
                OutlinedButton(
                  onPressed: () => form.clearErrors(),
                  child: const Text('clearErrors()'),
                ),
                OutlinedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final ok = await form.trigger();
                    messenger.showSnackBar(SnackBar(
                      content: Text('trigger() → $ok'),
                      duration: const Duration(seconds: 1),
                    ));
                  },
                  child: const Text('trigger()'),
                ),
              ],
            ),
            ZardDevtools(form: form),
          ],
        ),
      ),
    );
  }
}
