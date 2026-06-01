import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:zard/zard.dart';
import 'package:zard_flutter/hooks.dart';
import 'package:zard_flutter/zard_flutter.dart';

import '../shared/screen_scaffold.dart';

/// Screen 4 — async per-field validation via `registerAsyncValidator`.
/// Simulates a username-uniqueness check against a fake server.
class AsyncValidationScreen extends HookWidget {
  const AsyncValidationScreen({super.key});

  static const _taken = {'admin', 'root', 'flutter', 'zard'};

  @override
  Widget build(BuildContext context) {
    final form = useForm(
      schema: z.map({
        'username': z.string().min(3, message: 'Min 3 characters'),
      }),
      defaultValues: const {'username': ''},
      mode: ValidationMode.onChange,
      asyncValidation: true,
    );

    useEffect(() {
      form.registerAsyncValidator(
        'username',
        (value, _) async {
          if (value is! String || value.length < 3) return null;
          await Future.delayed(const Duration(milliseconds: 600));
          return _taken.contains(value.toLowerCase())
              ? '"$value" is already taken'
              : null;
        },
        debounce: const Duration(milliseconds: 400),
      );
      return null;
    }, [form]);

    final submitted = useState<Map<String, dynamic>?>(null);

    return ScreenScaffold(
      title: 'Async Validation',
      description:
          'Type a username. Names like "admin", "root", "flutter", "zard" are taken. '
          'A spinner appears while the (fake) server check runs.',
      child: ZardForm(
        form: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ZardInput(
              name: 'username',
              label: 'Username',
              placeholder: 'Try "admin"',
              loadingBuilder: (_) => const Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ZardButton(
              loading: form.isSubmitting,
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
