import "package:flutter/gestures.dart";
import "package:flutter/material.dart";

import "../elements/graph_viewport.dart";
import "../graph_viewport_controller.dart";
import "../graph_viewport_transform.dart";
import "../render_objects/graph_viewport.dart";
import "edge.dart";
import "node.dart";

typedef NodeBuilder = NodeWidget Function(BuildContext context, ViewNode node);
typedef EdgeBuilder = EdgeWidget Function(BuildContext context, ViewEdge edge);

class GraphViewport extends RenderObjectWidget {
  const GraphViewport({
    super.key,
    required this.viewportController,
    required this.nodeBuilder,
    required this.edgeBuilder,
    required this.transform,
    this.cacheExtent = 50.0,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd,
    this.onTapDown,
    this.onTap,
    this.onDoubleTapDown,
    this.onDoubleTap,
  });

  final GraphViewportController viewportController;
  final NodeBuilder nodeBuilder;
  final EdgeBuilder edgeBuilder;
  final GraphViewportTransform transform;
  final double cacheExtent;

  final GestureScaleStartCallback? onScaleStart;
  final GestureScaleUpdateCallback? onScaleUpdate;
  final GestureScaleEndCallback? onScaleEnd;
  final GestureTapDownCallback? onTapDown;
  final GestureTapCallback? onTap;
  final GestureTapDownCallback? onDoubleTapDown;
  final GestureDoubleTapCallback? onDoubleTap;

  @override
  RenderObjectElement createElement() {
    return GraphViewportElement(this);
  }

  @override
  RenderGraphViewport createRenderObject(BuildContext context) {
    return RenderGraphViewport(
      viewportController: viewportController,
      transform: transform,
      layoutHelper: context as GraphViewportElement,
      cacheExtent: cacheExtent,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderGraphViewport renderObject) {
    renderObject
      ..viewportController = viewportController
      ..transform = transform
      ..cacheExtent = cacheExtent;
  }
}
