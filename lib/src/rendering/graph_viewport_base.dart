import "dart:async";
import "dart:collection";

import "package:flutter/widgets.dart";

import "../graph_viewport_controller.dart";
import "../graph_viewport_transform.dart";
import "../interaction/drag_details.dart";
import "../rendering/graph_element.dart";
import "edge.dart";
import "node.dart";

abstract class RenderGraphViewportBase<NodeIdType, EdgeIdType> extends RenderBox {
  static RenderGraphViewportBase<NodeIdType, EdgeIdType>? maybeOf<NodeIdType, EdgeIdType>(RenderObject? object) {
    while (object != null) {
      if (object is RenderGraphViewportBase<NodeIdType, EdgeIdType>) {
        return object;
      }
      object = object.parent;
    }
    return null;
  }

  static RenderGraphViewportBase<NodeIdType, EdgeIdType> of<NodeIdType, EdgeIdType>(RenderObject? object) {
    final RenderGraphViewportBase<NodeIdType, EdgeIdType>? viewport = maybeOf<NodeIdType, EdgeIdType>(object);
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
    required GraphViewportController<NodeIdType, EdgeIdType> viewportController,
    required GraphViewportTransform transform,
  }) : _viewportController = viewportController,
       _transform = transform {
    _viewportController.onAttach(this);
  }

  GraphViewportController<NodeIdType, EdgeIdType> get viewportController => _viewportController;
  GraphViewportController<NodeIdType, EdgeIdType> _viewportController;
  set viewportController(GraphViewportController<NodeIdType, EdgeIdType> value) {
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
  NodeIdType? _dragDownNodeId;

  /// The NodeIds that are marked for being moved when dragging a Node.
  UnmodifiableSetView<NodeIdType> get movingNodeIds => UnmodifiableSetView({..._movingNodeIds, ?_dragDownNodeId});

  /// The NodeIds that are marked for being moved when dragging a Node.
  set movingNodeIds(Set<NodeIdType> value) => _movingNodeIds = Set.from(value);

  @protected
  UnmodifiableSetView<NodeIdType> get inFlightNodeIds =>
      UnmodifiableSetView(_isDraggingNodes ? Set.from(movingNodeIds) : const {});

  @protected
  UnmodifiableSetView<EdgeIdType> get inFlightEdgeIds => UnmodifiableSetView(
    _isDraggingNodes ? Set.from(movingNodeIds.expand((nodeId) => getConnectingEdgeIds(nodeId))) : const {},
  );

  UnmodifiableSetView<NodeIdType> get animationTargetNodeIds =>
      UnmodifiableSetView(Set.from(_showOnScreenAnimationData?.animationTargetNodeIds ?? const {}));

  Offset get movingNodeOffset => (_isDraggingNodes && movingNodeIds.isNotEmpty)
      ? (_transform.position - _startingViewportPosition) +
            ((_pointerScreenPosition - _startingPointerScreenPosition) / _transform.scale)
      : Offset.zero;

  void onNodeDragDown(NodeDragDownDetails details, NodeIdType nodeId) {
    transform.onNodeDragDown(details);

    _startingViewportPosition = _transform.position;
    _startingPointerScreenPosition = details.parentSpacePosition;
    _pointerScreenPosition = details.parentSpacePosition;
    _dragDownNodeId = nodeId;
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

    final Set<NodeIdType> movedNodeIds = Set.from(movingNodeIds);
    final Offset dragOffset = movingNodeOffset;

    _isDraggingNodes = false;
    _dragDownNodeId = null;

    _viewportController.notifyNodesMoved(movedNodeIds, dragOffset);
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
    _dragDownNodeId = null;
  }

  GraphNodeRenderObject? getNode(NodeIdType nodeId);
  GraphEdgeRenderObject? getEdge(EdgeIdType nodeId);

  void markNodeNeedsRebuild(NodeIdType nodeId);
  void markEdgeNeedsRebuild(EdgeIdType edgeId);

  @protected
  void markNodeNeedsLayout(NodeIdType nodeId);
  @protected
  void markEdgeNeedsLayout(EdgeIdType edgeId);

  @protected
  Iterable<EdgeIdType> getConnectingEdgeIds(NodeIdType nodeId);

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
    if (_isDraggingNodes) return;

    final Set<GraphNodeRenderObject> targetNodeRenderObjects = _showOnScreenAnimationData!.animationTargetNodeIds
        .map((nodeId) => getNode(nodeId)!)
        .toSet();

    final Rect? targetGraphSpaceRect = targetNodeRenderObjects.fold(
      null,
      (Rect? previousValue, GraphNodeRenderObject nodeRenderObject) {
        final Rect nodeRect = nodeRenderObject.paintBounds;
        return previousValue?.expandToInclude(nodeRect) ?? nodeRect;
      },
    );

    if (targetGraphSpaceRect == null) return;

    final animationData = _showOnScreenAnimationData!;
    _showOnScreenAnimationData = null;

    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) async {
        try {
          final bool finished = await transform.showInViewport(
            targetRect: targetGraphSpaceRect,
            margin: animationData.margin,
            padding: animationData.padding,
            duration: animationData.duration,
            curve: animationData.curve,
          );
          animationData.completer.complete(finished);
        } catch (err) {
          animationData.completer.completeError(err);
        }
      },
    );
  }

  /// {@template render_graph_viewport_base.show_nodes_on_screen}
  /// Animate the given [nodeIds] to be visible in the viewport.
  ///
  /// [margin] defines the insets _(in screen space)_ of the viewport that are obscured by overlaying UI elements (e.g.
  /// toolbars or sidebars). Defaults to [EdgeInsets.zero].
  /// [padding] defines how far _(in screen space)_ from the ([margin]-adjusted) viewport edges the target nodes should
  /// be inset by. Defaults to [EdgeInsets.zero].
  ///
  /// [duration] and [curve] together define the animation of the movement. [duration] defaults to [Duration.zero].
  /// [curve] defaults to [Curves.linear].
  ///
  /// Returns a [Future] that resolves to `true` when the target was fully reached, and `false` if the animation was
  /// stopped prematurely - e.g. because the user initiated a drag.
  /// {@endtemplate}
  Future<bool> showNodesOnScreen(
    Set<NodeIdType> nodeIds, {
    EdgeInsets margin = EdgeInsets.zero,
    EdgeInsets padding = EdgeInsets.zero,
    Duration duration = Duration.zero,
    Curve curve = Curves.linear,
  }) async {
    if (_showOnScreenAnimationData != null) {
      _showOnScreenAnimationData!.completer.complete(false);
    }

    final Completer<bool> completer = Completer();

    _showOnScreenAnimationData = _ShowOnScreenAnimationData(
      completer: completer,
      animationTargetNodeIds: nodeIds,
      padding: padding,
      margin: margin,
      duration: duration,
      curve: curve,
    );

    markNeedsLayout();

    return completer.future;
  }

  @override
  void showOnScreen({
    RenderObject? descendant,
    Rect? rect,
    EdgeInsets margin = EdgeInsets.zero,
    EdgeInsets padding = EdgeInsets.zero,
    Duration duration = Duration.zero,
    Curve curve = Curves.linear,
  }) {
    if (descendant == null) {
      return super.showOnScreen(descendant: descendant, rect: rect, duration: duration, curve: curve);
    }

    assert(descendant is GraphElementRenderObject);

    transform.showInViewport(
      targetRect: rect ?? descendant.paintBounds,
      margin: margin,
      padding: padding,
      duration: duration,
      curve: curve,
    );
  }
}

@immutable
class _ShowOnScreenAnimationData<NodeIdType> {
  const _ShowOnScreenAnimationData({
    required this.completer,
    required this.animationTargetNodeIds,
    required this.padding,
    required this.margin,
    required this.duration,
    required this.curve,
  });

  final Completer<bool> completer;
  final Set<NodeIdType> animationTargetNodeIds;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final Duration duration;
  final Curve curve;
}
