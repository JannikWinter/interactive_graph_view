import "package:flutter/rendering.dart";

import "edge.dart";
import "edge_parent_data.dart";
import "graph_child.dart";
import "node.dart";
import "node_parent_data.dart";

class RenderGraphViewportProxy extends RenderBox with RenderObjectWithChildMixin<GraphChildRenderObject> {
  RenderGraphViewportProxy({
    required Color backgroundColor,
  }) : _backgroundColor = backgroundColor;

  late Matrix4 _childTransformationMatrix;

  Color get backgroundColor => _backgroundColor;
  Color _backgroundColor;
  set backgroundColor(Color value) {
    if (_backgroundColor == value) return;

    _backgroundColor = value;

    markNeedsPaint();
  }

  @override
  void setupParentData(GraphChildRenderObject child) {
    if (child is GraphEdgeRenderObject && !child.hasParentData) {
      child.parentData = GraphViewportEdgeParentData();
    } else if (child is GraphNodeRenderObject && !child.hasParentData) {
      child.parentData = GraphViewportNodeParentData();
    }
  }

  GraphViewportNodeParentData _setChildNodeParentData(GraphNodeRenderObject node) {
    return node.parentData;
  }

  GraphViewportEdgeParentData _setChildEdgeParentData(GraphEdgeRenderObject edge) {
    return edge.parentData
      ..startNodeCenter = Offset(-size.width / 2, 0)
      ..endNodeCenter = Offset(size.width / 2, 0);
  }

  @override
  void performLayout() {
    size = constraints.biggest;
    _childTransformationMatrix = Matrix4.identity()..translateByDouble(size.width / 2, size.height / 2, 0, 1);

    switch (child) {
      case GraphNodeRenderObject():
        _setChildNodeParentData(child as GraphNodeRenderObject);

      case GraphEdgeRenderObject():
        _setChildEdgeParentData(child as GraphEdgeRenderObject);

      default:
        throw AssertionError("Unknown child type in RenderGraphViewportProxy: ${child.runtimeType}");
    }

    child!.layout(constraints);
  }

  @override
  void applyPaintTransform(covariant RenderObject child, Matrix4 transform) {
    transform.multiply(_childTransformationMatrix);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.pushClipRect(
      needsCompositing,
      offset,
      paintBounds,
      (context, offset) {
        context.canvas.drawColor(backgroundColor, BlendMode.src);

        context.pushTransform(
          needsCompositing,
          offset,
          _childTransformationMatrix,
          (context, offset) {
            context.paintChild(child!, offset);
          },
        );
      },
    );
  }
}
