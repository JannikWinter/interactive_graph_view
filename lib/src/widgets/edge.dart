import "package:flutter/material.dart";

import "../curve_style.dart";
import "../elements/edge.dart";
import "../line_shadow.dart";
import "../line_style.dart";
import "../render_objects/edge.dart";

class EdgeWidget extends LeafRenderObjectWidget {
  const EdgeWidget({
    super.key,
    required this.text,
    required this.color,
    required this.thickness,
    required this.lineStyle,
    required this.curveStyle,
    this.onTap,
    this.shadow = const [],
  });

  final String? text;
  final Color color;
  final double thickness;
  final LineStyle lineStyle;
  final CurveStyle curveStyle;
  final VoidCallback? onTap;
  final List<LineShadow> shadow;

  @override
  GraphEdgeRenderObject createRenderObject(BuildContext context) {
    return GraphEdgeRenderObject(
      text: text,
      color: color,
      thickness: thickness,
      lineStyle: lineStyle,
      curveStyle: curveStyle,
      shadow: shadow,
    );
  }

  @override
  EdgeElement createElement() {
    return EdgeElement(this);
  }

  @override
  void updateRenderObject(BuildContext context, GraphEdgeRenderObject renderObject) {
    renderObject
      ..text = text
      ..color = color
      ..thickness = thickness
      ..lineStyle = lineStyle
      ..curveStyle = curveStyle
      ..shadow = shadow;
  }
}
