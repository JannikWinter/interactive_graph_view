import "package:flutter/foundation.dart";
import "package:flutter/material.dart" show ThemeExtension, Colors;
import "package:flutter/painting.dart";

import "arrow_style.dart";
import "curve_style.dart";
import "line_shadow.dart";
import "line_style.dart";

/// The style for an [EdgeWidget].
///
/// A style can be applied either by supplying it directly to [EdgeWidget.new] or by supplying it through
/// [ThemeData] - either in a [MaterialApp] or in a [Theme] widget:
/// ```dart
/// Theme(
///   data: ThemeData(
///     extensions: {
///       // ...
///       EdgeStyle(
///         // ...
///       ),
///       // ...
///     },
///   )
/// ```
@immutable
class EdgeStyle extends ThemeExtension<EdgeStyle> {
  /// Constructs an edge style.
  const EdgeStyle({
    required this.lineColor,
    required this.textStyle,
    required this.lineStyle,
    required this.curveStyle,
    required this.arrowStyle,
    this.shadow = const [],
  });

  /// Constructs a fallback edge style which is used by [EdgeWidget] when neither a style is supplied directly nor
  /// an edge style was supplied through a [Theme] up the widget tree.
  const EdgeStyle.fallback()
    : this(
        lineColor: Colors.white,
        textStyle: const TextStyle(color: Colors.white),
        lineStyle: const SolidLineStyle(thickness: 4),
        curveStyle: const StraightCurveStyle(),
        arrowStyle: const ArrowStyle(length: 20, width: 20),
      );

  /// The color of the edge's drawn line.
  final Color lineColor;

  /// The style of the edge's text.
  final TextStyle textStyle;

  /// The fill style of the edge's drawn line.
  final LineStyle lineStyle;

  /// The curve style of the edge's drawn line.
  final CurveStyle curveStyle;

  /// The style of the edge's drawn arrow.
  final ArrowStyle arrowStyle;

  /// The list of shadows applied to the edge's drawn line.
  final List<LineShadow> shadow;

  /// Creates a copy of this edge style with all he given fields replaced by the non-null parameter values.
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
