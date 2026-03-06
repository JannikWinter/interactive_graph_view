import "package:flutter/foundation.dart";
import "package:flutter/material.dart" show ThemeExtension, Colors;
import "package:flutter/painting.dart";

import "arrow_style.dart";
import "curve_style.dart";
import "line_shadow.dart";
import "line_style.dart";

@immutable
class EdgeStyle extends ThemeExtension<EdgeStyle> {
  const EdgeStyle({
    required this.lineColor,
    required this.textStyle,
    required this.lineStyle,
    required this.curveStyle,
    required this.arrowStyle,
    this.shadow = const [],
  });

  const EdgeStyle.fallback()
    : this(
        lineColor: Colors.white,
        textStyle: const TextStyle(color: Colors.white),
        lineStyle: const SolidLineStyle(thickness: 4),
        curveStyle: const StraightCurveStyle(),
        arrowStyle: const ArrowStyle(length: 20, width: 20),
      );

  final Color lineColor;
  final TextStyle textStyle;
  final LineStyle lineStyle;
  final CurveStyle curveStyle;
  final ArrowStyle arrowStyle;
  final List<LineShadow> shadow;

  @override
  EdgeStyle copyWith({
    Color? lineColor,
    TextStyle? textStyle,
    LineStyle? lineStyle,
    CurveStyle? curveStyle,
    ArrowStyle? arrowStyle,
    List<LineShadow>? shadow,
  }) {
    return EdgeStyle(
      lineColor: lineColor ?? this.lineColor,
      textStyle: textStyle ?? this.textStyle,
      lineStyle: lineStyle ?? this.lineStyle,
      curveStyle: curveStyle ?? this.curveStyle,
      arrowStyle: arrowStyle ?? this.arrowStyle,
      shadow: List.from(shadow ?? this.shadow),
    );
  }

  @override
  EdgeStyle lerp(ThemeExtension<EdgeStyle>? other, double t) {
    if (identical(this, other) || other is! EdgeStyle) {
      return this;
    }
    return EdgeStyle(
      lineColor: Color.lerp(lineColor, other.lineColor, t)!,
      textStyle: TextStyle.lerp(textStyle, other.textStyle, t)!,
      lineStyle: lineStyle.lerp(other.lineStyle, t),
      curveStyle: curveStyle.lerp(other.curveStyle, t),
      arrowStyle: arrowStyle.lerp(other.arrowStyle, t),
      shadow: LineShadow.lerpList(shadow, other.shadow, t)!,
    );
  }
}
