import "dart:ui";

import "package:flutter/widgets.dart";

/// The style for the drawn arrow of an [EdgeWidget].
///
/// This is used by [EdgeStyle].
@immutable
final class ArrowStyle {
  /// Constructs an arrow style with a given [width] and [length].
  const ArrowStyle({required this.length, required this.width});

  /// The arrow's length.
  final double length;

  /// The arrow's width.
  final double width;

  /// Creates a copy of this arrow style with all the given fields replaced by the non-null parameter values.
  ArrowStyle copyWith({double? length, double? width}) {
    return ArrowStyle(
      length: length ?? this.length,
      width: width ?? this.width,
    );
  }

  ArrowStyle lerp(ArrowStyle? other, double t) {
    if (other is! ArrowStyle) return this;

    return ArrowStyle(
      length: lerpDouble(length, other.length, t)!,
      width: lerpDouble(width, other.width, t)!,
    );
  }
}
