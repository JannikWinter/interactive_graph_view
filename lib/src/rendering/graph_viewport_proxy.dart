import "package:flutter/rendering.dart";

import "edge.dart";
import "edge_parent_data.dart";
import "graph_child.dart";
import "graph_viewport_base.dart";
import "node.dart";
import "node_parent_data.dart";

class RenderGraphViewportProxy extends RenderGraphViewportBase with RenderObjectWithChildMixin<GraphChildRenderObject> {
  static RenderGraphViewportProxy? maybeOf(RenderObject? object) {
    final RenderGraphViewportBase? viewportBase = RenderGraphViewportBase.maybeOf(object);
    if (viewportBase is RenderGraphViewportProxy) {
      return viewportBase;
    }
    return null;
  }

  static RenderGraphViewportProxy of(RenderObject? object) {
    final RenderGraphViewportProxy? viewport = maybeOf(object);
    assert(() {
      if (viewport == null) {
        throw FlutterError(
          "RenderGraphViewportProxy.of() was called with a render object that was "
          "not a descendant of a RenderGraphViewportProxy.\n"
          "No RenderGraphViewportProxy render object ancestor could be found starting "
          "from the object that was passed to RenderGraphViewportProxy.of().\n"
          "The render object where the viewport search started was:\n"
          "  $object",
        );
      }
      return true;
    }());
    return viewport!;
  }

  RenderGraphViewportProxy({
    required super.backgroundColor,
  });

  late Matrix4 _childTransformationMatrix;

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

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return result.addWithPaintTransform(
      transform: _childTransformationMatrix,
      position: position,
      hitTest: child!.hitTest,
    );
  }
}
