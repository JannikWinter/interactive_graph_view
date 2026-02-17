import "package:flutter/gestures.dart";
import "package:flutter/material.dart";

import "../edge_data.dart";
import "../elements/graph_viewport.dart";
import "../graph_viewport_controller.dart";
import "../graph_viewport_transform.dart";
import "../node_data.dart";
import "../render_objects/graph_viewport.dart";
import "edge.dart";
import "node.dart";

typedef NodeBuilder<NodeIdType> = NodeWidget Function(BuildContext context, NodeIdType nodeId);
typedef EdgeBuilder<EdgeIdType> = EdgeWidget Function(BuildContext context, EdgeIdType edgeId);

class GraphViewport<
  NodeIdType,
  NodeDataType extends NodeData<NodeIdType>,
  EdgeIdType,
  EdgeDataType extends EdgeData<EdgeIdType, NodeIdType>
>
    extends RenderObjectWidget {
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

  final GraphViewportController<NodeIdType, NodeDataType, EdgeIdType, EdgeDataType> viewportController;
  final NodeBuilder<NodeIdType> nodeBuilder;
  final EdgeBuilder<EdgeIdType> edgeBuilder;
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
    return GraphViewportElement<NodeIdType, NodeDataType, EdgeIdType, EdgeDataType>(this);
  }

  @override
  RenderGraphViewport<NodeIdType, NodeDataType, EdgeIdType, EdgeDataType> createRenderObject(BuildContext context) {
    return RenderGraphViewport<NodeIdType, NodeDataType, EdgeIdType, EdgeDataType>(
      viewportController: viewportController,
      transform: transform,
      layoutHelper: context as GraphViewportElement<NodeIdType, NodeDataType, EdgeIdType, EdgeDataType>,
      cacheExtent: cacheExtent,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderGraphViewport<NodeIdType, NodeDataType, EdgeIdType, EdgeDataType> renderObject,
  ) {
    renderObject
      ..viewportController = viewportController
      ..transform = transform
      ..cacheExtent = cacheExtent;
  }
}
