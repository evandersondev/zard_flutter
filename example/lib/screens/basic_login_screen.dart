import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:zard/zard.dart';
import 'package:zard_flutter/hooks.dart';
import 'package:zard_flutter/zard_flutter.dart';

import '../shared/screen_scaffold.dart';

/// Screen 1 — basic email/password login form. Demonstrates the canonical
/// `useForm` + `ZardForm` + `ZardInput` flow side-by-side with the
/// controller-only flow (no flutter_hooks dependency).
class BasicLoginScreen extends StatelessWidget {
  const BasicLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScreenScaffold(
      title: 'Basic Login',
      description:
          'Email + password. Hook style on top, controller style below.',
      child: Column(
        children: [
          _HookForm(),
          SizedBox(height: 32),
          Divider(),
          SizedBox(height: 16),
          _ControllerForm(),
        ],
      ),
    );
  }
}

final _loginSchema = z.map({
  'email': z.string().email(message: 'Enter a valid email'),
  'password': z.string().min(6, message: 'At least 6 characters'),
});

class _HookForm extends HookWidget {
  const _HookForm();

  @override
  Widget build(BuildContext context) {
    final form = useForm(
      schema: _loginSchema,
      // defaultValues: const {'email': '', 'password': ''},
      mode: ValidationMode.onTouched,
    );

    final submitted = useState<Map<String, dynamic>?>(null);

    return ZardForm(
      form: form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Hook style (useForm)',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          const ZardInput(
            name: 'email',
            label: 'Email',
            placeholder: 'you@example.com',
          ),
          const SizedBox(height: 12),
          const ZardInput(
            name: 'password',
            label: 'Password',
            obscureText: true,
          ),
          const SizedBox(height: 16),
          ZardButton(
            fullWidth: true,
            loading: form.isSubmitting,
            onPressed: form.handleSubmit((data) async {
              await Future.delayed(const Duration(milliseconds: 400));
              submitted.value = data;
            }),
            child: const Text('Sign in'),
          ),
          SubmitResult(payload: submitted.value),
        ],
      ),
    );
  }
}

class _ControllerForm extends StatefulWidget {
  const _ControllerForm();
  @override
  State<_ControllerForm> createState() => _ControllerFormState();
}

class _ControllerFormState extends State<_ControllerForm> {
  late final form = ZardFormController(
    schema: _loginSchema,
    defaultValues: const {'email': 'example@mail.com', 'password': ''},
    mode: ValidationMode.onTouched,
  );
  Map<String, dynamic>? _submitted;

  @override
  void dispose() {
    form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ZardForm(
      form: form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Controller style',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          const ZardInput(
            name: 'email',
            label: 'Email',
            placeholder: 'you@example.com',
          ),
          const SizedBox(height: 12),
          const ZardInput(
            name: 'password',
            label: 'Password',
            obscureText: true,
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: form,
            builder: (ctx, _) => ZardButton(
              fullWidth: true,
              loading: form.isSubmitting,
              onPressed: form.handleSubmit((data) async {
                await Future.delayed(const Duration(milliseconds: 400));
                setState(() => _submitted = data);
              }),
              child: const Text('Sign in'),
            ),
          ),
          SubmitResult(payload: _submitted),
          ZardDevtools(form: form, collapsed: true),
        ],
      ),
    );
  }
}
