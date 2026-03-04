import "package:flutter/gestures.dart";
import "package:flutter/widgets.dart";

import "../elements/graph_viewport.dart";
import "../graph_viewport_controller.dart";
import "../graph_viewport_transform.dart";
import "../render_objects/graph_viewport.dart";
import "edge.dart";
import "node.dart";

typedef NodeBuilder<NodeIdType> = NodeWidget Function(BuildContext context, NodeIdType nodeId);
typedef EdgeBuilder<EdgeIdType> = EdgeWidget Function(BuildContext context, EdgeIdType edgeId);

class GraphViewport<NodeIdType, EdgeIdType> extends RenderObjectWidget {
  static const double kDefaultCacheExtent = 50.0;

  const GraphViewport({
    super.key,
    required this.viewportController,
    required this.nodeBuilder,
    required this.edgeBuilder,
    required this.transform,
    this.cacheExtent = kDefaultCacheExtent,
    this.rebuildAllChildrenOnWidgetUpdate = true,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd,
    this.onTapDown,
    this.onTap,
    this.onDoubleTapDown,
    this.onDoubleTap,
  });

  final GraphViewportController<NodeIdType, EdgeIdType> viewportController;
  final NodeBuilder<NodeIdType> nodeBuilder;
  final EdgeBuilder<EdgeIdType> edgeBuilder;
  final GraphViewportTransform transform;
  final double cacheExtent;
  final bool rebuildAllChildrenOnWidgetUpdate;

  final GestureScaleStartCallback? onScaleStart;
  final GestureScaleUpdateCallback? onScaleUpdate;
  final GestureScaleEndCallback? onScaleEnd;
  final GestureTapDownCallback? onTapDown;
  final GestureTapCallback? onTap;
  final GestureTapDownCallback? onDoubleTapDown;
  final GestureDoubleTapCallback? onDoubleTap;

  @override
  RenderObjectElement createElement() {
    return GraphViewportElement<NodeIdType, EdgeIdType>(this);
  }

  @override
  RenderGraphViewport<NodeIdType, EdgeIdType> createRenderObject(BuildContext context) {
    return RenderGraphViewport<NodeIdType, EdgeIdType>(
      viewportController: viewportController,
      transform: transform,
      layoutHelper: context as GraphViewportElement<NodeIdType, EdgeIdType>,
      cacheExtent: cacheExtent,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderGraphViewport<NodeIdType, EdgeIdType> renderObject,
  ) {
    renderObject
      ..viewportController = viewportController
      ..transform = transform
      ..cacheExtent = cacheExtent;
  }
}
