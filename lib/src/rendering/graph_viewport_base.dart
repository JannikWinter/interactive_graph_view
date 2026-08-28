import "package:flutter/rendering.dart";

import "edge.dart";
import "edge_parent_data.dart";
import "graph_child.dart";
import "node.dart";
import "node_parent_data.dart";

abstract class RenderGraphViewportBase extends RenderBox {
  static RenderGraphViewportBase? maybeOf(RenderObject? object) {
    while (object != null) {
      if (object is RenderGraphViewportBase) {
        return object;
      }
      object = object.parent;
    }
    return null;
  }

  static RenderGraphViewportBase of(RenderObject? object) {
    final RenderGraphViewportBase? viewportBase = maybeOf(object);
    assert(() {
      if (viewportBase == null) {
        throw FlutterError(
          "RenderGraphViewportBase.of() was called with a render object that was "
          "not a descendant of a RenderGraphViewportBase.\n"
          "No RenderGraphViewportBase render object ancestor could be found starting "
          "from the object that was passed to RenderGraphViewportBase.of().\n"
          "The render object where the viewport search started was:\n"
          "  $object",
        );
      }
      return true;
    }());
    return viewportBase!;
  }

  RenderGraphViewportBase({
    required Color backgroundColor,
  }) : _backgroundColor = backgroundColor;

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

  Offset get globalPaintOffset {
    final translation = getTransformTo(null).getTranslation();

    return Offset(translation.x, translation.y);
  }
}
