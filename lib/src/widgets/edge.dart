import "package:flutter/widgets.dart";

import "../style/arrow_style.dart";
import "../style/curve_style.dart";
import "../elements/edge.dart";
import "../style/line_shadow.dart";
import "../style/line_style.dart";
import "../render_objects/edge.dart";

class EdgeWidget<NodeIdType> extends LeafRenderObjectWidget {
  const EdgeWidget({
    super.key,
    required this.startNodeId,
    required this.endNodeId,
    required this.text,
    required this.color,
    required this.lineStyle,
    required this.curveStyle,
    required this.arrowStyle,
    this.onTap,
    this.shadow = const [],
  });

  final NodeIdType startNodeId;
  final NodeIdType endNodeId;
  final String? text;
  final Color color;
  final LineStyle lineStyle;
  final CurveStyle curveStyle;
  final ArrowStyle arrowStyle;
  final VoidCallback? onTap;
  final List<LineShadow> shadow;

  @override
  GraphEdgeRenderObject createRenderObject(BuildContext context) {
    return GraphEdgeRenderObject(
      startNodeId: startNodeId,
      endNodeId: endNodeId,
      text: text,
      color: color,
      lineStyle: lineStyle,
      curveStyle: curveStyle,
      arrowStyle: arrowStyle,
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
      ..lineStyle = lineStyle
      ..curveStyle = curveStyle
      ..arrowStyle = arrowStyle
      ..shadow = shadow;
  }
}
