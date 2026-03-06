import "dart:ui";

sealed class LineStyle {
  const LineStyle({required this.thickness});

  final double thickness;

  LineStyle lerp(LineStyle? other, double t) {
    if (other is! LineStyle) return this;

    final (double thicknessA, double dashSizeA, double gapSizeA) = switch (this) {
      SolidLineStyle(thickness: final double thickness) => (thickness, 5, 0),
      DashedLineStyle(
        thickness: final double thickness,
        dashSize: final double dashSize,
        gapSize: final double gapSize,
      ) =>
        (thickness, dashSize, gapSize),
      DottedLineStyle(thickness: final double thickness, gapSize: final double gapSize) => (
        thickness,
        thickness,
        gapSize,
      ),
    };
    final (double thicknessB, double dashSizeB, double gapSizeB) = switch (other) {
      SolidLineStyle(thickness: final double thickness) => (thickness, 5, 0),
      DashedLineStyle(
        thickness: final double thickness,
        dashSize: final double dashSize,
        gapSize: final double gapSize,
      ) =>
        (thickness, dashSize, gapSize),
      DottedLineStyle(thickness: final double thickness, gapSize: final double gapSize) => (
        thickness,
        thickness,
        gapSize,
      ),
    };

    return DashedLineStyle(
      thickness: lerpDouble(thicknessA, thicknessB, t)!,
      dashSize: lerpDouble(dashSizeA, dashSizeB, t)!,
      gapSize: lerpDouble(gapSizeA, gapSizeB, t)!,
    );
  }
}

class SolidLineStyle extends LineStyle {
  const SolidLineStyle({required super.thickness});
}

final class DashedLineStyle extends LineStyle {
  const DashedLineStyle({required super.thickness, required this.dashSize, required this.gapSize});

  final double dashSize;
  final double gapSize;
}

final class DottedLineStyle extends LineStyle {
  const DottedLineStyle({required super.thickness, double? gapSize}) : gapSize = gapSize ?? thickness;

  final double gapSize;
}
