import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:zard/zard.dart';
import 'package:zard_flutter/hooks.dart';
import 'package:zard_flutter/zard_flutter.dart';

import '../shared/screen_scaffold.dart';

class _UserModel {
  const _UserModel({required this.name, required this.email});
  final String name;
  final String email;
  @override
  String toString() => 'UserModel(name: "$name", email: "$email")';
}

/// Screen 10 — typed output via transformTyped. Submission returns a typed
/// model directly.
class TransformTypedScreen extends HookWidget {
  const TransformTypedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final form = useForm(
      schema: z.map({
        'name': z.string().min(2).transform(
              (value) => value.toUpperCase(),
            ),
        'email': z.string().email(),
      }),
      defaultValues: const {'name': '', 'email': ''},
    );
    final submitted = useState<_UserModel?>(null);
    return ScreenScaffold(
      title: 'Transform & Typed',
      description:
          'Map the raw form payload into a typed Dart model after validation.',
      child: ZardForm(
        form: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ZardInput(name: 'name', label: 'Name'),
            const SizedBox(height: 12),
            const ZardInput(name: 'email', label: 'Email'),
            const SizedBox(height: 16),
            ZardButton(
              onPressed: form.handleSubmit((data) async {
                submitted.value = _UserModel(
                  name: data['name'] as String,
                  email: data['email'] as String,
                );
              }),
              child: const Text('Submit'),
            ),
            if (submitted.value != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Typed: ${submitted.value}',
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
