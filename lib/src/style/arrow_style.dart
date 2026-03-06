import "dart:ui";

import "package:flutter/widgets.dart";

@immutable
final class ArrowStyle {
  const ArrowStyle({required this.length, required this.width});

  final double length;
  final double width;

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
