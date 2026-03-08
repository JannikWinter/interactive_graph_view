/// The style of the curve of an [EdgeWidget]'s drawn line.
///
/// This is used by [EdgeStyle].
///
/// Currently only [StraightCurveStyle] is supported, which draws a straight line from start node to end node.
sealed class CurveStyle {
  const CurveStyle();

  CurveStyle lerp(CurveStyle? other, double t) {
    switch (this) {
      case StraightCurveStyle():
        return this;
    }
  }
}

/// The _straight_ curve style for an [EdgeWidget]'s drawn line.
///
/// An edge using this [CurveStyle] will be drawn as a straight line from start node to end node.
final class StraightCurveStyle extends CurveStyle {
  const StraightCurveStyle();
}

// final class CubicBezierCurveStyle extends CurveStyle {
//   const CubicBezierCurveStyle();
// }
