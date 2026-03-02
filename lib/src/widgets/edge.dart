import "package:flutter/material.dart";

import "../curve_style.dart";
import "../elements/edge.dart";
import "../line_shadow.dart";
import "../line_style.dart";
import "../render_objects/edge.dart";

class EdgeWidget<NodeIdType> extends LeafRenderObjectWidget {
  const EdgeWidget({
    super.key,
    required this.startNodeId,
    required this.endNodeId,
    required this.text,
    required this.color,
    required this.thickness,
    required this.lineStyle,
    required this.curveStyle,
    this.onTap,
    this.shadow = const [],
  });

  final NodeIdType startNodeId;
  final NodeIdType endNodeId;
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
      startNodeId: startNodeId,
      endNodeId: endNodeId,
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
      ..startNodeId = startNodeId
      ..endNodeId = endNodeId
      ..text = text
      ..color = color
      ..thickness = thickness
      ..lineStyle = lineStyle
      ..curveStyle = curveStyle
      ..shadow = shadow;
  }
}
