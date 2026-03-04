import "dart:math" as math;
import "dart:ui" as ui show Shadow, lerpDouble;

import "package:flutter/widgets.dart";

@immutable
final class LineShadow extends ui.Shadow {
  static const Color kDefaultColor = Color(0xFF000000);
  static const double kDefaultBlurRadius = 0.0;
  static const double kDefaultSpreadRadius = 0.0;

  const LineShadow({
    super.color = kDefaultColor,
    super.blurRadius = kDefaultBlurRadius,
    this.spreadRadius = kDefaultSpreadRadius,
  });

  /// The amount the line should be inflated prior to applying the blur.
  final double spreadRadius;

  /// Create the [Paint] object that corresponds to this shadow description.
  @override
  Paint toPaint() {
    final Paint result = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma)
      ..strokeWidth = spreadRadius * 2;

    return result;
  }

  /// Returns a new line shadow with its blurRadius and spreadRadius
  /// scaled by the given factor.
  @override
  LineShadow scale(double factor) {
    return LineShadow(
      color: color,
      blurRadius: blurRadius * factor,
      spreadRadius: spreadRadius * factor,
    );
  }

  /// Creates a copy of this object but with the given fields replaced with the
  /// new values.
  LineShadow copyWith({
    Color? color,
    double? blurRadius,
    double? spreadRadius,
  }) {
    return LineShadow(
      color: color ?? this.color,
      blurRadius: blurRadius ?? this.blurRadius,
      spreadRadius: spreadRadius ?? this.spreadRadius,
    );
  }

  /// Linearly interpolate between two line shadows.
  ///
  /// If either line shadow is null, this function linearly interpolates from
  /// a line shadow that matches the other line shadow in color but has a
  /// zero blurRadius.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static LineShadow? lerp(LineShadow? a, LineShadow? b, double t) {
    if (identical(a, b)) {
      return a;
    }
    if (a == null) {
      return b!.scale(t);
    }
    if (b == null) {
      return a.scale(1.0 - t);
    }
    return LineShadow(
      color: Color.lerp(a.color, b.color, t)!,
      blurRadius: ui.lerpDouble(a.blurRadius, b.blurRadius, t)!,
      spreadRadius: ui.lerpDouble(a.spreadRadius, b.spreadRadius, t)!,
    );
  }

  /// Linearly interpolate between two lists of line shadows.
  ///
  /// If the lists differ in length, excess items are lerped with null.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static List<LineShadow>? lerpList(List<LineShadow>? a, List<LineShadow>? b, double t) {
    if (identical(a, b)) {
      return a;
    }
    a ??= <LineShadow>[];
    b ??= <LineShadow>[];
    final int commonLength = math.min(a.length, b.length);
    return <LineShadow>[
      for (int i = 0; i < commonLength; i += 1) LineShadow.lerp(a[i], b[i], t)!,
      for (int i = commonLength; i < a.length; i += 1) a[i].scale(1.0 - t),
      for (int i = commonLength; i < b.length; i += 1) b[i].scale(t),
    ];
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is LineShadow &&
        other.color == color &&
        other.blurRadius == blurRadius &&
        other.spreadRadius == spreadRadius;
  }

  @override
  int get hashCode => Object.hash(color, offset, blurRadius, spreadRadius);
}
