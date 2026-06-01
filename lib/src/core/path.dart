sealed class PathSegment {
  const PathSegment();
}

final class KeySegment extends PathSegment {
  final String key;
  const KeySegment(this.key);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is KeySegment && other.key == key);

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'KeySegment($key)';
}

final class IndexSegment extends PathSegment {
  final int index;
  const IndexSegment(this.index);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is IndexSegment && other.index == index);

  @override
  int get hashCode => index.hashCode;

  @override
  String toString() => 'IndexSegment($index)';
}

class PathTypeError extends Error {
  final String message;
  PathTypeError(this.message);
  @override
  String toString() => 'PathTypeError: $message';
}

List<PathSegment> parsePath(String input) {
  if (input.isEmpty) return const [];
  final segments = <PathSegment>[];
  final buffer = StringBuffer();

  void flushKey() {
    if (buffer.isEmpty) return;
    final token = buffer.toString();
    buffer.clear();
    final asInt = int.tryParse(token);
    if (asInt != null) {
      segments.add(IndexSegment(asInt));
    } else {
      segments.add(KeySegment(token));
    }
  }

  for (var i = 0; i < input.length; i++) {
    final c = input[i];
    if (c == '.') {
      flushKey();
    } else if (c == '[') {
      flushKey();
      final closeAt = input.indexOf(']', i + 1);
      if (closeAt == -1) {
        throw PathTypeError('Unclosed [ in path "$input"');
      }
      final inside = input.substring(i + 1, closeAt);
      final idx = int.tryParse(inside);
      if (idx == null) {
        // Non-numeric bracket — treat as key (e.g. ['foo'])
        var stripped = inside;
        if ((stripped.startsWith("'") && stripped.endsWith("'")) ||
            (stripped.startsWith('"') && stripped.endsWith('"'))) {
          stripped = stripped.substring(1, stripped.length - 1);
        }
        segments.add(KeySegment(stripped));
      } else {
        segments.add(IndexSegment(idx));
      }
      i = closeAt;
    } else {
      buffer.write(c);
    }
  }
  flushKey();
  return segments;
}

String canonicalPath(List<PathSegment> segments) {
  if (segments.isEmpty) return '';
  final out = StringBuffer();
  for (var i = 0; i < segments.length; i++) {
    if (i > 0) out.write('.');
    final s = segments[i];
    switch (s) {
      case KeySegment(:final key):
        out.write(key);
      case IndexSegment(:final index):
        out.write(index);
    }
  }
  return out.toString();
}

/// Convenience: parse + canonicalize in one step.
String canonicalizePath(String input) => canonicalPath(parsePath(input));

bool isPathUnder(String parent, String descendant) {
  if (parent.isEmpty) return descendant.isNotEmpty;
  if (descendant == parent) return true;
  return descendant.startsWith('$parent.');
}

dynamic readPath(Object? root, List<PathSegment> segments) {
  Object? cursor = root;
  for (final s in segments) {
    if (cursor == null) return null;
    switch (s) {
      case KeySegment(:final key):
        if (cursor is Map) {
          cursor = cursor[key];
        } else {
          return null;
        }
      case IndexSegment(:final index):
        if (cursor is List) {
          if (index < 0 || index >= cursor.length) return null;
          cursor = cursor[index];
        } else {
          return null;
        }
    }
  }
  return cursor;
}

/// Writes [value] into [root] at the given [segments].
///
/// Allocates intermediate maps/lists as needed. Throws [PathTypeError] when an
/// existing slot exists with the wrong shape (e.g. a map where a list is
/// expected).
void writePath(Object root, List<PathSegment> segments, dynamic value) {
  if (segments.isEmpty) {
    throw PathTypeError('Cannot write to empty path');
  }
  Object cursor = root;
  for (var i = 0; i < segments.length - 1; i++) {
    final s = segments[i];
    final next = segments[i + 1];
    switch (s) {
      case KeySegment(:final key):
        if (cursor is! Map) {
          throw PathTypeError(
              'Expected Map at segment "$key" but found ${cursor.runtimeType}');
        }
        var child = cursor[key];
        if (child == null) {
          child = (next is IndexSegment) ? <dynamic>[] : <String, dynamic>{};
          cursor[key] = child;
        }
        cursor = child as Object;
      case IndexSegment(:final index):
        if (cursor is! List) {
          throw PathTypeError(
              'Expected List at segment "[$index]" but found ${cursor.runtimeType}');
        }
        while (cursor.length <= index) {
          cursor.add(null);
        }
        var child = cursor[index];
        if (child == null) {
          child = (next is IndexSegment) ? <dynamic>[] : <String, dynamic>{};
          cursor[index] = child;
        }
        cursor = child as Object;
    }
  }
  final last = segments.last;
  switch (last) {
    case KeySegment(:final key):
      if (cursor is! Map) {
        throw PathTypeError(
            'Expected Map at terminal key "$key" but found ${cursor.runtimeType}');
      }
      cursor[key] = value;
    case IndexSegment(:final index):
      if (cursor is! List) {
        throw PathTypeError(
            'Expected List at terminal index [$index] but found ${cursor.runtimeType}');
      }
      while (cursor.length <= index) {
        cursor.add(null);
      }
      cursor[index] = value;
  }
}

void removePath(Object root, List<PathSegment> segments) {
  if (segments.isEmpty) return;
  Object? cursor = root;
  for (var i = 0; i < segments.length - 1; i++) {
    if (cursor == null) return;
    final s = segments[i];
    switch (s) {
      case KeySegment(:final key):
        if (cursor is Map) {
          cursor = cursor[key];
        } else {
          return;
        }
      case IndexSegment(:final index):
        if (cursor is List && index >= 0 && index < cursor.length) {
          cursor = cursor[index];
        } else {
          return;
        }
    }
  }
  if (cursor == null) return;
  final last = segments.last;
  switch (last) {
    case KeySegment(:final key):
      if (cursor is Map) cursor.remove(key);
    case IndexSegment(:final index):
      if (cursor is List && index >= 0 && index < cursor.length) {
        cursor.removeAt(index);
      }
  }
}
