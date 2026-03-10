import "dart:ui";

/// The fill style of an [EdgeWidget]'s drawn line.
///
/// This is used by [EdgeStyle].
sealed class LineStyle {
  const LineStyle({required this.thickness});

  /// The thickness of the edge's drawn line.
  final double thickness;

  static LineStyle? lerp(LineStyle? a, LineStyle? b, double t) {
    if (identical(a, b)) {
      return a;
    }

    final (double? thicknessA, double? dashSizeA, double? gapSizeA) = switch (a) {
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
      null => (null, null, null),
    };
    final (double? thicknessB, double? dashSizeB, double? gapSizeB) = switch (b) {
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
      null => (null, null, null),
    };

    return DashedLineStyle(
      thickness: lerpDouble(thicknessA, thicknessB, t)!,
      dashSize: lerpDouble(dashSizeA, dashSizeB, t)!,
      gapSize: lerpDouble(gapSizeA, gapSizeB, t)!,
    );
  }
}

/// The _solid_ line style for an [EdgeWidget]'s drawn line.
///
/// An edge using this [LineStyle] will be drawn as a solid line.
class SolidLineStyle extends LineStyle {
  /// Constructs a solid line style with a given [thickness].
  const SolidLineStyle({required super.thickness});
}

/// The _dashed_ line style for an [EdgeWidget]'s drawn line.
///
/// An edge using this [LineStyle] will be drawn as a dashed line.
final class DashedLineStyle extends LineStyle {
  /// Constructs a dashed line style with a given [thickness], [dashSize] and [gapSize].
  const DashedLineStyle({required super.thickness, required this.dashSize, required this.gapSize});

  /// The length of each drawn dash.
  final double dashSize;

  /// The length of each gap - the part between the drawn dashes.
  final double gapSize;
}

/// The _dotted_ line style for an [EdgeWidget]'s drawn line.
///
/// An edge using this [LineStyle] will be drawn as a dotted line - similar to the [DashedLineStyle], but the
/// [DashedLineStyle.dashSize] is the same as the [DashedLineStyle.thickness], resulting in drawn dots.
final class DottedLineStyle extends LineStyle {
  /// Constructs a dotted line style with a given [thickness] and [gapSize].
  ///
  /// The dash size is the same as the supplied [thickness].
  ///
  /// If no [gapSize] is supplied, it defaults to using [thickness] as well.
  const DottedLineStyle({required super.thickness, double? gapSize}) : gapSize = gapSize ?? thickness;

  /// The length of each gap - the part between the drawn dots.
  ///
  /// Defaults to [thickness].
  final double gapSize;
}
