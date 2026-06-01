import 'package:flutter_test/flutter_test.dart';
import 'package:zard_flutter/zard_flutter.dart';

void main() {
  group('parsePath', () {
    test('empty input → empty segments', () {
      expect(parsePath(''), isEmpty);
    });

    test('single key', () {
      final segs = parsePath('email');
      expect(segs, hasLength(1));
      expect(segs.first, isA<KeySegment>());
      expect((segs.first as KeySegment).key, 'email');
    });

    test('dotted keys', () {
      final segs = parsePath('user.address.street');
      expect(segs.map((s) => (s as KeySegment).key), ['user', 'address', 'street']);
    });

    test('dotted with numeric segments → IndexSegment', () {
      final segs = parsePath('users.0.email');
      expect(segs[0], isA<KeySegment>());
      expect(segs[1], isA<IndexSegment>());
      expect((segs[1] as IndexSegment).index, 0);
      expect(segs[2], isA<KeySegment>());
    });

    test('bracket notation', () {
      final segs = parsePath('users[0].email');
      expect(segs[0], isA<KeySegment>());
      expect(segs[1], isA<IndexSegment>());
      expect((segs[1] as IndexSegment).index, 0);
      expect((segs[2] as KeySegment).key, 'email');
    });

    test('mixed dot and bracket', () {
      final segs = parsePath('a.b[3].c');
      expect(segs[0], isA<KeySegment>());
      expect(segs[1], isA<KeySegment>());
      expect((segs[2] as IndexSegment).index, 3);
      expect((segs[3] as KeySegment).key, 'c');
    });
  });

  group('canonicalPath', () {
    test('always dot-only', () {
      expect(canonicalPath(parsePath('users[0].email')), 'users.0.email');
      expect(canonicalPath(parsePath('users.0.email')), 'users.0.email');
      expect(canonicalPath(parsePath('a.b[3].c')), 'a.b.3.c');
    });

    test('round-trip via canonicalizePath', () {
      expect(canonicalizePath('users[0][1].email'), 'users.0.1.email');
      expect(canonicalizePath('a'), 'a');
      expect(canonicalizePath(''), '');
    });

    test('zard bracket form equals dotted form', () {
      expect(
        canonicalizePath('items[0].name'),
        canonicalizePath('items.0.name'),
      );
    });
  });
}
