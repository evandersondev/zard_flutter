import 'package:flutter/material.dart';

import 'screens/async_validation_screen.dart';
import 'screens/basic_login_screen.dart';
import 'screens/conditional_fields_screen.dart';
import 'screens/custom_widget_screen.dart';
import 'screens/defaults_reset_screen.dart';
import 'screens/devtools_showcase_screen.dart';
import 'screens/field_array_screen.dart';
import 'screens/manual_errors_screen.dart';
import 'screens/multi_step_screen.dart';
import 'screens/nested_paths_screen.dart';
import 'screens/radix_composition_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/transform_typed_screen.dart';
import 'screens/validation_modes_screen.dart';
import 'screens/watch_form_state_screen.dart';

void main() => runApp(const ZardFlutterDemo());

class ZardFlutterDemo extends StatelessWidget {
  const ZardFlutterDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'zard_flutter showcase',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6366F1)),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const _HomeScreen(),
    );
  }
}

class _DemoEntry {
  const _DemoEntry(this.title, this.subtitle, this.builder);
  final String title;
  final String subtitle;
  final WidgetBuilder builder;
}

final _entries = <_DemoEntry>[
  _DemoEntry('Basic Login', 'email + password, hook + controller styles',
      (_) => const BasicLoginScreen()),
  _DemoEntry('Registration', 'cross-field refine, password match',
      (_) => RegistrationScreen()),
  _DemoEntry('Validation Modes', 'onChange / onBlur / onSubmit / onTouched',
      (_) => const ValidationModesScreen()),
  _DemoEntry('Async Validation', 'registerAsyncValidator with debounce',
      (_) => const AsyncValidationScreen()),
  _DemoEntry('Field Array', 'append/prepend/insert/remove/swap/move/replace',
      (_) => const FieldArrayScreen()),
  _DemoEntry('Nested Paths', 'user.address.street paths',
      (_) => const NestedPathsScreen()),
  _DemoEntry('Defaults & Reset', 'reset, keepDirty / keepErrors',
      (_) => const DefaultsResetScreen()),
  _DemoEntry('Manual Errors', 'setError / clearErrors / trigger',
      (_) => const ManualErrorsScreen()),
  _DemoEntry('Watch & FormState', 'granular subscriptions + rebuild counts',
      (_) => const WatchFormStateScreen()),
  _DemoEntry('Transform & Typed', 'typed model from form data',
      (_) => const TransformTypedScreen()),
  _DemoEntry('Radix-style Composition', 'Label + Input + Description + Error',
      (_) => const RadixCompositionScreen()),
  _DemoEntry('Multi-Step Wizard', 'trigger(path) between steps',
      (_) => const MultiStepScreen()),
  _DemoEntry('Conditional Fields', 'ZardWatch show/hide',
      (_) => const ConditionalFieldsScreen()),
  _DemoEntry('Custom Widget (Slider)', 'ZardField.builder for any widget',
      (_) => const CustomWidgetScreen()),
  _DemoEntry('DevTools Showcase', 'every widget + live state inspection',
      (_) => const DevtoolsShowcaseScreen()),
];

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('zard_flutter showcase')),
      body: ListView.separated(
        itemCount: _entries.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final e = _entries[i];
          return ListTile(
            leading: CircleAvatar(child: Text('${i + 1}')),
            title: Text(e.title),
            subtitle: Text(e.subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(ctx).push(
              MaterialPageRoute(builder: e.builder),
            ),
          );
        },
      ),
    );
  }
}
