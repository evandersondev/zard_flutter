<p align="center">
  <img src="./assets/logo.png" width="200px" align="center" alt="Zard Flutter logo" />
<h1 align="center">Zard Flutter</h1>
<br>
<p align="center">
Reactive, headless-first forms for Flutter — powered by <a href="https://github.com/evandersondev/zard">Zard</a> schemas.
<br/>
<b>Zod + React Hook Form</b> ergonomics, native to Flutter. Your schema is the single source of truth for validation, transformation, and types.
<br/><br/>
🇧🇷 <a href="https://github.com/evandersondev/zard_flutter/blob/main/README.pt-br.md">Documentação em Português (pt-BR)</a>
</p>
</p>

<br/>

### Support 💖

If you find Zard Flutter useful, please consider supporting its development 🌟 [Buy Me a Coffee](https://buymeacoffee.com/evandersondev) 🌟. Your support helps us improve the framework and make it even better!

<br/>

## Why Zard Flutter 🤔

Zard already gives you schemas, validation, transforms, and typed output. **Zard Flutter** adds the Flutter layer on top: form state, per-field state, granular reactivity, and a set of widgets to bind it all to your UI — without forcing a particular look.

- **Headless-first** — `ZardForm` / `ZardField` carry behavior, not pixels. Drop in your own widgets, or use the included Material set.
- **Granular subscriptions** — per-field listeners mean typing in one field doesn't rebuild the others.
- **One schema, everywhere** — validation, async checks, transforms, and typed output all come from your Zard schema.
- **Nested paths & field arrays** — `user.address.street`, dynamic lists with stable row IDs.
- **Async validation** — debounced, per-field, with loading indicators.
- **Hooks are optional** — use the `useForm` hook style, or plain `ZardFormController` with no `flutter_hooks` dependency.

---

## Installation 📦

```yaml
dependencies:
  zard: ^1.1.2
  zard_flutter: ^1.0.0-beta.1

  # Optional — only needed if you use the hooks layer (`package:zard_flutter/hooks.dart`).
  flutter_hooks: ^0.20.5
```

```sh
flutter pub get
```

Imports you'll use:

```dart
import 'package:zard/zard.dart';                  // z.map, z.string, ...
import 'package:zard_flutter/zard_flutter.dart';  // ZardForm, ZardField, ZardInput, ...
import 'package:zard_flutter/hooks.dart';         // useForm, useWatch, ... (optional)
```

---

## Quick start 🚀

A minimal login form, end to end:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:zard/zard.dart';
import 'package:zard_flutter/hooks.dart';
import 'package:zard_flutter/zard_flutter.dart';

final _loginSchema = z.map({
  'email': z.string().email(message: 'Enter a valid email'),
  'password': z.string().min(6, message: 'At least 6 characters'),
});

class LoginScreen extends HookWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final form = useForm(
      schema: _loginSchema,
      defaultValues: const {'email': '', 'password': ''},
      mode: ValidationMode.onTouched,
    );

    return ZardForm(
      form: form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The Material widgets bind themselves — just pass `name:`.
          const ZardInput(name: 'email', label: 'Email', placeholder: 'you@example.com'),
          const SizedBox(height: 12),
          const ZardInput(name: 'password', label: 'Password', obscureText: true),
          const SizedBox(height: 16),
          ZardButton(
            fullWidth: true,
            loading: form.isSubmitting,
            onPressed: form.handleSubmit((data) async {
              await Future.delayed(const Duration(milliseconds: 400));
              debugPrint('Submitted: $data');
            }),
            child: const Text('Sign in'),
          ),
        ],
      ),
    );
  }
}
```

That's the whole loop: **schema → `ZardForm` → a widget with `name:` → `handleSubmit`**.

> ℹ️ **`ZardField` is optional.** The Material widgets (`ZardInput`, `ZardCheckbox`,
> `ZardSwitch`, `ZardSelect`, `ZardRadioGroup`) resolve their own field when you give them a
> `name:` — no wrapper needed. You only reach for `ZardField` to *compose* several widgets
> around one field, to wire a custom/non-Material widget, or to bind a non-`String` type. See
> [ZardField — when you actually need it](#zardfield--when-you-actually-need-it).

---

## Two ways to create a form 🪝

### Hook style — `useForm`

```dart
class MyForm extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final form = useForm(schema: _schema, mode: ValidationMode.onTouched);
    return ZardForm(form: form, child: /* ... */);
  }
}
```

`useForm` creates the controller, disposes it automatically on unmount, and subscribes the
widget to form-level changes.

> ⚠️ **Hooks must be called inside `build()`.** Calling `useForm` / `useState` as a *field
> initializer* throws `Hooks can only be called from the build method`. Always declare them as
> locals at the top of `build`:
>
> ```dart
> // ❌ WRONG — runs when the object is constructed, outside build
> class MyForm extends HookWidget {
>   final form = useForm(schema: _schema); // throws!
> }
>
> // ✅ RIGHT — inside build
> class MyForm extends HookWidget {
>   @override
>   Widget build(BuildContext context) {
>     final form = useForm(schema: _schema);
>     ...
>   }
> }
> ```

### Controller style — `ZardFormController` (no hooks)

If you don't want `flutter_hooks`, own the controller in a `StatefulWidget`:

```dart
class MyForm extends StatefulWidget {
  const MyForm({super.key});
  @override
  State<MyForm> createState() => _MyFormState();
}

class _MyFormState extends State<MyForm> {
  late final form = ZardFormController(
    schema: _schema,
    defaultValues: const {'email': '', 'password': ''},
    mode: ValidationMode.onTouched,
  );

  @override
  void dispose() {
    form.dispose(); // you own the lifecycle here
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ZardForm(form: form, child: /* ... */);
  }
}
```

Wrap any reactive part (like a submit button) in `AnimatedBuilder(animation: form, ...)` to
rebuild it on form-level changes.

---

## Core concepts 🧠

### `ZardForm`

Provides the controller to descendants via context. Two modes:

```dart
// 1. Bring your own controller (hook or StatefulWidget)
ZardForm(form: form, child: ...);

// 2. Let ZardForm create + dispose one from a schema
ZardForm(schema: _schema, defaultValues: const {...}, child: ...);

// 3. Builder form — get the controller in the callback
ZardForm.builder(
  schema: _schema,
  builder: (context, form) => ...,
);
```

### `ZardField` — when you actually need it

Every Material widget in this package can bind itself directly. **For a single field, skip
`ZardField` entirely** and just pass `name:`:

```dart
// ✅ The common case — one widget, no wrapper
const ZardInput(name: 'email', label: 'Email'),
const ZardCheckbox(name: 'acceptTerms', label: 'I accept the terms'),
const ZardSelect<String>(name: 'role', options: [...]),
```

`ZardField<T>` is the **headless binder** underneath. It registers a field at `name` and exposes
its controller to the *whole subtree* via context. Reach for it in three cases:

**1. Compose several widgets around one field** — declare `name` once; the children read it from
context (this is what `ZardLabel` / `ZardErrorMessage` / `ZardDescription` need):

```dart
ZardField<String>(
  name: 'email',
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: const [
      ZardLabel('Email'),
      ZardInput(),         // no name — inherited from ZardField
      ZardErrorMessage(),  // no name — inherited from ZardField
    ],
  ),
);
```

**2. Wire a custom / non-Material widget** with `ZardField.builder`:

```dart
ZardField<double>.builder(
  name: 'volume',
  defaultValue: 50,
  builder: (ctx, field, state) => Slider(
    value: state.value ?? 0,
    min: 0,
    max: 100,
    onChanged: state.disabled ? null : (v) => field.setValue(v),
  ),
);
```

**3. Bind a non-`String` type** — `ZardInput` is `String`-only; `ZardField<T>` is generic.

> 💡 Need a per-field default? `ZardField` takes `defaultValue:` / `disabled:`. The bare
> `ZardInput(name:)` form has no `defaultValue` — seed it from the form's `defaultValues:`
> instead (which is the recommended place for initial values anyway).

### `ZardFieldController` / `ZardFieldState`

Each field owns a controller exposing a `ValueListenable<ZardFieldState<T>>`. The state is an
immutable snapshot:

```dart
state.value        // current value
state.errors       // List<String>
state.error        // first error or null
state.hasError     // bool
state.isTouched    // bool
state.isDirty      // bool
state.isValidating // bool (async validation in progress)
state.disabled     // bool
```

From the controller you can `setValue`, `setTouched`, `setErrors`, `setDisabled`, and (for
string fields) access a lazily-allocated `textController` / `focusNode`.

---

## Validation ✅

### When does it run? `ValidationMode` + `RevalidateMode`

`mode` controls when a field is validated for the **first** time; `revalidateMode` controls
when an already-errored field is re-checked as the user fixes it.

```dart
final form = ZardFormController(
  schema: _schema,
  mode: ValidationMode.onTouched,        // see table below
  revalidateMode: RevalidateMode.onChange,
);
```

| `ValidationMode` | Validates… |
| --- | --- |
| `onSubmit` (default) | only when the form is submitted |
| `onChange` | on every change (most aggressive) |
| `onBlur` | when a field loses focus |
| `onTouched` | after a field has been touched once |
| `all` | on every change *and* blur |

| `RevalidateMode` | After an error, re-validates… |
| --- | --- |
| `onChange` (default) | on every change |
| `onBlur` | on blur |
| `onSubmit` | only on the next submit |

### Cross-field rules with `.refine()`

Refinements live on the schema. Their errors surface as **form-level** errors:

```dart
final _schema = z.map({
  'password': z.string().min(6),
  'confirm': z.string().min(6),
}).refine(
  (data) => data['password'] == data['confirm'],
  message: 'Passwords must match',
);

// Show them in the UI:
AnimatedBuilder(
  animation: form,
  builder: (ctx, _) {
    if (form.formErrors.isEmpty) return const SizedBox.shrink();
    return Text(form.formErrors.first,
        style: const TextStyle(color: Color(0xFFB91C1C)));
  },
);
```

### Manual control: `setError`, `clearErrors`, `trigger`

```dart
form.setError('email', 'Email already exists'); // push a server error onto a field
form.clearErrors('email');                       // clear one field
form.clearErrors();                              // clear everything

final emailOk = await form.trigger('email');     // validate one path
final formOk  = await form.trigger();            // validate the whole form
```

### Async validation

Enable the async pipeline and register per-field validators (debounced). Return `null` when
valid, or an error message when not:

```dart
final form = useForm(
  schema: z.map({'username': z.string().min(3)}),
  mode: ValidationMode.onChange,
  asyncValidation: true,
);

form.registerAsyncValidator(
  'username',
  (value, allValues) async {
    if (value is! String || value.length < 3) return null;
    await Future.delayed(const Duration(milliseconds: 600));
    return _takenUsernames.contains(value) ? '"$value" is already taken' : null;
  },
  debounce: const Duration(milliseconds: 400),
);
```

`ZardInput` shows a spinner during async validation — customize it with `loadingBuilder`:

```dart
ZardInput(
  label: 'Username',
  loadingBuilder: (_) => const SizedBox(
    width: 16, height: 16,
    child: CircularProgressIndicator(strokeWidth: 2),
  ),
);
```

---

## Submitting 📤

`handleSubmit` returns a `VoidCallback` ready for `onPressed:`. It validates, then calls
`onValid` (with the parsed/transformed values) or the optional `onInvalid`:

```dart
ZardButton(
  loading: form.isSubmitting,
  onPressed: form.handleSubmit(
    (values) async {
      await api.createUser(values);
    },
    onInvalid: (errors) {
      debugPrint('Blocked by: $errors');
    },
  ),
  child: const Text('Create account'),
);
```

Prefer to `await` the flow yourself? Use `form.submit(onValid, onInvalid:)`. Read
`form.isSubmitting` / `form.submitCount` for UI state.

Because the values handed to `onValid` are the schema's **parsed** output, you can map them
straight onto a typed model:

```dart
class User {
  const User({required this.name, required this.email});
  final String name;
  final String email;
}

onPressed: form.handleSubmit((data) async {
  final user = User(name: data['name'] as String, email: data['email'] as String);
  // ...
});
```

---

## Watching values — and avoiding unwanted rebuilds 🔁

This is the part that surprises people, so it's worth understanding the model.

### How reactivity works

`ZardFormController` is a `ChangeNotifier`. There are **two** levels of subscription:

- **Per-field** — each field has its own `ZardFieldController` (a
  `ValueListenable<ZardFieldState>`). Widgets like `ZardInput` and `ZardField` listen to *their
  own* field, so typing in one field rebuilds only that field's subtree.
- **Form-level** — the controller itself calls `notifyListeners()` on a range of events:
  `setValue`, submit start/end, validation start/end, field register/unregister, and error
  changes. Anything subscribed to the *whole form* rebuilds on any of these.

### What subscribes to the whole form

These rebuild on **every** form-level notification (including each keystroke, since `setValue`
notifies):

- `useForm(...)` — it subscribes the host widget (via `useListenable`) so `form.isSubmitting`,
  `form.isValid`, etc. stay live.
- `AnimatedBuilder(animation: form, ...)`
- `ZardFormScope.of(context, listen: true)`
- `ZardWatchAll(builder: ...)`

### Why this is usually fine

A `useForm` widget re-running `build` is **not** the same as rebuilding the whole tree. Keep
your field subtrees `const`:

```dart
const ZardInput(name: 'email', label: 'Email'),
```

When the parent rebuilds, Flutter sees the identical `const` widget and **skips** that subtree.
The inputs still reflect typing because they listen to their own field listenable — not the
parent's rebuild. So in practice a `useForm` screen made of `const` fields is cheap.

### The toolbox to minimize rebuilds

Reach for these when a rebuild actually shows up on a profiler:

- **`ZardWatch<T>(name:)`** — rebuild only when a single field's value changes:

  ```dart
  ZardWatch<String>(
    name: 'first',
    builder: (ctx, value) => Text('Hello, ${value ?? ''}'),
  );
  ```

- **`useWatch<T>(name)`** — the hook form of the same single-field subscription.

- **`useFormState(listen:)`** — subscribe only to the form flags you care about:

  ```dart
  final s = useFormState(listen: (snap) => [snap.isValid, snap.isDirty]);
  // rebuilds only when isValid or isDirty flips
  ```

- **Scope `AnimatedBuilder` tightly** — wrap *just* the submit button, not the whole screen:

  ```dart
  AnimatedBuilder(
    animation: form,
    builder: (ctx, _) => ZardButton(loading: form.isSubmitting, ...),
  );
  ```

- **Use the controller without subscribing** — with the `ZardFormController` (no-hooks) style,
  read the controller directly and only wrap the reactive bits, so the screen itself never
  subscribes to the whole form.

### Before / after

```dart
// ⚠️ Everything in this screen re-runs build on each keystroke (still cheap if fields are const,
// but the surrounding non-const widgets all rebuild too).
class Screen extends HookWidget {
  Widget build(context) {
    final form = useForm(schema: _schema);
    return ExpensiveLayout(form: form); // non-const → rebuilds every notify
  }
}

// ✅ Only the button rebuilds on form changes; the heavy layout is built once.
class Screen extends StatefulWidget { ... }
class _ScreenState extends State<Screen> {
  late final form = ZardFormController(schema: _schema);
  Widget build(context) => ZardForm(
    form: form,
    child: const ExpensiveLayout( // const → built once
      submitButton: _ReactiveSubmit(), // wraps AnimatedBuilder internally
    ),
  );
}
```

> 💡 Want to *see* it? The **Watch & FormState** example screen renders live rebuild counters
> next to `ZardWatch`, `ZardWatchAll`, and `useFormState` so you can watch exactly which
> subscribers re-render as you type.

---

## Default values & reset ♻️

```dart
final form = useForm(
  schema: _schema,
  defaultValues: const {'email': 'default@zard.dev', 'nickname': 'guest'},
);

form.reset();                                   // back to defaultValues
form.reset(values: const {'email': 'new@x.dev'}); // new baseline
form.reset(keepDirty: true);                     // keep dirty flags
form.reset(keepErrors: true);                    // keep current errors
form.reset(keepTouched: true);                   // keep touched flags
```

---

## Nested paths 🌳

Use dot notation for nested objects — errors land on the right nested field:

```dart
final _schema = z.map({
  'user': z.map({
    'name': z.string().min(2),
    'address': z.map({
      'street': z.string().min(3),
      'city': z.string().min(2),
    }),
  }),
});

const ZardInput(name: 'user.name',           label: 'Name'),
const ZardInput(name: 'user.address.street', label: 'Street'),
const ZardInput(name: 'user.address.city',   label: 'City'),
```

---

## Field arrays 📚

Manage dynamic lists with stable row IDs (use the `id` as the widget `key` so state survives
reorders):

```dart
final form = useForm(
  schema: z.map({'skills': z.list(z.string().min(1))}),
  defaultValues: const {'skills': ['Dart', 'Flutter']},
  mode: ValidationMode.onChange,
);
final skills = useFieldArray<String>('skills', form: form);

// Render rows — bind each with `skills.$i`
for (var i = 0; i < skills.rows.value.length; i++)
  Row(
    key: ValueKey(skills.rows.value[i].id),
    children: [
      Expanded(
        child: ZardInput(name: 'skills.$i', label: 'Skill #${i + 1}'),
      ),
      IconButton(
        icon: const Icon(Icons.arrow_upward),
        onPressed: i == 0 ? null : () => skills.move(i, i - 1),
      ),
      IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () => skills.remove(i),
      ),
    ],
  ),

OutlinedButton.icon(
  onPressed: () => skills.append(''),
  icon: const Icon(Icons.add),
  label: const Text('Add skill'),
),
```

Available operations: `append`, `prepend`, `insert`, `remove`, `swap`, `move`, `replace`,
`update`. Without hooks, call `form.useFieldArray<E>('skills')` directly.

---

## Conditional fields 🔀

Use `ZardWatch` to show/hide fields based on another field's value (pair with `.optional()` in
the schema):

```dart
final _schema = z.map({
  'subscribe': z.bool(),
  'email': z.string().optional(),
});

const ZardCheckbox(name: 'subscribe', label: 'Subscribe to newsletter'),
ZardWatch<bool>(
  name: 'subscribe',
  builder: (ctx, on) => on == true
      ? const ZardInput(name: 'email', label: 'Email')
      : const SizedBox.shrink(),
),
```

---

## Multi-step wizards 🧭

Gate each step with `trigger(path)` — validate just the current step before advancing:

```dart
final step = useState(0);
final form = useForm(schema: _schema, mode: ValidationMode.onTouched);

Future<void> next() async {
  const pathByStep = ['name', 'email', 'plan'];
  final ok = await form.trigger(pathByStep[step.value]);
  if (!ok) return;
  if (step.value == 2) {
    await form.submit((data) async { /* finish */ });
  } else {
    step.value++;
  }
}

ZardButton(
  loading: form.isValidating || form.isSubmitting,
  onPressed: next,
  child: Text(step.value == 2 ? 'Submit' : 'Next'),
);
```

---

## Material widgets 🎨

Ready-made widgets that resolve their field from the surrounding `ZardField` (or take an
explicit `name:`).

| Widget | For | Highlights |
| --- | --- | --- |
| `ZardInput` | `String` | label, placeholder, helperText, obscureText, prefix/suffix, `loadingBuilder`, `errorBuilder` |
| `ZardTextarea` | `String` | multi-line variant (`minLines: 3`, `maxLines: 8`) |
| `ZardCheckbox` | `bool` | optional label, tristate |
| `ZardSwitch` | `bool` | optional label |
| `ZardSelect<T>` | `T` | `options: [ZardSelectOption(value:, label:)]` |
| `ZardRadioGroup<T>` | `T` | `options: [ZardRadioOption(value:, label:)]`, vertical/horizontal |
| `ZardButton` | — | `loading`, `fullWidth`, `icon`; pair with `handleSubmit` |

Kitchen-sink example — each binds itself with `name:`, no `ZardField` needed:

```dart
const ZardInput(name: 'name', label: 'Name'),
const ZardSelect<String>(
  name: 'role',
  label: 'Role',
  options: [
    ZardSelectOption(value: 'engineer', label: 'Engineer'),
    ZardSelectOption(value: 'designer', label: 'Designer'),
  ],
),
const ZardSwitch(name: 'newsletter', label: 'Subscribe to newsletter'),
const ZardRadioGroup<String>(
  name: 'tier',
  options: [
    ZardRadioOption(value: 'free', label: 'Free'),
    ZardRadioOption(value: 'pro', label: 'Pro'),
  ],
),
```

> Seed initial values (`role: 'engineer'`, `newsletter: false`, `tier: 'free'`, …) in the
> form's `defaultValues:`.

---

## Headless / Radix-style composition 🧩

Compose a field from small headless pieces. They pick up the surrounding `ZardField` context —
no need to repeat the `name`:

```dart
ZardField<String>(
  name: 'email',
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: const [
      ZardLabel('Email', requiredMarker: Text(' *', style: TextStyle(color: Color(0xFFB91C1C)))),
      SizedBox(height: 4),
      ZardInput(placeholder: 'you@example.com'),
      ZardDescription('We never share your email.'),
      ZardErrorMessage(),
    ],
  ),
);
```

Pieces: `ZardLabel`, `ZardDescription`, `ZardErrorMessage` (auto-bound, or pass `name:` /
`builder:`), and `ZardFormSection` for grouping with an optional title/description.

---

## Hooks reference 🪝

All hooks live in `package:zard_flutter/hooks.dart` (require `flutter_hooks`).

| Hook | Returns | Purpose |
| --- | --- | --- |
| `useForm({schema, defaultValues, mode, ...})` | `ZardFormController` | Create + own a form, subscribed to form-level state |
| `useController<T>(name, {form, defaultValue, disabled})` | `ZardFieldController<T>` | Register/resolve a field, subscribed to its state |
| `useFieldState<T>(name, {form})` | `ZardFieldState<T>` | Just the field's current state |
| `useWatch<T>(name, {form, defaultValue})` | `T?` | Reactive read of a single field value |
| `useFieldArray<E>(name, {form})` | `ZardFieldArray<E>` | Dynamic list management |
| `useFormState({form, listen})` | `ZardFormSnapshot` | Form-level flags; `listen:` limits rebuilds |
| `useZardFormContext()` | `ZardFormController` | Resolve the nearest form from context |

---

## DevTools 🐛

Drop a live inspection panel anywhere inside a form — values, errors, dirty/touched/disabled
flags, and a JSON dump:

```dart
ZardDevtools(form: form, collapsed: true);
```

---

## API reference 📖

### Core

| Name | Description |
| --- | --- |
| `ZardFormController` | The reactive form (`ChangeNotifier`) backed by a `ZMap` schema |
| `ZardFieldController<T>` | Per-field state, value, errors, optional text controller/focus node |
| `ZardFieldState<T>` | Immutable field snapshot (`value`, `errors`, `isTouched`, …) |
| `ZardFieldArray<E>` / `ZardFieldArrayRow<E>` | Dynamic list + stable-ID rows |
| `ValidationMode` / `RevalidateMode` | Enums controlling validation timing |
| `AsyncFieldValidator` | `Future<String?> Function(value, allValues)` typedef |
| `ZardFormScope` | `InheritedNotifier` exposing the controller (`of` / `maybeOf`) |
| path utils | `parsePath`, `canonicalizePath`, `readPath`, `writePath`, `removePath` |

### Headless widgets

| Name | Description |
| --- | --- |
| `ZardForm` / `ZardForm.builder` | Own or wrap a controller; provide it to descendants |
| `ZardField<T>` / `ZardField<T>.builder` | Bind a field at `name`; `.builder` wraps any widget |
| `ZardFieldBinding` | Inherited access to the field controller (`of` / `maybeOf`) |
| `ZardWatch<T>` | Rebuild on a single field's value change |
| `ZardWatchAll` | Rebuild on any form-level change |
| `ZardLabel` | Headless label (forwards taps to the field's focus node) |
| `ZardErrorMessage` | Shows field errors (context-bound or by `name:`) |
| `ZardDescription` | Helper/description text |
| `ZardFormSection` | Grouping with optional title/description |

### Material widgets

| Name | Description |
| --- | --- |
| `ZardInput` | Material `TextField` bound to a `String` field |
| `ZardTextarea` | Multi-line `ZardInput` |
| `ZardCheckbox` / `ZardSwitch` | `bool` fields |
| `ZardSelect<T>` / `ZardSelectOption<T>` | Dropdown |
| `ZardRadioGroup<T>` / `ZardRadioOption<T>` | Radio group |
| `ZardButton` | Elevated button with loading state |
| `ZardDevtools` | Live form-state inspector |

### Hooks

See the [Hooks reference](#hooks-reference-) table above.

---

## Running the example 🧪

The example app is a showcase of **15 screens** covering every feature in this README — basic
login, registration with cross-field refine, validation modes, async validation, field arrays,
nested paths, defaults/reset, manual errors, watch/form-state, transforms, Radix-style
composition, multi-step wizard, conditional fields, custom widgets, and the DevTools showcase.

```sh
cd example
flutter run
```

---

## License 📄

MIT.

---

### Support 💖

If Zard Flutter saves you time, consider supporting development 🌟 [Buy Me a Coffee](https://buymeacoffee.com/evandersondev) 🌟. Thank you!
