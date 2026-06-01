import 'package:flutter/material.dart';
import 'package:zard/zard.dart';
import 'package:zard_flutter/zard_flutter.dart';

import '../shared/screen_scaffold.dart';

/// Screen 3 — toggle the four validation modes and observe behavior live.
class ValidationModesScreen extends StatefulWidget {
  const ValidationModesScreen({super.key});
  @override
  State<ValidationModesScreen> createState() => _ValidationModesScreenState();
}

class _ValidationModesScreenState extends State<ValidationModesScreen> {
  ValidationMode _mode = ValidationMode.onSubmit;
  RevalidateMode _revalidate = RevalidateMode.onChange;
  ZardFormController? _form;

  void _rebuildForm() {
    _form?.dispose();
    _form = ZardFormController(
      schema: z.map({'email': z.string().email(message: 'Bad email')}),
      defaultValues: const {'email': ''},
      mode: _mode,
      revalidateMode: _revalidate,
    );
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _rebuildForm();
  }

  @override
  void dispose() {
    _form?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Validation Modes',
      description:
          'Pick a mode below — the form is recreated so you can compare behavior. '
          'For onTouched/onBlur, tab focus away from the field. For onSubmit, hit submit.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<ValidationMode>(
            initialValue: _mode,
            decoration: const InputDecoration(labelText: 'mode'),
            items: ValidationMode.values
                .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                .toList(),
            onChanged: (m) {
              if (m == null) return;
              _mode = m;
              _rebuildForm();
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<RevalidateMode>(
            initialValue: _revalidate,
            decoration: const InputDecoration(labelText: 'revalidateMode'),
            items: RevalidateMode.values
                .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                .toList(),
            onChanged: (m) {
              if (m == null) return;
              _revalidate = m;
              _rebuildForm();
            },
          ),
          const SizedBox(height: 24),
          if (_form != null)
            ZardForm(
              form: _form!,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ZardField<String>(
                    name: 'email',
                    child: ZardInput(label: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  ZardButton(
                    onPressed: _form!.handleSubmit((_) async {}),
                    child: const Text('Submit'),
                  ),
                  ZardDevtools(form: _form!),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
