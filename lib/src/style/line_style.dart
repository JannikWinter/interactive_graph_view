sealed class LineStyle {
  const LineStyle({required this.thickness});

  final double thickness;
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
