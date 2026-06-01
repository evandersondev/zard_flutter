import 'package:flutter/foundation.dart';

import 'form_controller.dart';
import 'path.dart';

/// A row in a [ZardFieldArray].
@immutable
class ZardFieldArrayRow<E> {
  const ZardFieldArrayRow({required this.id, required this.value});
  final String id;
  final E? value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ZardFieldArrayRow<E> && other.id == id && other.value == value);

  @override
  int get hashCode => Object.hash(id, value);
}

/// Reactive helper for managing a dynamic list of items at a form path.
///
/// Mirrors React Hook Form's `useFieldArray`: append, prepend, insert, remove,
/// swap, move, replace, update. Each row carries a stable [String] id that
/// callers should use as the widget key so Flutter preserves child state
/// across reorders.
class ZardFieldArray<E> {
  ZardFieldArray._({required this.form, required this.path});

  factory ZardFieldArray.internal({
    required ZardFormController form,
    required String path,
  }) =>
      ZardFieldArray<E>._(form: form, path: path);

  final ZardFormController form;
  final String path;
  final ValueNotifier<List<ZardFieldArrayRow<E>>> _rows = ValueNotifier(const []);
  final List<String> _ids = [];
  int _idCounter = 0;

  ValueListenable<List<ZardFieldArrayRow<E>>> get rows => _rows;

  int get length => _rows.value.length;

  void initializeInternal(List<E> initial) {
    _ids
      ..clear()
      ..addAll(List.generate(initial.length, (_) => _nextId()));
    _emit(initial);
  }

  void append(E item) {
    final next = _currentValues()..add(item);
    _ids.add(_nextId());
    _commit(next);
  }

  void prepend(E item) {
    final next = _currentValues()..insert(0, item);
    _ids.insert(0, _nextId());
    _shiftFieldPaths(insertAt: 0, count: 1);
    _commit(next);
  }

  void insert(int index, E item) {
    final next = _currentValues()..insert(index, item);
    _ids.insert(index, _nextId());
    _shiftFieldPaths(insertAt: index, count: 1);
    _commit(next);
  }

  void remove(int index) {
    final next = _currentValues();
    if (index < 0 || index >= next.length) return;
    next.removeAt(index);
    _ids.removeAt(index);
    _unregisterChildrenAt(index);
    _shiftFieldPaths(removeAt: index, count: 1);
    _commit(next);
  }

  void swap(int a, int b) {
    final next = _currentValues();
    if (a < 0 || a >= next.length || b < 0 || b >= next.length || a == b) return;
    final temp = next[a];
    next[a] = next[b];
    next[b] = temp;
    final tempId = _ids[a];
    _ids[a] = _ids[b];
    _ids[b] = tempId;
    _swapFieldPaths(a, b);
    _commit(next);
  }

  void move(int from, int to) {
    final next = _currentValues();
    if (from < 0 || from >= next.length || to < 0 || to >= next.length) return;
    if (from == to) return;
    final item = next.removeAt(from);
    next.insert(to, item);
    final movedId = _ids.removeAt(from);
    _ids.insert(to, movedId);
    _moveFieldPaths(from, to);
    _commit(next);
  }

  void replace(List<E> items) {
    _clearChildrenUnderPath();
    _ids
      ..clear()
      ..addAll(List.generate(items.length, (_) => _nextId()));
    _commit(List<E>.from(items));
  }

  void update(int index, E item) {
    final next = _currentValues();
    if (index < 0 || index >= next.length) return;
    next[index] = item;
    _commit(next);
  }

  // -----------------------------------------------------------------------
  // Internal helpers
  // -----------------------------------------------------------------------

  String _nextId() => 'fa_${identityHashCode(this)}_${_idCounter++}';

  List<E> _currentValues() {
    final raw = readPath(form.valuesInternal, parsePath(path));
    if (raw is List) {
      return raw.cast<E>().toList();
    }
    return <E>[];
  }

  void _commit(List<E> values) {
    writePath(form.valuesInternal, parsePath(path), values);
    _emit(values);
    // Propagate via the form so listeners/validation react properly.
    form.setValue(path, values, shouldValidate: true, shouldDirty: true);
  }

  void _emit(List<E> values) {
    final rows = <ZardFieldArrayRow<E>>[];
    for (var i = 0; i < values.length; i++) {
      rows.add(ZardFieldArrayRow<E>(
        id: i < _ids.length ? _ids[i] : _nextId(),
        value: values[i],
      ));
    }
    _rows.value = rows;
  }

  void _unregisterChildrenAt(int index) {
    final prefix = '$path.$index';
    final toRemove = form.fieldsInternal.keys
        .where((k) => k == prefix || k.startsWith('$prefix.'))
        .toList();
    for (final k in toRemove) {
      form.unregister(k);
    }
  }

  void _clearChildrenUnderPath() {
    final prefix = '$path.';
    final toRemove = form.fieldsInternal.keys
        .where((k) => k.startsWith(prefix))
        .toList();
    for (final k in toRemove) {
      form.unregister(k);
    }
  }

  void _shiftFieldPaths({int? insertAt, int? removeAt, required int count}) {
    // Re-key any descendant fields whose index sits at/after the mutation
    // point. Insert: bump indices >= insertAt by +count. Remove: indices
    // > removeAt (the removed slot's children were already unregistered)
    // shift by -count.
    final regex = RegExp('^${RegExp.escape(path)}\\.(\\d+)(\\..*|\$)');
    final entries = form.fieldsInternal.entries.toList();
    final renames = <String, String>{};
    for (final entry in entries) {
      final m = regex.firstMatch(entry.key);
      if (m == null) continue;
      final idx = int.parse(m.group(1)!);
      final tail = m.group(2) ?? '';
      int? newIdx;
      if (insertAt != null && idx >= insertAt) {
        newIdx = idx + count;
      } else if (removeAt != null && idx > removeAt) {
        newIdx = idx - count;
      }
      if (newIdx != null) {
        renames[entry.key] = '$path.$newIdx$tail';
      }
    }
    _applyRenames(renames);
  }

  void _swapFieldPaths(int a, int b) {
    final aPrefix = '$path.$a';
    final bPrefix = '$path.$b';
    final renames = <String, String>{};
    for (final key in form.fieldsInternal.keys.toList()) {
      if (key == aPrefix || key.startsWith('$aPrefix.')) {
        renames[key] = key.replaceFirst(aPrefix, '__swap__');
      } else if (key == bPrefix || key.startsWith('$bPrefix.')) {
        renames[key] = key.replaceFirst(bPrefix, aPrefix);
      }
    }
    final second = <String, String>{};
    renames.forEach((from, to) {
      if (to.startsWith('__swap__')) {
        second[from] = to.replaceFirst('__swap__', bPrefix);
      } else {
        second[from] = to;
      }
    });
    _applyRenames(second);
  }

  void _moveFieldPaths(int from, int to) {
    final fromPrefix = '$path.$from';
    final renames = <String, String>{};
    // Collect children of "from" and shift everything between from/to.
    final regex = RegExp('^${RegExp.escape(path)}\\.(\\d+)(\\..*|\$)');
    for (final key in form.fieldsInternal.keys.toList()) {
      if (key == fromPrefix || key.startsWith('$fromPrefix.')) {
        renames[key] = key.replaceFirst(fromPrefix, '$path.$to');
        continue;
      }
      final m = regex.firstMatch(key);
      if (m == null) continue;
      final idx = int.parse(m.group(1)!);
      final tail = m.group(2) ?? '';
      int? newIdx;
      if (from < to && idx > from && idx <= to) {
        newIdx = idx - 1;
      } else if (from > to && idx >= to && idx < from) {
        newIdx = idx + 1;
      }
      if (newIdx != null) {
        renames[key] = '$path.$newIdx$tail';
      }
    }
    _applyRenames(renames);
  }

  void _applyRenames(Map<String, String> renames) {
    if (renames.isEmpty) return;
    // First, move all controllers out of the map to avoid collisions.
    final detached = <String, dynamic>{};
    for (final from in renames.keys) {
      final ctrl = form.fieldsInternal.remove(from);
      if (ctrl != null) detached[from] = ctrl;
    }
    detached.forEach((from, ctrl) {
      final to = renames[from]!;
      ctrl.renameInternal(to);
      form.fieldsInternal[to] = ctrl;
    });
  }
}
