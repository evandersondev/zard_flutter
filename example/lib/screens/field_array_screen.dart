import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:zard/zard.dart';
import 'package:zard_flutter/hooks.dart';
import 'package:zard_flutter/zard_flutter.dart';

import '../shared/screen_scaffold.dart';

/// Screen 5 — dynamic list of fields with append/prepend/insert/remove/swap/move/replace.
/// Children are keyed by `row.id` so reorders preserve widget state.
class FieldArrayScreen extends HookWidget {
  const FieldArrayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final form = useForm(
      schema: z.map({
        'skills': z.list(z.string().min(1, message: 'Required')),
      }),
      defaultValues: const {
        'skills': ['Dart', 'Flutter'],
      },
      mode: ValidationMode.onChange,
    );
    final skills = useFieldArray<String>('skills', form: form);
    final submitted = useState<Map<String, dynamic>?>(null);

    return ScreenScaffold(
      title: 'Field Array',
      description:
          'append / prepend / insert / remove / swap / move / replace. '
          'Each row carries a stable id used as the widget key.',
      child: ZardForm(
        form: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < skills.rows.value.length; i++)
              Padding(
                key: ValueKey(skills.rows.value[i].id),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: ZardInput(
                        name: 'skills.$i',
                        label: 'Skill #${i + 1}',
                      ),
                    ),
                    IconButton(
                      tooltip: 'Up',
                      icon: const Icon(Icons.arrow_upward),
                      onPressed: i == 0 ? null : () => skills.move(i, i - 1),
                    ),
                    IconButton(
                      tooltip: 'Down',
                      icon: const Icon(Icons.arrow_downward),
                      onPressed: i == skills.rows.value.length - 1
                          ? null
                          : () => skills.move(i, i + 1),
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => skills.remove(i),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => skills.append(''),
                  icon: const Icon(Icons.add),
                  label: const Text('Append'),
                ),
                OutlinedButton(
                  onPressed: () => skills.prepend(''),
                  child: const Text('Prepend'),
                ),
                OutlinedButton(
                  onPressed: () => skills.insert(1, ''),
                  child: const Text('Insert @1'),
                ),
                OutlinedButton(
                  onPressed: skills.rows.value.length >= 2
                      ? () => skills.swap(0, skills.rows.value.length - 1)
                      : null,
                  child: const Text('Swap first ↔ last'),
                ),
                OutlinedButton(
                  onPressed: () =>
                      skills.replace(['React', 'Vue', 'Svelte']),
                  child: const Text('Replace (React/Vue/Svelte)'),
                ),
              ],
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
