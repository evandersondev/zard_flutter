import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:zard/zard.dart';
import 'package:zard_flutter/hooks.dart';
import 'package:zard_flutter/zard_flutter.dart';

import '../shared/screen_scaffold.dart';

/// Screen 6 — nested object paths (`user.name`, `user.address.street`).
class NestedPathsScreen extends HookWidget {
  const NestedPathsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final form = useForm(
      schema: z.map({
        'user': z.map({
          'name': z.string().min(2),
          'address': z.map({
            'street': z.string().min(3),
            'city': z.string().min(2),
          }),
        }),
      }),
      mode: ValidationMode.onTouched,
    );
    final submitted = useState<Map<String, dynamic>?>(null);
    return ScreenScaffold(
      title: 'Nested Paths',
      description: 'Bind fields by dotted path. Errors land on the right field.',
      child: ZardForm(
        form: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ZardField<String>(
              name: 'user.name',
              child: ZardInput(label: 'Name'),
            ),
            const SizedBox(height: 12),
            const ZardField<String>(
              name: 'user.address.street',
              child: ZardInput(label: 'Street'),
            ),
            const SizedBox(height: 12),
            const ZardField<String>(
              name: 'user.address.city',
              child: ZardInput(label: 'City'),
            ),
            const SizedBox(height: 16),
            ZardButton(
              onPressed: form.handleSubmit((data) async {
                submitted.value = data;
              }),
              child: const Text('Submit'),
            ),
            SubmitResult(payload: submitted.value),
            ZardDevtools(form: form),
          ],
        ),
      ),
    );
  }
}
