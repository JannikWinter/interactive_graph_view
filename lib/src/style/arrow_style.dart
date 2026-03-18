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

  static ArrowStyle? lerp(ArrowStyle? a, ArrowStyle? b, double t) {
    if (identical(a, b)) {
      return a;
    }

    final double lengthA = a?.length ?? 0;
    final double widthA = a?.width ?? 0;
    final double lengthB = b?.length ?? 0;
    final double widthB = b?.width ?? 0;

    return ArrowStyle(
      length: lerpDouble(lengthA, lengthB, t)!,
      width: lerpDouble(widthA, widthB, t)!,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (runtimeType != other.runtimeType) {
      return false;
    }

    return other is ArrowStyle && length == other.length && width == other.width;
  }

  @override
  int get hashCode => Object.hash(length, width);
}
