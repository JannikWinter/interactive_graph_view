import "package:flutter/foundation.dart";
import "package:flutter/painting.dart" show Size;
import "package:flutter/rendering.dart" show Rect;

extension NotEmptyRect on Rect {
  bool get isNotEmpty => top < bottom && left < right;
}

extension NotEmptySize on Size {
  bool get isNotEmpty => width > 0.0 && height > 0.0;
}

extension IterableWhereNot<E> on Iterable<E> {
  Iterable<E> whereNot(bool Function(E element) test) => where((element) => !test(element));
}

@immutable
class Nullable<ValueType extends Object> {
  const Nullable(this.value);

  final ValueType? value;
}
