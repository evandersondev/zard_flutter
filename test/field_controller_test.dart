import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zard/zard.dart';
import 'package:zard_flutter/zard_flutter.dart';

void main() {
  group('ZardFieldController', () {
    test('TextEditingController syncs from form.setValue without cursor jump', () {
      final form = ZardFormController(schema: z.map({'q': z.string()}));
      final f = form.register<String>('q', defaultValue: 'hello');
      final tc = f.textController;
      expect(tc.text, 'hello');
      // Place cursor at index 2 ("he|llo") and ensure external write places
      // selection at the end (collapsed at length).
      tc.selection = const TextSelection.collapsed(offset: 2);
      form.setValue('q', 'world');
      expect(tc.text, 'world');
      expect(tc.selection, const TextSelection.collapsed(offset: 5));
      form.dispose();
    });

    test('TextEditingController user typing routes through form.setValue', () {
      final form = ZardFormController(schema: z.map({'q': z.string()}));
      final f = form.register<String>('q', defaultValue: '');
      final tc = f.textController;
      tc.value = const TextEditingValue(text: 'typed');
      expect(form.getValue<String>('q'), 'typed');
      expect(form.isDirty, isTrue);
      form.dispose();
    });

    test('setDisabled propagates to state', () {
      final form = ZardFormController(schema: z.map({'q': z.string()}));
      final f = form.register<String>('q');
      expect(f.currentState.disabled, isFalse);
      f.setDisabled(true);
      expect(f.currentState.disabled, isTrue);
      form.dispose();
    });

    test('setError adds and clears single message', () {
      final form = ZardFormController(schema: z.map({'q': z.string()}));
      final f = form.register<String>('q');
      f.setError('bad');
      expect(f.currentState.errors, ['bad']);
      f.setError(null);
      expect(f.currentState.errors, isEmpty);
      form.dispose();
    });
  });
}
