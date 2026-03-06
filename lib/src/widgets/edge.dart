import "package:flutter/material.dart" show Theme;
import "package:flutter/widgets.dart";

import "../elements/edge.dart";
import "../style/edge_style.dart";
import "../render_objects/edge.dart";

class EdgeWidget<NodeIdType> extends LeafRenderObjectWidget {
  const EdgeWidget({
    super.key,
    required this.startNodeId,
    required this.endNodeId,
    required this.text,
    this.style,
    this.onTap,
  });

  final NodeIdType startNodeId;
  final NodeIdType endNodeId;
  final String? text;
  final EdgeStyle? style;
  final VoidCallback? onTap;

  @override
  GraphEdgeRenderObject createRenderObject(BuildContext context) {
    final EdgeStyle effectiveStyle = style ?? Theme.of(context).extension<EdgeStyle>() ?? EdgeStyle.fallback();

    return GraphEdgeRenderObject(
      startNodeId: startNodeId,
      endNodeId: endNodeId,
      text: text,
      style: effectiveStyle,
    );
  }

  @override
  EdgeElement createElement() {
    return EdgeElement(this);
  }

  @override
  void updateRenderObject(BuildContext context, GraphEdgeRenderObject renderObject) {
    final EdgeStyle effectiveStyle = style ?? Theme.of(context).extension<EdgeStyle>() ?? EdgeStyle.fallback();

    renderObject
      ..startNodeId = startNodeId
      ..endNodeId = endNodeId
      ..text = text
      ..style = effectiveStyle;
  }
}
