import "dart:async";
import "dart:collection";

import "package:flutter/widgets.dart";

import "../edge_data.dart";
import "../node_data.dart";
import "../drag_details.dart";
import "../graph_viewport_controller.dart";
import "../graph_viewport_transform.dart";
import "edge.dart";
import "node.dart";

abstract class RenderGraphViewportBase<
  NodeIdType,
  NodeDataType extends NodeData<NodeIdType>,
  EdgeIdType,
  EdgeDataType extends EdgeData<EdgeIdType, NodeIdType>
>
    extends RenderBox {
  static RenderGraphViewportBase<NodeIdType, NodeDataType, EdgeIdType, EdgeDataType>? maybeOf<
    NodeIdType,
    NodeDataType extends NodeData<NodeIdType>,
    EdgeIdType,
    EdgeDataType extends EdgeData<EdgeIdType, NodeIdType>
  >(RenderObject? object) {
    while (object != null) {
      if (object is RenderGraphViewportBase<NodeIdType, NodeDataType, EdgeIdType, EdgeDataType>) {
        return object;
      }
      object = object.parent;
    }
    return null;
  }

  static RenderGraphViewportBase<NodeIdType, NodeDataType, EdgeIdType, EdgeDataType> of<
    NodeIdType,
    NodeDataType extends NodeData<NodeIdType>,
    EdgeIdType,
    EdgeDataType extends EdgeData<EdgeIdType, NodeIdType>
  >(RenderObject? object) {
    final RenderGraphViewportBase<NodeIdType, NodeDataType, EdgeIdType, EdgeDataType>? viewport =
        maybeOf<NodeIdType, NodeDataType, EdgeIdType, EdgeDataType>(object);
    assert(() {
      if (viewport == null) {
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
    return viewport!;
  }

  RenderGraphViewportBase({
    required GraphViewportController<NodeIdType, NodeDataType, EdgeIdType, EdgeDataType> viewportController,
    required GraphViewportTransform transform,
  }) : _viewportController = viewportController,
       _transform = transform {
    _viewportController.onAttach(this);
  }

  GraphViewportController<NodeIdType, NodeDataType, EdgeIdType, EdgeDataType> get viewportController =>
      _viewportController;
  GraphViewportController<NodeIdType, NodeDataType, EdgeIdType, EdgeDataType> _viewportController;
  set viewportController(GraphViewportController<NodeIdType, NodeDataType, EdgeIdType, EdgeDataType> value) {
    if (_viewportController == value) return;

    assert(_viewportController.isAttached);
    assert(!value.isAttached);

    _viewportController.onDetach(this);

    _viewportController = value;

    value.onAttach(this);

    markNeedsLayout();
  }

  GraphViewportTransform get transform => _transform;
  GraphViewportTransform _transform;
  set transform(GraphViewportTransform value) {
    if (_transform == value) return;

    _transform.removeListener(markNeedsLayout);
    value.addListener(markNeedsLayout);

    _transform = value;

    markNeedsLayout();
  }

  Offset _startingViewportPosition = Offset.zero;

  Offset _startingPointerScreenPosition = Offset.zero;
  Offset _pointerScreenPosition = Offset.zero;

  bool _isDraggingNodes = false;

  Set<NodeIdType> _movingNodeIds = {};

  /// The NodeIds that are marked for being moved when dragging a Node.
  UnmodifiableSetView<NodeIdType> get movingNodeIds => UnmodifiableSetView(_movingNodeIds);

  /// The NodeIds that are marked for being moved when dragging a Node.
  set movingNodeIds(Set<NodeIdType> value) => _movingNodeIds = Set.from(value);

  @protected
  UnmodifiableSetView<NodeIdType> get inFlightNodeIds =>
      UnmodifiableSetView(_isDraggingNodes ? Set.from(_movingNodeIds) : const {});

  @protected
  UnmodifiableSetView<EdgeIdType> get inFlightEdgeIds => UnmodifiableSetView(
    _isDraggingNodes
        ? Set.from(_movingNodeIds.expand((nodeId) => _viewportController.getConnectingEdgeIds(nodeId)))
        : const {},
  );

  UnmodifiableSetView<NodeIdType> get animationTargetNodeIds =>
      UnmodifiableSetView(Set.from(_showOnScreenAnimationData?.animationTargetNodeIds ?? const {}));

  Offset get movingNodeOffset => (_isDraggingNodes && _movingNodeIds.isNotEmpty)
      ? (_transform.position - _startingViewportPosition) +
            ((_pointerScreenPosition - _startingPointerScreenPosition) / _transform.scale)
      : Offset.zero;

  void onNodeDragDown(NodeDragDownDetails details) {
    transform.onNodeDragDown(details);

    _startingViewportPosition = _transform.position;
    _startingPointerScreenPosition = details.parentSpacePosition;
    _pointerScreenPosition = details.parentSpacePosition;
  }

  void onNodeDragStart(NodeDragStartDetails details) {
    transform.onNodeDragStart(details);

    _isDraggingNodes = true;
  }

  void onNodeDragUpdate(NodeDragUpdateDetails details) {
    transform.onNodeDragUpdate(details);

    if (details.hasMoved) {
      _pointerScreenPosition = details.parentSpacePosition;

      for (final NodeIdType nodeId in inFlightNodeIds) {
        markNodeNeedsLayout(nodeId);
      }
      for (final EdgeIdType edgeId in inFlightEdgeIds) {
        markEdgeNeedsLayout(edgeId);
      }

      markNeedsLayout();
    }
  }

  void onNodeDragEnd(NodeDragEndDetails details) {
    transform.onNodeDragEnd(details);

    for (final NodeIdType nodeId in inFlightNodeIds) {
      markNodeNeedsLayout(nodeId);
    }
    for (final EdgeIdType edgeId in inFlightEdgeIds) {
      markEdgeNeedsLayout(edgeId);
    }

    markNeedsLayout();

    _isDraggingNodes = false;
  }

  void onNodeDragCancel() {
    transform.onNodeDragCancel();

    for (final NodeIdType nodeId in inFlightNodeIds) {
      markNodeNeedsLayout(nodeId);
    }
    for (final EdgeIdType edgeId in inFlightEdgeIds) {
      markEdgeNeedsLayout(edgeId);
    }

    markNeedsLayout();

    _isDraggingNodes = false;
  }

  GraphNodeRenderObject? getNode(NodeIdType nodeId);
  GraphEdgeRenderObject? getEdge(EdgeIdType nodeId);

  @protected
  void markNodeNeedsRebuild(NodeIdType nodeId);
  @protected
  void markEdgeNeedsRebuild(EdgeIdType edgeId);

  @protected
  void markNodeNeedsLayout(NodeIdType nodeId);
  @protected
  void markEdgeNeedsLayout(EdgeIdType edgeId);

  Offset get globalPaintOffset {
    final translation = getTransformTo(null).getTranslation();

    return Offset(translation.x, translation.y);
  }

  NodeDragDownDetails convertDragDownDetails(DragDownDetails details) {
    return NodeDragDownDetails(
      parentSpacePosition: details.globalPosition - globalPaintOffset,
      graphSpacePosition: details.localPosition,
    );
  }

  NodeDragStartDetails convertDragStartDetails(DragStartDetails details) {
    return NodeDragStartDetails(
      parentSpacePosition: details.globalPosition - globalPaintOffset,
      graphSpacePosition: details.localPosition,
    );
  }

  NodeDragUpdateDetails convertDragUpdateDetails(DragUpdateDetails details) {
    return NodeDragUpdateDetails(
      parentSpacePosition: details.globalPosition - globalPaintOffset,
      graphSpacePosition: details.localPosition,
      parentSpaceDelta: details.delta / transform.scale,
      graphSpaceDelta: details.delta,
    );
  }

  NodeDragEndDetails convertDragEndDetails(DragEndDetails details) {
    return NodeDragEndDetails();
  }

  _ShowOnScreenAnimationData? _showOnScreenAnimationData;

  @protected
  void maybeStartShowOnScreenAnimation() {
    assert(
      debugDoingThisLayout,
      "RenderGraphViewportBase.maybeStartShowOnScreenAnimation should only be called from performLayout()",
    );

    if (_showOnScreenAnimationData == null) return;

    final Set<GraphNodeRenderObject> targetNodeRenderObjects = _showOnScreenAnimationData!.animationTargetNodeIds
        .map((nodeId) => getNode(nodeId)!)
        .toSet();

    final Rect? targetGraphSpaceRect = targetNodeRenderObjects.fold(
      null,
      (Rect? previousValue, GraphNodeRenderObject nodeRenderObject) {
        final Offset nodePosition = nodeRenderObject.position;
        final Size nodeSize = nodeRenderObject.size;
        final Rect nodeRect = Rect.fromCenter(center: nodePosition, width: nodeSize.width, height: nodeSize.height);

        if (previousValue == null) {
          return nodeRect;
        } else {
          return previousValue.expandToInclude(nodeRect);
        }
      },
    );

    if (targetGraphSpaceRect == null) return;

    final completer = _showOnScreenAnimationData!.completer;
    final padding = _showOnScreenAnimationData!.padding;
    final margin = _showOnScreenAnimationData!.margin;
    final behavior = _showOnScreenAnimationData!.behavior;
    final duration = _showOnScreenAnimationData!.duration;
    final curve = _showOnScreenAnimationData!.curve;

    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) async {
        try {
          await transform.showInViewport(
            targetRect_GS: targetGraphSpaceRect,
            padding: padding,
            margin: margin,
            behavior: behavior,
            duration: duration,
            curve: curve,
          );
          completer.complete();
        } catch (err) {
          completer.completeError(err);
        }
      },
    );

    _showOnScreenAnimationData = null;
  }

  Future<void> showNodesOnScreen(
    Set<NodeIdType> nodeIds, {
    EdgeInsets padding = EdgeInsets.zero,
    EdgeInsets margin = EdgeInsets.zero,
    GraphViewportBehaviorResolver? behavior,
    Duration? duration,
    Curve? curve,
  }) async {
    assert(_showOnScreenAnimationData == null);

    final Completer completer = Completer();

    _showOnScreenAnimationData = _ShowOnScreenAnimationData(
      completer: completer,
      animationTargetNodeIds: nodeIds,
      padding: padding,
      margin: margin,
      behavior: behavior,
      duration: duration,
      curve: curve,
    );

    markNeedsLayout();

    await completer.future;
  }
}

class _ShowOnScreenAnimationData<NodeIdType> {
  const _ShowOnScreenAnimationData({
    required this.completer,
    required this.animationTargetNodeIds,
    required this.padding,
    required this.margin,
    required this.behavior,
    required this.duration,
    required this.curve,
  });

  final Completer completer;
  final Set<NodeIdType> animationTargetNodeIds;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final GraphViewportBehaviorResolver? behavior;
  final Duration? duration;
  final Curve? curve;
}
