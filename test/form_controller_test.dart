import 'package:flutter_test/flutter_test.dart';
import 'package:zard/zard.dart';
import 'package:zard_flutter/zard_flutter.dart';

void main() {
  group('ZardFormController', () {
    test('register/setValue/getValue happy path', () {
      final form = ZardFormController(
        schema: z.map({'email': z.string().email()}),
      );
      final email = form.register<String>('email', defaultValue: '');
      expect(email.value, '');
      form.setValue('email', 'a@b.c');
      expect(form.getValue<String>('email'), 'a@b.c');
      expect(email.value, 'a@b.c');
      form.dispose();
    });

    test('default values seed values and field controllers', () {
      final form = ZardFormController(
        schema: z.map({'email': z.string()}),
        defaultValues: {'email': 'hello@x.io'},
      );
      final email = form.register<String>('email');
      expect(email.value, 'hello@x.io');
      expect(form.values['email'], 'hello@x.io');
      form.dispose();
    });

    test('setValue marks dirty when value differs from default', () {
      final form = ZardFormController(
        schema: z.map({'email': z.string()}),
        defaultValues: {'email': 'a@b.c'},
      );
      form.register<String>('email');
      expect(form.isDirty, isFalse);
      form.setValue('email', 'other@x.io');
      expect(form.isDirty, isTrue);
      form.setValue('email', 'a@b.c');
      expect(form.isDirty, isFalse);
      form.dispose();
    });

    test('nested paths route to right field', () {
      final schema = z.map({
        'user': z.map({
          'address': z.map({
            'street': z.string().min(3),
          }),
        }),
      });
      final form = ZardFormController(schema: schema);
      final street = form.register<String>('user.address.street');
      form.setValue('user.address.street', 'X');
      expect(street.value, 'X');
      expect(form.getValue<String>('user.address.street'), 'X');
      form.dispose();
    });

    test('submit on valid invokes onValid with values', () async {
      final form = ZardFormController(
        schema: z.map({'email': z.string().email()}),
        mode: ValidationMode.onSubmit,
      );
      form.register<String>('email');
      form.setValue('email', 'good@example.com', shouldValidate: false);
      Map<String, dynamic>? got;
      await form.submit((values) {
        got = Map<String, dynamic>.from(values);
      });
      expect(got, isNotNull);
      expect(got!['email'], 'good@example.com');
      expect(form.isSubmitting, isFalse);
      expect(form.submitCount, 1);
      form.dispose();
    });

    test('submit on invalid surfaces error and calls onInvalid', () async {
      final form = ZardFormController(
        schema: z.map({'email': z.string().email()}),
      );
      form.register<String>('email');
      form.setValue('email', 'not-an-email', shouldValidate: false);
      Map<String, List<String>>? captured;
      await form.submit(
        (_) {},
        onInvalid: (errors) {
          captured = Map.from(errors);
        },
      );
      expect(captured, isNotNull);
      expect(captured!['email'], isNotNull);
      expect(form.isValid, isFalse);
      form.dispose();
    });

    test('reset restores defaults and clears flags', () async {
      final form = ZardFormController(
        schema: z.map({'email': z.string().email()}),
        defaultValues: {'email': 'a@b.c'},
      );
      form.register<String>('email');
      form.setValue('email', 'x@y.z');
      expect(form.isDirty, isTrue);
      form.reset();
      expect(form.getValue<String>('email'), 'a@b.c');
      expect(form.isDirty, isFalse);
      form.dispose();
    });

    test('setError + clearErrors round trip', () {
      final form = ZardFormController(
        schema: z.map({'email': z.string()}),
      );
      form.register<String>('email');
      form.setError('email', 'manual');
      expect(form.errors['email'], contains('manual'));
      expect(form.isValid, isFalse);
      form.clearErrors('email');
      expect(form.errors['email'], isNull);
      form.dispose();
    });

    test('trigger returns true when path is clean', () async {
      final form = ZardFormController(
        schema: z.map({'email': z.string().email()}),
      );
      form.register<String>('email');
      form.setValue('email', 'good@example.com', shouldValidate: false);
      expect(await form.trigger('email'), isTrue);
      form.setValue('email', 'bad', shouldValidate: false);
      expect(await form.trigger('email'), isFalse);
      form.dispose();
    });

    test('async validator surfaces error at the right path', () async {
      final form = ZardFormController(
        schema: z.map({'username': z.string()}),
        asyncValidation: true,
      );
      form.register<String>('username');
      form.registerAsyncValidator('username', (value, _) async {
        if (value == 'taken') return 'Username is taken';
        return null;
      }, debounce: Duration.zero);
      form.setValue('username', 'taken', shouldValidate: false);
      final ok = await form.validate(async: true);
      expect(ok, isFalse);
      expect(form.errors['username'], contains('Username is taken'));
      form.dispose();
    });
  });
}
