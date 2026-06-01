<p align="center">
  <img src="./assets/logo.png" width="200px" align="center" alt="Logo do Zard Flutter" />
<h1 align="center">Zard Flutter</h1>
<br>
<p align="center">
Formulários reativos e <i>headless-first</i> para Flutter — movidos por schemas do <a href="https://github.com/evandersondev/zard">Zard</a>.
<br/>
Ergonomia de <b>Zod + React Hook Form</b>, nativa no Flutter. Seu schema é a única fonte da verdade para validação, transformação e tipos.
<br/><br/>
🇺🇸 <a href="https://github.com/evandersondev/zard_flutter/blob/main/README.md">Documentation in English</a>
</p>
</p>

<br/>

### Apoie 💖

Se o Zard Flutter te for útil, considere apoiar o desenvolvimento 🌟 [Buy Me a Coffee](https://buymeacoffee.com/evandersondev) 🌟. Seu apoio nos ajuda a melhorar o framework e deixá-lo cada vez melhor!

<br/>

## Por que Zard Flutter? 🤔

O Zard já te entrega schemas, validação, transformações e saída tipada. O **Zard Flutter** adiciona a camada Flutter por cima: estado do formulário, estado por campo, reatividade granular e um conjunto de widgets para ligar tudo à sua UI — sem te obrigar a um visual específico.

- **Headless-first** — `ZardForm` / `ZardField` carregam comportamento, não pixels. Use seus próprios widgets ou o conjunto Material incluído.
- **Assinaturas granulares** — listeners por campo: digitar em um campo não reconstrói os outros.
- **Um schema para tudo** — validação, checagens assíncronas, transforms e saída tipada vêm do seu schema Zard.
- **Caminhos aninhados e field arrays** — `user.address.street`, listas dinâmicas com IDs de linha estáveis.
- **Validação assíncrona** — com debounce, por campo e com indicador de carregamento.
- **Hooks são opcionais** — use o estilo do hook `useForm`, ou o `ZardFormController` puro sem depender de `flutter_hooks`.

---

## Instalação 📦

```yaml
dependencies:
  zard: ^latest
  zard_flutter: ^latest

  # Opcional — só é necessário se você usar a camada de hooks (`package:zard_flutter/hooks.dart`).
  flutter_hooks: ^0.20.5
```

```sh
flutter pub get
```

Imports que você vai usar:

```dart
import 'package:zard/zard.dart';                  // z.map, z.string, ...
import 'package:zard_flutter/zard_flutter.dart';  // ZardForm, ZardField, ZardInput, ...
import 'package:zard_flutter/hooks.dart';         // useForm, useWatch, ... (opcional)
```

---

## Começo rápido 🚀

Um formulário de login mínimo, de ponta a ponta:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:zard/zard.dart';
import 'package:zard_flutter/hooks.dart';
import 'package:zard_flutter/zard_flutter.dart';

final _loginSchema = z.map({
  'email': z.string().email(message: 'Informe um e-mail válido'),
  'password': z.string().min(6, message: 'Pelo menos 6 caracteres'),
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
          const ZardField<String>(
            name: 'email',
            child: ZardInput(label: 'E-mail', placeholder: 'voce@exemplo.com'),
          ),
          const SizedBox(height: 12),
          const ZardField<String>(
            name: 'password',
            child: ZardInput(label: 'Senha', obscureText: true),
          ),
          const SizedBox(height: 16),
          ZardButton(
            fullWidth: true,
            loading: form.isSubmitting,
            onPressed: form.handleSubmit((data) async {
              await Future.delayed(const Duration(milliseconds: 400));
              debugPrint('Enviado: $data');
            }),
            child: const Text('Entrar'),
          ),
        ],
      ),
    );
  }
}
```

Esse é o ciclo inteiro: **schema → `ZardForm` → `ZardField` + um widget → `handleSubmit`**.

---

## Duas formas de criar um formulário 🪝

### Estilo hook — `useForm`

```dart
class MyForm extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final form = useForm(schema: _schema, mode: ValidationMode.onTouched);
    return ZardForm(form: form, child: /* ... */);
  }
}
```

O `useForm` cria o controller, faz o dispose automaticamente ao desmontar e inscreve o widget
nas mudanças de nível de formulário.

> ⚠️ **Hooks precisam ser chamados dentro do `build()`.** Chamar `useForm` / `useState` como
> *inicializador de campo* lança `Hooks can only be called from the build method`. Sempre
> declare como variáveis locais no topo do `build`:
>
> ```dart
> // ❌ ERRADO — executa na construção do objeto, fora do build
> class MyForm extends HookWidget {
>   final form = useForm(schema: _schema); // lança exceção!
> }
>
> // ✅ CERTO — dentro do build
> class MyForm extends HookWidget {
>   @override
>   Widget build(BuildContext context) {
>     final form = useForm(schema: _schema);
>     ...
>   }
> }
> ```

### Estilo controller — `ZardFormController` (sem hooks)

Se você não quer o `flutter_hooks`, mantenha o controller em um `StatefulWidget`:

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
    form.dispose(); // aqui o ciclo de vida é seu
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ZardForm(form: form, child: /* ... */);
  }
}
```

Envolva qualquer parte reativa (como um botão de envio) em `AnimatedBuilder(animation: form, ...)`
para reconstruí-la nas mudanças de nível de formulário.

---

## Conceitos centrais 🧠

### `ZardForm`

Fornece o controller aos descendentes via contexto. Dois modos:

```dart
// 1. Traga seu próprio controller (hook ou StatefulWidget)
ZardForm(form: form, child: ...);

// 2. Deixe o ZardForm criar + descartar um a partir de um schema
ZardForm(schema: _schema, defaultValues: const {...}, child: ...);

// 3. Forma builder — receba o controller no callback
ZardForm.builder(
  schema: _schema,
  builder: (context, form) => ...,
);
```

### `ZardField<T>`

Vinculador headless. Registra um campo em `name` e expõe o controller dele à subárvore.

```dart
// Envolve um widget que sabe ler o campo do contexto (ex.: ZardInput)
const ZardField<String>(
  name: 'email',
  child: ZardInput(label: 'E-mail'),
);

// Ou use o builder para ligar QUALQUER widget você mesmo
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

O `ZardField` aceita `name`, `defaultValue` e `disabled`.

### `ZardFieldController` / `ZardFieldState`

Cada campo possui um controller que expõe um `ValueListenable<ZardFieldState<T>>`. O estado é
um snapshot imutável:

```dart
state.value        // valor atual
state.errors       // List<String>
state.error        // primeiro erro ou null
state.hasError     // bool
state.isTouched    // bool
state.isDirty      // bool
state.isValidating // bool (validação assíncrona em andamento)
state.disabled     // bool
```

Pelo controller você pode usar `setValue`, `setTouched`, `setErrors`, `setDisabled` e (para
campos de texto) acessar um `textController` / `focusNode` alocados sob demanda.

---

## Validação ✅

### Quando ela roda? `ValidationMode` + `RevalidateMode`

`mode` controla quando um campo é validado pela **primeira** vez; `revalidateMode` controla
quando um campo já em erro é revalidado conforme o usuário corrige.

```dart
final form = ZardFormController(
  schema: _schema,
  mode: ValidationMode.onTouched,        // veja a tabela abaixo
  revalidateMode: RevalidateMode.onChange,
);
```

| `ValidationMode` | Valida… |
| --- | --- |
| `onSubmit` (padrão) | só quando o formulário é enviado |
| `onChange` | a cada mudança (mais agressivo) |
| `onBlur` | quando o campo perde o foco |
| `onTouched` | depois que o campo é tocado uma vez |
| `all` | a cada mudança *e* no blur |

| `RevalidateMode` | Após um erro, revalida… |
| --- | --- |
| `onChange` (padrão) | a cada mudança |
| `onBlur` | no blur |
| `onSubmit` | só no próximo envio |

### Regras entre campos com `.refine()`

Os refinamentos ficam no schema. Seus erros surgem como erros de **nível de formulário**:

```dart
final _schema = z.map({
  'password': z.string().min(6),
  'confirm': z.string().min(6),
}).refine(
  (data) => data['password'] == data['confirm'],
  message: 'As senhas precisam coincidir',
);

// Exiba na UI:
AnimatedBuilder(
  animation: form,
  builder: (ctx, _) {
    if (form.formErrors.isEmpty) return const SizedBox.shrink();
    return Text(form.formErrors.first,
        style: const TextStyle(color: Color(0xFFB91C1C)));
  },
);
```

### Controle manual: `setError`, `clearErrors`, `trigger`

```dart
form.setError('email', 'E-mail já existe'); // empurra um erro do servidor para um campo
form.clearErrors('email');                  // limpa um campo
form.clearErrors();                         // limpa tudo

final emailOk = await form.trigger('email'); // valida um caminho
final formOk  = await form.trigger();        // valida o formulário todo
```

### Validação assíncrona

Habilite o pipeline assíncrono e registre validadores por campo (com debounce). Retorne `null`
quando válido, ou uma mensagem de erro quando não:

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
    return _usuariosEmUso.contains(value) ? '"$value" já está em uso' : null;
  },
  debounce: const Duration(milliseconds: 400),
);
```

O `ZardInput` mostra um spinner durante a validação assíncrona — personalize com `loadingBuilder`:

```dart
ZardInput(
  label: 'Usuário',
  loadingBuilder: (_) => const SizedBox(
    width: 16, height: 16,
    child: CircularProgressIndicator(strokeWidth: 2),
  ),
);
```

---

## Enviando 📤

`handleSubmit` retorna um `VoidCallback` pronto para o `onPressed:`. Ele valida e então chama
`onValid` (com os valores já parseados/transformados) ou o `onInvalid` opcional:

```dart
ZardButton(
  loading: form.isSubmitting,
  onPressed: form.handleSubmit(
    (values) async {
      await api.createUser(values);
    },
    onInvalid: (errors) {
      debugPrint('Bloqueado por: $errors');
    },
  ),
  child: const Text('Criar conta'),
);
```

Prefere dar `await` no fluxo? Use `form.submit(onValid, onInvalid:)`. Leia `form.isSubmitting`
/ `form.submitCount` para o estado da UI.

Como os valores entregues ao `onValid` são a saída **parseada** do schema, você pode mapeá-los
direto para um modelo tipado:

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

## Observando valores — e evitando rebuilds indesejados 🔁

Essa é a parte que costuma surpreender, então vale entender o modelo.

### Como funciona a reatividade

`ZardFormController` é um `ChangeNotifier`. Existem **dois** níveis de assinatura:

- **Por campo** — cada campo tem seu próprio `ZardFieldController` (um
  `ValueListenable<ZardFieldState>`). Widgets como `ZardInput` e `ZardField` escutam o *seu
  próprio* campo, então digitar em um campo reconstrói apenas a subárvore daquele campo.
- **Nível de formulário** — o controller em si chama `notifyListeners()` numa série de eventos:
  `setValue`, início/fim do envio, início/fim da validação, registro/desregistro de campos e
  mudanças de erro. Tudo que estiver inscrito no formulário *inteiro* reconstrói nesses casos.

### O que se inscreve no formulário inteiro

Estes reconstroem a **cada** notificação de nível de formulário (incluindo cada tecla, já que
o `setValue` notifica):

- `useForm(...)` — inscreve o widget hospedeiro (via `useListenable`) para manter
  `form.isSubmitting`, `form.isValid`, etc. sempre atualizados.
- `AnimatedBuilder(animation: form, ...)`
- `ZardFormScope.of(context, listen: true)`
- `ZardWatchAll(builder: ...)`

### Por que normalmente está tudo bem

Um widget com `useForm` reexecutando o `build` **não** é o mesmo que reconstruir a árvore
inteira. Mantenha as subárvores dos campos como `const`:

```dart
const ZardField<String>(name: 'email', child: ZardInput(label: 'E-mail')),
```

Quando o pai reconstrói, o Flutter vê o widget `const` idêntico e **pula** aquela subárvore. Os
inputs continuam refletindo a digitação porque escutam o listenable do próprio campo — não o
rebuild do pai. Na prática, uma tela com `useForm` feita de campos `const` é barata.

### A caixa de ferramentas para minimizar rebuilds

Use estes quando um rebuild realmente aparecer no profiler:

- **`ZardWatch<T>(name:)`** — reconstrói só quando o valor de um único campo muda:

  ```dart
  ZardWatch<String>(
    name: 'first',
    builder: (ctx, value) => Text('Olá, ${value ?? ''}'),
  );
  ```

- **`useWatch<T>(name)`** — a forma em hook da mesma assinatura por campo.

- **`useFormState(listen:)`** — inscreva-se apenas nas flags de formulário que importam:

  ```dart
  final s = useFormState(listen: (snap) => [snap.isValid, snap.isDirty]);
  // reconstrói só quando isValid ou isDirty mudam
  ```

- **Escope o `AnimatedBuilder`** — envolva *apenas* o botão de envio, não a tela inteira:

  ```dart
  AnimatedBuilder(
    animation: form,
    builder: (ctx, _) => ZardButton(loading: form.isSubmitting, ...),
  );
  ```

- **Use o controller sem se inscrever** — com o estilo `ZardFormController` (sem hooks), leia o
  controller diretamente e envolva só as partes reativas, de modo que a tela em si nunca se
  inscreva no formulário inteiro.

### Antes / depois

```dart
// ⚠️ Tudo nesta tela reexecuta o build a cada tecla (ainda barato se os campos forem const,
// mas todos os widgets não-const ao redor também reconstroem).
class Screen extends HookWidget {
  Widget build(context) {
    final form = useForm(schema: _schema);
    return ExpensiveLayout(form: form); // não-const → reconstrói a cada notify
  }
}

// ✅ Só o botão reconstrói nas mudanças do formulário; o layout pesado é construído uma vez.
class Screen extends StatefulWidget { ... }
class _ScreenState extends State<Screen> {
  late final form = ZardFormController(schema: _schema);
  Widget build(context) => ZardForm(
    form: form,
    child: const ExpensiveLayout( // const → construído uma vez
      submitButton: _ReactiveSubmit(), // envolve o AnimatedBuilder internamente
    ),
  );
}
```

> 💡 Quer *ver* isso? A tela de exemplo **Watch & FormState** mostra contadores de rebuild ao
> vivo ao lado de `ZardWatch`, `ZardWatchAll` e `useFormState`, para você acompanhar exatamente
> quais assinantes reconstroem enquanto digita.

---

## Valores padrão & reset ♻️

```dart
final form = useForm(
  schema: _schema,
  defaultValues: const {'email': 'padrao@zard.dev', 'nickname': 'guest'},
);

form.reset();                                      // volta aos defaultValues
form.reset(values: const {'email': 'novo@x.dev'}); // nova base
form.reset(keepDirty: true);                       // mantém as flags dirty
form.reset(keepErrors: true);                      // mantém os erros atuais
form.reset(keepTouched: true);                     // mantém as flags touched
```

---

## Caminhos aninhados 🌳

Use notação por ponto para objetos aninhados — os erros caem no campo aninhado certo:

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

const ZardField<String>(name: 'user.name',           child: ZardInput(label: 'Nome')),
const ZardField<String>(name: 'user.address.street', child: ZardInput(label: 'Rua')),
const ZardField<String>(name: 'user.address.city',   child: ZardInput(label: 'Cidade')),
```

---

## Field arrays 📚

Gerencie listas dinâmicas com IDs de linha estáveis (use o `id` como `key` do widget para que o
estado sobreviva às reordenações):

```dart
final form = useForm(
  schema: z.map({'skills': z.list(z.string().min(1))}),
  defaultValues: const {'skills': ['Dart', 'Flutter']},
  mode: ValidationMode.onChange,
);
final skills = useFieldArray<String>('skills', form: form);

// Renderize as linhas — vincule cada uma com `skills.$i`
for (var i = 0; i < skills.rows.value.length; i++)
  Row(
    key: ValueKey(skills.rows.value[i].id),
    children: [
      Expanded(
        child: ZardField<String>(
          name: 'skills.$i',
          child: ZardInput(label: 'Skill #${i + 1}'),
        ),
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
  label: const Text('Adicionar skill'),
),
```

Operações disponíveis: `append`, `prepend`, `insert`, `remove`, `swap`, `move`, `replace`,
`update`. Sem hooks, chame `form.useFieldArray<E>('skills')` diretamente.

---

## Campos condicionais 🔀

Use `ZardWatch` para mostrar/ocultar campos com base no valor de outro campo (combine com
`.optional()` no schema):

```dart
final _schema = z.map({
  'subscribe': z.bool(),
  'email': z.string().optional(),
});

const ZardField<bool>(
  name: 'subscribe',
  defaultValue: false,
  child: ZardCheckbox(label: 'Assinar a newsletter'),
),
ZardWatch<bool>(
  name: 'subscribe',
  builder: (ctx, on) => on == true
      ? const ZardField<String>(name: 'email', child: ZardInput(label: 'E-mail'))
      : const SizedBox.shrink(),
),
```

---

## Assistentes multi-etapa 🧭

Faça o gate de cada etapa com `trigger(path)` — valide só a etapa atual antes de avançar:

```dart
final step = useState(0);
final form = useForm(schema: _schema, mode: ValidationMode.onTouched);

Future<void> next() async {
  const pathByStep = ['name', 'email', 'plan'];
  final ok = await form.trigger(pathByStep[step.value]);
  if (!ok) return;
  if (step.value == 2) {
    await form.submit((data) async { /* finalizar */ });
  } else {
    step.value++;
  }
}

ZardButton(
  loading: form.isValidating || form.isSubmitting,
  onPressed: next,
  child: Text(step.value == 2 ? 'Enviar' : 'Próximo'),
);
```

---

## Widgets Material 🎨

Widgets prontos que resolvem o campo a partir do `ZardField` ao redor (ou recebem um `name:`
explícito).

| Widget | Para | Destaques |
| --- | --- | --- |
| `ZardInput` | `String` | label, placeholder, helperText, obscureText, prefix/suffix, `loadingBuilder`, `errorBuilder` |
| `ZardTextarea` | `String` | variante multi-linha (`minLines: 3`, `maxLines: 8`) |
| `ZardCheckbox` | `bool` | label opcional, tristate |
| `ZardSwitch` | `bool` | label opcional |
| `ZardSelect<T>` | `T` | `options: [ZardSelectOption(value:, label:)]` |
| `ZardRadioGroup<T>` | `T` | `options: [ZardRadioOption(value:, label:)]`, vertical/horizontal |
| `ZardButton` | — | `loading`, `fullWidth`, `icon`; combine com `handleSubmit` |

Exemplo "pia da cozinha":

```dart
const ZardField<String>(name: 'name', child: ZardInput(label: 'Nome')),
ZardField<String>(
  name: 'role',
  child: ZardSelect<String>(
    label: 'Cargo',
    options: const [
      ZardSelectOption(value: 'engineer', label: 'Engenheiro'),
      ZardSelectOption(value: 'designer', label: 'Designer'),
    ],
  ),
),
const ZardField<bool>(
  name: 'newsletter',
  defaultValue: false,
  child: ZardSwitch(label: 'Assinar a newsletter'),
),
ZardField<String>(
  name: 'tier',
  defaultValue: 'free',
  child: ZardRadioGroup<String>(
    options: const [
      ZardRadioOption(value: 'free', label: 'Free'),
      ZardRadioOption(value: 'pro', label: 'Pro'),
    ],
  ),
),
```

---

## Composição headless / estilo Radix 🧩

Componha um campo a partir de pequenas peças headless. Elas pegam o contexto do `ZardField` ao
redor — sem precisar repetir o `name`:

```dart
ZardField<String>(
  name: 'email',
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: const [
      ZardLabel('E-mail', requiredMarker: Text(' *', style: TextStyle(color: Color(0xFFB91C1C)))),
      SizedBox(height: 4),
      ZardInput(placeholder: 'voce@exemplo.com'),
      ZardDescription('Nunca compartilhamos seu e-mail.'),
      ZardErrorMessage(),
    ],
  ),
);
```

Peças: `ZardLabel`, `ZardDescription`, `ZardErrorMessage` (auto-vinculado, ou passe `name:` /
`builder:`) e `ZardFormSection` para agrupar com título/descrição opcionais.

---

## Referência de hooks 🪝

Todos os hooks ficam em `package:zard_flutter/hooks.dart` (requerem `flutter_hooks`).

| Hook | Retorna | Propósito |
| --- | --- | --- |
| `useForm({schema, defaultValues, mode, ...})` | `ZardFormController` | Cria + possui um formulário, inscrito no estado de nível de formulário |
| `useController<T>(name, {form, defaultValue, disabled})` | `ZardFieldController<T>` | Registra/resolve um campo, inscrito no estado dele |
| `useFieldState<T>(name, {form})` | `ZardFieldState<T>` | Apenas o estado atual do campo |
| `useWatch<T>(name, {form, defaultValue})` | `T?` | Leitura reativa do valor de um único campo |
| `useFieldArray<E>(name, {form})` | `ZardFieldArray<E>` | Gerência de lista dinâmica |
| `useFormState({form, listen})` | `ZardFormSnapshot` | Flags de nível de formulário; `listen:` limita rebuilds |
| `useZardFormContext()` | `ZardFormController` | Resolve o formulário mais próximo no contexto |

---

## DevTools 🐛

Coloque um painel de inspeção ao vivo em qualquer lugar dentro de um formulário — valores,
erros, flags de dirty/touched/disabled e um dump JSON:

```dart
ZardDevtools(form: form, collapsed: true);
```

---

## Referência da API 📖

### Core

| Nome | Descrição |
| --- | --- |
| `ZardFormController` | O formulário reativo (`ChangeNotifier`) baseado em um schema `ZMap` |
| `ZardFieldController<T>` | Estado por campo, valor, erros, text controller/focus node opcionais |
| `ZardFieldState<T>` | Snapshot imutável do campo (`value`, `errors`, `isTouched`, …) |
| `ZardFieldArray<E>` / `ZardFieldArrayRow<E>` | Lista dinâmica + linhas com ID estável |
| `ValidationMode` / `RevalidateMode` | Enums que controlam o timing da validação |
| `AsyncFieldValidator` | Typedef `Future<String?> Function(value, allValues)` |
| `ZardFormScope` | `InheritedNotifier` que expõe o controller (`of` / `maybeOf`) |
| utilitários de path | `parsePath`, `canonicalizePath`, `readPath`, `writePath`, `removePath` |

### Widgets headless

| Nome | Descrição |
| --- | --- |
| `ZardForm` / `ZardForm.builder` | Possui ou envolve um controller; o fornece aos descendentes |
| `ZardField<T>` / `ZardField<T>.builder` | Vincula um campo em `name`; `.builder` envolve qualquer widget |
| `ZardFieldBinding` | Acesso herdado ao controller do campo (`of` / `maybeOf`) |
| `ZardWatch<T>` | Reconstrói na mudança de valor de um único campo |
| `ZardWatchAll` | Reconstrói em qualquer mudança de nível de formulário |
| `ZardLabel` | Label headless (encaminha toques ao focus node do campo) |
| `ZardErrorMessage` | Mostra erros do campo (vinculado por contexto ou por `name:`) |
| `ZardDescription` | Texto de ajuda/descrição |
| `ZardFormSection` | Agrupamento com título/descrição opcionais |

### Widgets Material

| Nome | Descrição |
| --- | --- |
| `ZardInput` | `TextField` do Material vinculado a um campo `String` |
| `ZardTextarea` | `ZardInput` multi-linha |
| `ZardCheckbox` / `ZardSwitch` | Campos `bool` |
| `ZardSelect<T>` / `ZardSelectOption<T>` | Dropdown |
| `ZardRadioGroup<T>` / `ZardRadioOption<T>` | Grupo de rádio |
| `ZardButton` | Botão elevado com estado de carregamento |
| `ZardDevtools` | Inspetor de estado do formulário ao vivo |

### Hooks

Veja a tabela de [Referência de hooks](#refer%C3%AAncia-de-hooks-) acima.

---

## Rodando o exemplo 🧪

O app de exemplo é uma vitrine de **15 telas** cobrindo cada recurso deste README — login
básico, cadastro com refine entre campos, modos de validação, validação assíncrona, field
arrays, caminhos aninhados, defaults/reset, erros manuais, watch/form-state, transforms,
composição estilo Radix, assistente multi-etapa, campos condicionais, widgets personalizados e
a vitrine de DevTools.

```sh
cd example
flutter run
```

---

## Licença 📄

MIT.

---

### Apoie 💖

Se o Zard Flutter te economiza tempo, considere apoiar o desenvolvimento 🌟 [Buy Me a Coffee](https://buymeacoffee.com/evandersondev) 🌟. Obrigado!
