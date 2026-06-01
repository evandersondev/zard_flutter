import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:zard/zard.dart';
import 'package:zard_flutter/hooks.dart';
import 'package:zard_flutter/zard_flutter.dart';

import '../shared/screen_scaffold.dart';

/// Screen 12 — multi-step wizard. Use `trigger(path)` between steps to gate
/// progression.
class MultiStepScreen extends HookWidget {
  const MultiStepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final step = useState(0);
    final form = useForm(
      schema: z.map({
        'name': z.string().min(2, message: 'Name required'),
        'email': z.string().email(message: 'Valid email required'),
        'plan': z.string(),
      }),
      defaultValues: const {'name': '', 'email': '', 'plan': 'free'},
      mode: ValidationMode.onTouched,
    );
    final submitted = useState<Map<String, dynamic>?>(null);

    Widget stepBody() {
      switch (step.value) {
        case 0:
          return const ZardInput(name: 'name', label: 'Name');
        case 1:
          return const ZardInput(name: 'email', label: 'Email');
        default:
          return const ZardSelect<String>(
            name: 'plan',
            label: 'Plan',
            options: [
              ZardSelectOption(value: 'free', label: 'Free'),
              ZardSelectOption(value: 'pro', label: 'Pro'),
              ZardSelectOption(value: 'team', label: 'Team'),
            ],
          );
      }
    }

    Future<void> next() async {
      final pathByStep = ['name', 'email', 'plan'];
      final ok = await form.trigger(pathByStep[step.value]);
      if (!ok) return;
      if (step.value == 2) {
        await form.submit((data) async {
          submitted.value = data;
        });
      } else {
        step.value++;
      }
    }

    return ScreenScaffold(
      title: 'Multi-Step Wizard',
      description:
          'trigger(path) validates only the current step. The Next button is '
          'disabled while validation runs.',
      child: ZardForm(
        form: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: (step.value + 1) / 3),
            const SizedBox(height: 16),
            stepBody(),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton(
                  onPressed: step.value == 0
                      ? null
                      : () => step.value--,
                  child: const Text('Back'),
                ),
                const Spacer(),
                ZardButton(
                  loading: form.isValidating || form.isSubmitting,
                  onPressed: next,
                  child: Text(step.value == 2 ? 'Submit' : 'Next'),
                ),
              ],
            ),
            SubmitResult(payload: submitted.value),
          ],
        ),
      ),
    );
  }
}
