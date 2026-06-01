import 'package:flutter_test/flutter_test.dart';
import 'package:zard/zard.dart';
import 'package:zard_flutter/zard_flutter.dart';

void main() {
  ZardFormController makeForm() => ZardFormController(
        schema: z.map({
          'skills': z.list(z.string()),
        }),
      );

  group('ZardFieldArray', () {
    test('append/prepend/insert', () {
      final form = makeForm();
      final arr = form.useFieldArray<String>('skills');
      arr.append('flutter');
      arr.append('dart');
      arr.prepend('rust');
      arr.insert(1, 'go');
      expect(
        arr.rows.value.map((r) => r.value).toList(),
        ['rust', 'go', 'flutter', 'dart'],
      );
      // ids stable per row (no collisions)
      expect(arr.rows.value.map((r) => r.id).toSet(), hasLength(4));
      form.dispose();
    });

    test('remove drops both value and id', () {
      final form = makeForm();
      final arr = form.useFieldArray<String>('skills');
      arr.replace(['a', 'b', 'c']);
      final idsBefore = arr.rows.value.map((r) => r.id).toList();
      arr.remove(1);
      expect(arr.rows.value.map((r) => r.value).toList(), ['a', 'c']);
      expect(arr.rows.value[0].id, idsBefore[0]);
      expect(arr.rows.value[1].id, idsBefore[2]);
      form.dispose();
    });

    test('swap preserves ids', () {
      final form = makeForm();
      final arr = form.useFieldArray<String>('skills');
      arr.replace(['a', 'b', 'c']);
      final ids = arr.rows.value.map((r) => r.id).toList();
      arr.swap(0, 2);
      expect(arr.rows.value.map((r) => r.value).toList(), ['c', 'b', 'a']);
      expect(arr.rows.value[0].id, ids[2]);
      expect(arr.rows.value[2].id, ids[0]);
      form.dispose();
    });

    test('move preserves the moved id', () {
      final form = makeForm();
      final arr = form.useFieldArray<String>('skills');
      arr.replace(['a', 'b', 'c', 'd']);
      final ids = arr.rows.value.map((r) => r.id).toList();
      arr.move(0, 2);
      expect(arr.rows.value.map((r) => r.value).toList(), ['b', 'c', 'a', 'd']);
      // The moved item's id stays with it.
      expect(arr.rows.value[2].id, ids[0]);
      form.dispose();
    });

    test('replace regenerates ids', () {
      final form = makeForm();
      final arr = form.useFieldArray<String>('skills');
      arr.replace(['a']);
      final firstId = arr.rows.value.first.id;
      arr.replace(['a']);
      expect(arr.rows.value.first.id, isNot(firstId));
      form.dispose();
    });

    test('remove unregisters child field controllers under the removed index',
        () {
      final form = makeForm();
      final arr = form.useFieldArray<String>('skills');
      arr.append('flutter');
      arr.append('dart');
      form.register<String>('skills.0');
      form.register<String>('skills.1');
      expect(form.registeredPaths, containsAll(['skills.0', 'skills.1']));
      arr.remove(0);
      expect(form.registeredPaths, contains('skills.0'));
      expect(form.registeredPaths, isNot(contains('skills.1')));
      form.dispose();
    });
  });
}
