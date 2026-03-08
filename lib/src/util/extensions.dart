import "package:flutter/painting.dart" show Size;
import "package:flutter/rendering.dart" show Rect;

/// An extension that adds [isNotEmpty] to [Rect].
extension NotEmptyRect on Rect {
  /// Whether this rect is not empty.
  ///
  /// Precisely this returns true when the horizontal **and** the vertical size are both positive - zero exclusive.
  bool get isNotEmpty => top < bottom && left < right;
}

/// An extension that adds [isNotEmpty] to [Size].
extension NotEmptySize on Size {
  /// Whether this size is not empty.
  ///
  /// Precisely this returns true when [width] **and** [height] are both larger than `0.0`.
  bool get isNotEmpty => width > 0.0 && height > 0.0;
}

/// An extension that adds [whereNot] to [Iterable].
extension IterableWhereNot<E> on Iterable<E> {
  /// Returns a new `Iterable` for which the given [test] evaluates to `false`.
  Iterable<E> whereNot(bool Function(E element) test) => where((element) => !test(element));
}
