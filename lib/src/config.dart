import "package:flutter/material.dart" show Colors;
import "package:flutter/rendering.dart";

class Config {
  static const double nodeMaxWidth = 400; // TODO: move to Node data and make editable per node
  static const double edgeHitBoxHalfThickness = 20;

  // TODO: move to Theme:
  static const Color canvasBackgroundColor = Colors.black;
  static const String _defaultFontFamily = "NotoSans";
  static const Color nullNodeTextColor = Colors.white;
  static const double nullNodeFontSize = 14;
  static const FontWeight nullNodeFontWeight = FontWeight.normal;
  static const FontStyle nullNodeFontStyle = FontStyle.normal;
  static const TextStyle nullNodeTextStyle = TextStyle(
    fontFamily: _defaultFontFamily,
    color: nullNodeTextColor,
    fontSize: nullNodeFontSize,
    fontWeight: nullNodeFontWeight,
    fontStyle: nullNodeFontStyle,
  );
}
