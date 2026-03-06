import "package:flutter/gestures.dart";
import "package:flutter/material.dart" show Theme;
import "package:flutter/widgets.dart";

import "../elements/graph_viewport.dart";
import "../graph_viewport_controller.dart";
import "../graph_viewport_transform.dart";
import "../render_objects/graph_viewport.dart";
import "../style/graph_style.dart";
import "edge.dart";
import "node.dart";

typedef NodeBuilder<NodeIdType> = NodeWidget Function(BuildContext context, NodeIdType nodeId);
typedef EdgeBuilder<EdgeIdType> = EdgeWidget Function(BuildContext context, EdgeIdType edgeId);

class GraphViewport<NodeIdType, EdgeIdType> extends RenderObjectWidget {
  static const double kDefaultCacheExtent = 50.0;
  static const double kDefaultEdgeHitboxThickness = 40.0;

  const GraphViewport({
    super.key,
    required this.viewportController,
    required this.nodeBuilder,
    required this.edgeBuilder,
    required this.transform,
    this.style,
    this.cacheExtent = kDefaultCacheExtent,
    this.edgeHitboxThickness = kDefaultEdgeHitboxThickness,
    this.rebuildAllChildrenOnWidgetUpdate = true,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd,
    this.onTapDown,
    this.onTap,
    this.onDoubleTapDown,
    this.onDoubleTap,
  }) : assert(cacheExtent >= 0.0),
       assert(edgeHitboxThickness >= 1.0);

  final GraphViewportController<NodeIdType, EdgeIdType> viewportController;
  final NodeBuilder<NodeIdType> nodeBuilder;
  final EdgeBuilder<EdgeIdType> edgeBuilder;
  final GraphViewportTransform transform;
  final GraphStyle? style;
  final double cacheExtent;
  final double edgeHitboxThickness;
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
    final GraphStyle effectiveStyle = style ?? Theme.of(context).extension<GraphStyle>() ?? GraphStyle.fallback();

    return RenderGraphViewport<NodeIdType, EdgeIdType>(
      viewportController: viewportController,
      transform: transform,
      layoutHelper: context as GraphViewportElement<NodeIdType, EdgeIdType>,
      cacheExtent: cacheExtent,
      edgeHitboxThickness: edgeHitboxThickness,
      style: effectiveStyle,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderGraphViewport<NodeIdType, EdgeIdType> renderObject,
  ) {
    final GraphStyle effectiveStyle = style ?? Theme.of(context).extension<GraphStyle>() ?? GraphStyle.fallback();

    renderObject
      ..viewportController = viewportController
      ..transform = transform
      ..cacheExtent = cacheExtent
      ..edgeHitboxThickness = edgeHitboxThickness
      ..style = effectiveStyle;
  }
}
