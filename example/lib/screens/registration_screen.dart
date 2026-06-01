import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:zard/zard.dart';
import 'package:zard_flutter/hooks.dart';
import 'package:zard_flutter/zard_flutter.dart';

import '../shared/screen_scaffold.dart';

final _schema = z.map({
  'name': z.string().min(2, message: 'Name too short'),
  'email': z.string().email(message: 'Invalid email'),
  'password': z.string().min(6, message: 'At least 6 characters'),
  'confirm': z.string().min(6, message: 'At least 6 characters'),
  'acceptTerms': z.bool(),
}).refine(
  (data) => data['password'] == data['confirm'],
  message: 'Passwords must match',
);

/// Screen 2 — multi-field registration form with cross-field refinement
/// (passwords must match).
class RegistrationScreen extends HookWidget {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final form = useForm(
      schema: _schema,
      defaultValues: const {
        'name': '',
        'email': '',
        'password': '',
        'confirm': '',
        'acceptTerms': false,
      },
      mode: ValidationMode.onTouched,
    );
    final submitted = useState<Map<String, dynamic>?>(null);

    return ScreenScaffold(
      title: 'Registration',
      description:
          'Multi-field form with cross-field refine + boolean acceptance.',
      child: ZardForm(
        form: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ZardField<String>(
              name: 'name',
              child: ZardInput(label: 'Name', placeholder: 'Ada Lovelace'),
            ),
            const SizedBox(height: 12),
            const ZardField<String>(
              name: 'email',
              child: ZardInput(label: 'Email'),
            ),
            const SizedBox(height: 12),
            const ZardField<String>(
              name: 'password',
              child: ZardInput(label: 'Password', obscureText: true),
            ),
            const SizedBox(height: 12),
            const ZardField<String>(
              name: 'confirm',
              child: ZardInput(label: 'Confirm password', obscureText: true),
            ),
            const SizedBox(height: 12),
            const ZardField<bool>(
              name: 'acceptTerms',
              defaultValue: false,
              child: ZardCheckbox(label: 'I accept the terms'),
            ),
            AnimatedBuilder(
              animation: form,
              builder: (ctx, _) {
                if (form.formErrors.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    form.formErrors.first,
                    style: const TextStyle(color: Color(0xFFB91C1C)),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            ZardButton(
              fullWidth: true,
              loading: form.isSubmitting,
              onPressed: form.handleSubmit((data) async {
                await Future.delayed(const Duration(milliseconds: 400));
                submitted.value = data;
              }),
              child: const Text('Create account'),
            ),
            SubmitResult(payload: submitted.value),
          ],
        ),
      ),
    );
  }
}
