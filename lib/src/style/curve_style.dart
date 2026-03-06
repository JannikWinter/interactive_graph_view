sealed class CurveStyle {
  const CurveStyle();

  CurveStyle lerp(CurveStyle? other, double t) {
    switch (this) {
      case StraightCurveStyle():
        return this;
    }
  }
}

final class StraightCurveStyle extends CurveStyle {
  const StraightCurveStyle();
}

// final class CubicBezierCurveStyle extends CurveStyle {
//   const CubicBezierCurveStyle();
// }
