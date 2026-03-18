/// The style of the curve of an [EdgeWidget]'s drawn line.
///
/// This is used by [EdgeStyle].
///
/// Currently only [StraightCurveStyle] is supported, which draws a straight line from start node to end node.
sealed class CurveStyle {
  const CurveStyle();

  static CurveStyle? lerp(CurveStyle? a, CurveStyle? b, double t) {
    if (identical(a, b)) {
      return a;
    }

    switch (a ?? b!) {
      case StraightCurveStyle():
        return a ?? b!;
    }
  }
}

/// The _straight_ curve style for an [EdgeWidget]'s drawn line.
///
/// An edge using this [CurveStyle] will be drawn as a straight line from start node to end node.
final class StraightCurveStyle extends CurveStyle {
  const StraightCurveStyle();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (runtimeType != other.runtimeType) {
      return false;
    }

    return other is StraightCurveStyle;
  }

  @override
  int get hashCode => 0;
}

// final class CubicBezierCurveStyle extends CurveStyle {
//   const CubicBezierCurveStyle();
// }
