import "package:flutter/foundation.dart";
import "package:flutter/material.dart" show ThemeExtension, Colors;
import "package:flutter/painting.dart";

import "../util/nullable.dart";
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
    this.lineColor,
    this.textStyle = const TextStyle(),
    this.textBackgroundColor,
    this.lineStyle,
    this.curveStyle,
    this.arrowStyle,
    this.shadow,
  });

  /// Constructs a fallback edge style which is used by [EdgeWidget] when neither a style is supplied directly nor
  /// an edge style was supplied through a [Theme] up the widget tree.
  EdgeStyle.fallback()
    : this(
        lineColor: Colors.white,
        textStyle: TextStyle(color: Colors.white),
        textBackgroundColor: Colors.black.withValues(alpha: 0.8),
        lineStyle: const SolidLineStyle(thickness: 3),
        curveStyle: const StraightCurveStyle(),
        arrowStyle: const ArrowStyle(length: 20, width: 20),
        shadow: const [],
      );

  /// The color of the edge's drawn line.
  final Color? lineColor;

  /// The style of the edge's text.
  final TextStyle textStyle;

  /// The background color of the edge's text.
  ///
  /// Set this to [Colors.transparent] if there should be no background.
  final Color? textBackgroundColor;

  /// The fill style of the edge's drawn line.
  final LineStyle? lineStyle;

  /// The curve style of the edge's drawn line.
  final CurveStyle? curveStyle;

  /// The style of the edge's drawn arrow.
  final ArrowStyle? arrowStyle;

  /// The list of shadows applied to the edge's drawn line.
  final List<LineShadow>? shadow;

  /// Creates a copy of this edge style with all he given fields replaced by the non-null parameter values.
  @override
  EdgeStyle copyWith({
    Nullable<Color>? lineColor,
    TextStyle? textStyle,
    Nullable<Color>? textBackgroundColor,
    Nullable<LineStyle>? lineStyle,
    Nullable<CurveStyle>? curveStyle,
    Nullable<ArrowStyle>? arrowStyle,
    Nullable<List<LineShadow>>? shadow,
  }) {
    return EdgeStyle(
      lineColor: (lineColor != null) ? lineColor.value : this.lineColor,
      textStyle: textStyle ?? this.textStyle,
      textBackgroundColor: (textBackgroundColor != null) ? textBackgroundColor.value : this.textBackgroundColor,
      lineStyle: (lineStyle != null) ? lineStyle.value : this.lineStyle,
      curveStyle: (curveStyle != null) ? curveStyle.value : this.curveStyle,
      arrowStyle: (arrowStyle != null) ? arrowStyle.value : this.arrowStyle,
      shadow: (shadow != null) ? ((shadow.value != null) ? List.from(shadow.value!) : null) : this.shadow,
    );
  }

  @override
  EdgeStyle lerp(ThemeExtension<EdgeStyle>? other, double t) {
    if (identical(this, other) || other is! EdgeStyle) {
      return this;
    }
    return EdgeStyle(
      lineColor: Color.lerp(lineColor, other.lineColor, t),
      textStyle: TextStyle.lerp(textStyle, other.textStyle, t)!,
      textBackgroundColor: Color.lerp(textBackgroundColor, other.textBackgroundColor, t),
      lineStyle: LineStyle.lerp(lineStyle, other.lineStyle, t),
      curveStyle: CurveStyle.lerp(curveStyle, other.curveStyle, t),
      arrowStyle: ArrowStyle.lerp(arrowStyle, other.arrowStyle, t),
      shadow: LineShadow.lerpList(shadow, other.shadow, t),
    );
  }

  /// Returns a new edge style that is a combination of this style and the given [other] style.
  ///
  /// The null properties of the given [other] edge style are replaced with the non-null properties of this edge style.
  /// The [other] style _inherits_ the properties of this style. Another way to think of it is that the "missing"
  /// properties of the [other] style are _filled_ by the properties of this style.
  ///
  /// If the given edge style is null, returns this edge style.
  EdgeStyle merge(EdgeStyle? other) {
    if (identical(this, other) || other == null) {
      return this;
    }

    return copyWith(
      lineColor: Nullable((other.lineColor != null) ? other.lineColor : lineColor),
      textStyle: textStyle.merge(other.textStyle),
      textBackgroundColor: Nullable(
        (other.textBackgroundColor != null) ? other.textBackgroundColor : textBackgroundColor,
      ),
      lineStyle: Nullable((other.lineStyle != null) ? other.lineStyle : lineStyle),
      curveStyle: Nullable((other.curveStyle != null) ? other.curveStyle : curveStyle),
      arrowStyle: Nullable((other.arrowStyle != null) ? other.arrowStyle : arrowStyle),
      shadow: Nullable((other.shadow != null) ? other.shadow : shadow),
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

    return other is EdgeStyle &&
        lineColor == other.lineColor &&
        textStyle == other.textStyle &&
        textBackgroundColor == other.textBackgroundColor &&
        lineStyle == other.lineStyle &&
        curveStyle == other.curveStyle &&
        arrowStyle == other.arrowStyle &&
        shadow == other.shadow;
  }

  @override
  int get hashCode => Object.hash(
    lineColor,
    textStyle,
    textBackgroundColor,
    lineStyle,
    curveStyle,
    arrowStyle,
    shadow,
  );
}
