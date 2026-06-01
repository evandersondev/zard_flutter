import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:zard/zard.dart';
import 'package:zard_flutter/hooks.dart';
import 'package:zard_flutter/zard_flutter.dart';

import '../shared/screen_scaffold.dart';

/// Screen 11 — Radix/shadcn-style composition with ZardField + ZardLabel +
/// ZardInput + ZardDescription + ZardErrorMessage.
class RadixCompositionScreen extends HookWidget {
  const RadixCompositionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final form = useForm(
      schema: z.map({
        'email': z.string().email(message: 'Enter a valid email'),
      }),
      defaultValues: const {'email': ''},
      mode: ValidationMode.onTouched,
    );
    return ScreenScaffold(
      title: 'Radix-style Composition',
      description:
          'Compose a field manually: Label + Input + Description + ErrorMessage. '
          'No name re-binding needed — they pick up the surrounding ZardField.',
      child: ZardForm(
        form: form,
        child: const ZardField<String>(
          name: 'email',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ZardLabel(
                'Email',
                requiredMarker: Text(' *',
                    style: TextStyle(color: Color(0xFFB91C1C))),
              ),
              SizedBox(height: 4),
              ZardInput(placeholder: 'you@example.com'),
              ZardDescription('We never share your email.'),
              ZardErrorMessage(),
            ],
          ),
        ),
      ),
    );
  }
}
