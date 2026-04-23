import "dart:ui";

import "package:flutter/widgets.dart";

/// The style for the drawn arrow of an [EdgeWidget].
///
/// This is used by [EdgeStyle].
@immutable
final class ArrowStyle {
  /// Constructs an arrow style with a given [width] and [length].
  const ArrowStyle({required this.width, required this.length});

  /// The arrow's width.
  final double width;

  /// The arrow's length.
  final double length;

  /// Creates a copy of this arrow style with all the given fields replaced by the non-null parameter values.
  ArrowStyle copyWith({double? width, double? length}) {
    return ArrowStyle(
      width: width ?? this.width,
      length: length ?? this.length,
    );
  }

  static ArrowStyle? lerp(ArrowStyle? a, ArrowStyle? b, double t) {
    if (identical(a, b)) {
      return a;
    }

    final double widthA = a?.width ?? 0;
    final double lengthA = a?.length ?? 0;
    final double widthB = b?.width ?? 0;
    final double lengthB = b?.length ?? 0;

    return ArrowStyle(
      width: lerpDouble(widthA, widthB, t)!,
      length: lerpDouble(lengthA, lengthB, t)!,
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

    return other is ArrowStyle && width == other.width && length == other.length;
  }

  @override
  int get hashCode => Object.hash(width, length);
}
