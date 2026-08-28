import "dart:async";
import "dart:collection";

import "package:flutter/gestures.dart";
import "package:flutter/rendering.dart";
import "package:flutter/widgets.dart";

import "../edge_data.dart";
import "../elements/graph_viewport.dart";
import "../graph_viewport_controller.dart";
import "../graph_viewport_transform.dart";
import "../interaction/drag_details.dart";
import "../node_data.dart";
import "edge.dart";
import "edge_parent_data.dart";
import "graph_child.dart";
import "node.dart";
import "node_parent_data.dart";
import "quad_tree.dart";

class RenderGraphViewport<NodeIdType, EdgeIdType> extends RenderBox {
  static RenderGraphViewport<NodeIdType, EdgeIdType>? maybeOf<NodeIdType, EdgeIdType>(RenderObject? object) {
    while (object != null) {
      if (object is RenderGraphViewport<NodeIdType, EdgeIdType>) {
        return object;
      }
      object = object.parent;
    }
    return null;
  }

  static RenderGraphViewport<NodeIdType, EdgeIdType> of<NodeIdType, EdgeIdType>(RenderObject? object) {
    final RenderGraphViewport<NodeIdType, EdgeIdType>? viewport = maybeOf<NodeIdType, EdgeIdType>(object);
    assert(() {
      if (viewport == null) {
        throw FlutterError(
          "RenderGraphViewport.of() was called with a render object that was "
          "not a descendant of a RenderGraphViewport.\n"
          "No RenderGraphViewport render object ancestor could be found starting "
          "from the object that was passed to RenderGraphViewport.of().\n"
          "The render object where the viewport search started was:\n"
          "  $object",
        );
      }
      return true;
    }());
    return viewport!;
  }

  Offset get globalPaintOffset {
    final translation = getTransformTo(null).getTranslation();

    return Offset(translation.x, translation.y);
  }

  RenderGraphViewport({
    required GraphViewportController<NodeIdType, EdgeIdType> viewportController,
    required GraphViewportTransform transform,
    required GraphViewportLayoutHelper layoutHelper,
    required double cacheExtent,
    required EdgeInsets boundaryInsets,
    required Color backgroundColor,
    required bool debugPaintQuadTree,
  }) : _viewportController = viewportController,
       _transform = transform,
       _layoutHelper = layoutHelper,
       _cacheExtent = cacheExtent,
       _boundaryInsets = boundaryInsets,
       _backgroundColor = backgroundColor,
       _debugPaintQuadTree = debugPaintQuadTree;

  final GraphViewportLayoutHelper _layoutHelper;

  final Map<NodeIdType, GraphNodeRenderObject> _nodes = {};
  final Map<EdgeIdType, GraphEdgeRenderObject> _edges = {};

  late bool _isFirstLayout;

  late final QuadTree<NodeIdType, EdgeIdType> _childQuadTree = QuadTree.fromInnermostQTSize(
    innermostDimension: 100,
    subdivisionSteps: 8,
  );
  final Set<NodeIdType> _nodeIdsNeedingRebuild = {};
  final Set<EdgeIdType> _edgeIdsNeedingRebuild = {};
  final Set<NodeIdType> _nodeIdsNeedingLayout = {};
  final Set<EdgeIdType> _edgeIdsNeedingLayout = {};

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

  double get cacheExtent => _cacheExtent;
  double _cacheExtent;
  set cacheExtent(double value) {
    if (_cacheExtent == value) return;

    _cacheExtent = value;

    markNeedsLayout();
  }

  EdgeInsets get boundaryInsets => _boundaryInsets;
  EdgeInsets _boundaryInsets;
  set boundaryInsets(EdgeInsets value) {
    if (_boundaryInsets == value) return;

    _boundaryInsets = value;

    markNeedsLayout();
  }

  Color get backgroundColor => _backgroundColor;
  Color _backgroundColor;
  set backgroundColor(Color value) {
    if (_backgroundColor == value) return;

    _backgroundColor = value;

    markNeedsPaint();
  }

  bool _debugPaintQuadTree;
  bool get debugPaintQuadTree => _debugPaintQuadTree;
  set debugPaintQuadTree(bool value) {
    if (_debugPaintQuadTree == value) return;

    _debugPaintQuadTree = value;

    markNeedsPaint();
  }

  GraphNodeRenderObject? getNode(NodeIdType nodeId) => _nodes[nodeId];

  GraphEdgeRenderObject? getEdge(EdgeIdType edgeId) => _edges[edgeId];

  void markNodeNeedsRebuild(NodeIdType nodeId) {
    _nodeIdsNeedingRebuild.add(nodeId);
    markNodeNeedsLayout(nodeId);
  }

  void markEdgeNeedsRebuild(EdgeIdType edgeId) {
    _edgeIdsNeedingRebuild.add(edgeId);
    markEdgeNeedsLayout(edgeId);
  }

  @protected
  void markNodeNeedsLayout(NodeIdType nodeId) {
    if (_nodes.containsKey(nodeId)) {
      _nodeIdsNeedingLayout.add(nodeId);
      _nodes[nodeId]!.markNeedsLayout();
    }
    markNeedsLayout();
  }

  @protected
  void markEdgeNeedsLayout(EdgeIdType edgeId) {
    if (_edges.containsKey(edgeId)) {
      _edgeIdsNeedingLayout.add(edgeId);
      _edges[edgeId]!.markNeedsLayout();
    }
    markNeedsLayout();
  }

  void markNeedsLayoutForNodeChange(GraphNodeRenderObject node) {
    final NodeIdType nodeId = _nodes.entries.firstWhere((entry) => entry.value == node).key;

    for (final EdgeIdType edgeId in getConnectingEdgeIds(nodeId)) {
      markEdgeNeedsLayout(edgeId);
    }
    markNeedsLayout();
  }

  Iterable<EdgeIdType> getConnectingEdgeIds(NodeIdType nodeId) {
    return viewportController.allEdges.entries
        .where((edgeEntry) => edgeEntry.value.startNodeId == nodeId || edgeEntry.value.endNodeId == nodeId)
        .map((edgeEntry) => edgeEntry.key);
  }

  void adoptNode(NodeIdType nodeId, GraphNodeRenderObject node) {
    _nodes[nodeId] = node;

    adoptChild(node);
  }

  void adoptEdge(EdgeIdType edgeId, GraphEdgeRenderObject edge) {
    _edges[edgeId] = edge;

    adoptChild(edge);
  }

  void dropNode(NodeIdType nodeId) {
    final GraphNodeRenderObject node = _nodes.remove(nodeId)!;

    dropChild(node);
  }

  void dropEdge(EdgeIdType edgeId) {
    final GraphEdgeRenderObject edge = _edges.remove(edgeId)!;

    dropChild(edge);
  }

  void removeNode(NodeIdType nodeId) {
    _childQuadTree.removeNode(nodeId);
    _nodeIdsNeedingRebuild.remove(nodeId);
    _nodeIdsNeedingLayout.remove(nodeId);
  }

  void removeEdge(EdgeIdType edgeId) {
    _childQuadTree.removeEdge(edgeId);
    _edgeIdsNeedingRebuild.remove(edgeId);
    _edgeIdsNeedingLayout.remove(edgeId);
  }

  GraphViewportNodeParentData _setChildNodeParentData(NodeIdType nodeId, GraphNodeRenderObject node) {
    final NodeData<NodeIdType> nodeData = viewportController.allNodes[nodeId]!;
    final bool isBeingDragged = inFlightNodeIds.contains(nodeId);

    return node.parentData
      ..position = nodeData.position
      ..dragOffset = isBeingDragged ? movingNodeOffset : Offset.zero;
  }

  GraphViewportEdgeParentData _setChildEdgeParentData(EdgeIdType edgeId, GraphEdgeRenderObject edge) {
    final EdgeData<NodeIdType, EdgeIdType> edgeData = viewportController.allEdges[edgeId]!;
    final GraphNodeRenderObject startNode = _nodes[edgeData.startNodeId]!;
    final GraphNodeRenderObject endNode = _nodes[edgeData.endNodeId]!;

    return edge.parentData
      ..startNodeCenter = startNode.parentData.positionWithDragOffset
      ..startNodeSize = startNode.size
      ..startNodeBorderRadius = startNode.borderRadius
      ..endNodeCenter = endNode.parentData.positionWithDragOffset
      ..endNodeSize = endNode.size
      ..endNodeBorderRadius = endNode.borderRadius;
  }

  void markNeedsFirstLayout() {
    markNeedsLayout();
    _isFirstLayout = true;
  }

  void _layoutNode(NodeIdType nodeId, GraphNodeRenderObject node) {
    _nodeIdsNeedingLayout.remove(nodeId);

    _setChildNodeParentData(nodeId, node);
    node.layout(BoxConstraints(), parentUsesSize: true);

    // Only update the QuadTree if this node is not currently moving (e.g. during dragging).
    // Updating in-flight nodes would result in many unnecessary quad tree updates.
    // inFlightNodeIds are layouted even if they are not on screen, so they can safely be excluded from the quad tree.
    if (!inFlightNodeIds.contains(nodeId)) {
      _childQuadTree.putNode(nodeId, node.semanticBounds);
    }
  }

  void _layoutEdge(EdgeIdType edgeId, GraphEdgeRenderObject edge) {
    _edgeIdsNeedingLayout.remove(edgeId);

    _setChildEdgeParentData(edgeId, edge);
    edge.layout(BoxConstraints(), parentUsesSize: true);

    // Only update the QuadTree if this edge is not currently moving (e.g. during dragging).
    // Updating in-flight edges would result in many unnecessary quad tree updates.
    // inFlightEdgeIds are layouted even if they are not on screen, so they can safely be excluded from the quad tree.
    if (!inFlightEdgeIds.contains(edgeId)) {
      _childQuadTree.putEdge(edgeId, edge.linePath);
    }
  }

  late Rect _lastFrameContentRect;

  @override
  void performLayout() {
    if (_isFirstLayout) {
      _isFirstLayout = false;
      // baue alles zum ersten Mal

      _childQuadTree.clear();

      for (final nodeEntry in _nodes.entries) {
        final NodeIdType nodeId = nodeEntry.key;
        final GraphNodeRenderObject node = nodeEntry.value;
        _layoutNode(nodeId, node);
      }

      for (final edgeEntry in _edges.entries) {
        final EdgeIdType edgeId = edgeEntry.key;
        final GraphEdgeRenderObject edge = edgeEntry.value;
        _layoutEdge(edgeId, edge);
      }

      transform.applyContentDimensions(_childQuadTree.contentRect);
      _lastFrameContentRect = _childQuadTree.contentRect;
    }

    if (!hasSize || size != constraints.biggest) {
      size = constraints.biggest;
    }
    transform.applyViewportDimensions(size, boundaryInsets);

    {
      // frage QuadTree, was gerade sichtbar ist und baue nur diese Elemente + aktive ELemente +  die Elemente, die geändert wurden

      _layoutHelper.startLayout();

      final Rect visibleRect = transform.visibleRect.inflate(cacheExtent);

      final Set<NodeIdType> usedNodeIds = {
        ..._childQuadTree.getNodeIdsInRect(visibleRect),
        ...inFlightNodeIds,
        ...animationTargetNodeIds,
        ..._nodeIdsNeedingRebuild,
        ..._nodeIdsNeedingLayout,
      };
      final Set<EdgeIdType> usedEdgeIds = {
        ..._childQuadTree.getEdgeIdsInRect(visibleRect),
        ...inFlightEdgeIds,
        ...animationTargetEdgeIds,
        ..._edgeIdsNeedingRebuild,
        ..._edgeIdsNeedingLayout,
      };

      for (final EdgeIdType edgeId in usedEdgeIds) {
        _reuseOrBuildEdge(edgeId);

        final EdgeData<NodeIdType, EdgeIdType> edgeData = viewportController.allEdges[edgeId]!;

        usedNodeIds.addAll([edgeData.startNodeId, edgeData.endNodeId]);
      }

      for (final NodeIdType nodeId in usedNodeIds) {
        _reuseOrBuildNode(nodeId);
      }

      invokeLayoutCallback((BoxConstraints _) {
        _layoutHelper.endLayout();
      });
    }

    assert(_nodeIdsNeedingRebuild.isEmpty);
    assert(_edgeIdsNeedingRebuild.isEmpty);

    {
      final Rect oldContentRect = _lastFrameContentRect;

      for (final NodeIdType nodeId in _nodes.keys) {
        final GraphNodeRenderObject node = _nodes[nodeId]!;
        _layoutNode(nodeId, node);
      }
      for (final EdgeIdType edgeId in _edges.keys) {
        final GraphEdgeRenderObject edge = _edges[edgeId]!;
        _layoutEdge(edgeId, edge);
      }

      assert(_nodeIdsNeedingLayout.isEmpty);
      assert(_edgeIdsNeedingLayout.isEmpty);

      Rect newContentRect = _childQuadTree.contentRect;
      for (final NodeIdType movingNodeId in inFlightNodeIds) {
        final GraphNodeRenderObject movingNode = _nodes[movingNodeId]!;
        newContentRect = newContentRect.expandToInclude(movingNode.semanticBounds);
      }

      if (oldContentRect != newContentRect) {
        transform.applyContentDimensions(newContentRect);
        _lastFrameContentRect = newContentRect;
      }
    }

    maybeStartShowOnScreenAnimation();
  }

  GraphNodeRenderObject _reuseOrBuildNode(NodeIdType nodeId) {
    final GraphViewportNodeSlot slot = GraphViewportNodeSlot(nodeId);

    assert(
      viewportController.containsNode(nodeId),
      "The node $nodeId was marked for layout but does not exist in the ViewportController.\n"
      "This can happen when a node gets removed via ViewportController.removeNode() but its connecting edges are not.",
    );

    if (!_nodes.containsKey(nodeId) || _nodeIdsNeedingRebuild.contains(nodeId)) {
      invokeLayoutCallback((BoxConstraints _) {
        _layoutHelper.buildChild(slot);
      });

      _nodeIdsNeedingRebuild.remove(nodeId);
    } else {
      _layoutHelper.reuseChild(slot);
    }

    return _nodes[nodeId]!;
  }

  GraphEdgeRenderObject _reuseOrBuildEdge(EdgeIdType edgeId) {
    final GraphViewportEdgeSlot slot = GraphViewportEdgeSlot(edgeId);

    assert(viewportController.containsEdge(edgeId));

    if (!_edges.containsKey(edgeId) || _edgeIdsNeedingRebuild.contains(edgeId)) {
      invokeLayoutCallback((BoxConstraints _) {
        _layoutHelper.buildChild(slot);
      });

      _edgeIdsNeedingRebuild.remove(edgeId);
    } else {
      _layoutHelper.reuseChild(slot);
    }

    return _edges[edgeId]!;
  }

  @override
  void redepthChildren() {
    for (final GraphNodeRenderObject node in _nodes.values) {
      redepthChild(node);
    }
    for (final GraphEdgeRenderObject edge in _edges.values) {
      redepthChild(edge);
    }
  }

  @override
  void applyPaintTransform(covariant RenderObject child, Matrix4 transform) {
    transform.multiply(this.transform.childTransformMatrix);
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
          transform.childTransformMatrix,
          (context, offset) {
            if (debugPaintQuadTree) {
              _childQuadTree.debugPaint(context, offset);
            }

            for (final GraphEdgeRenderObject edge in _edges.values) {
              context.paintChild(edge, offset);
            }

            for (final GraphNodeRenderObject node in _nodes.values) {
              context.paintChild(node, offset);
            }
          },
        );
      },
    );
  }

  @override
  void setupParentData(GraphChildRenderObject child) {
    if (child is GraphEdgeRenderObject && !child.hasParentData) {
      child.parentData = GraphViewportEdgeParentData();
    } else if (child is GraphNodeRenderObject && !child.hasParentData) {
      child.parentData = GraphViewportNodeParentData();
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);

    _viewportController.onAttach(this);

    _isFirstLayout = true;

    transform.addListener(_onTransformChanged);

    for (final GraphEdgeRenderObject edge in _edges.values) {
      edge.attach(owner);
    }

    for (final GraphNodeRenderObject node in _nodes.values) {
      node.attach(owner);
    }
  }

  @override
  void detach() {
    super.detach();

    if (_viewportController.isAttached) {
      _viewportController.onDetach(this);
    }

    transform.removeListener(_onTransformChanged);

    for (final GraphEdgeRenderObject edge in _edges.values) {
      edge.detach();
    }

    for (final GraphNodeRenderObject node in _nodes.values) {
      node.detach();
    }
  }

  void _onTransformChanged() {
    // mark all moving nodes and edges as needing layout
    for (final NodeIdType nodeId in inFlightNodeIds) {
      _nodes[nodeId]!.markNeedsLayout();
    }
    for (final EdgeIdType edgeId in inFlightEdgeIds) {
      _edges[edgeId]!.markNeedsLayout();
    }

    markNeedsLayout();
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    for (final GraphNodeRenderObject node in _nodes.values) {
      visitor(node);
    }
    for (final GraphEdgeRenderObject edge in _edges.values) {
      visitor(edge);
    }
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return [
      ..._nodes.values.map((node) => node.toDiagnosticsNode()),
      ..._edges.values.map((edge) => edge.toDiagnosticsNode()),
    ];
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  bool hitTestSelf(Offset position) {
    return size.contains(position);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return result.addWithPaintTransform(
      transform: transform.childTransformMatrix,
      position: position,
      hitTest: (result, position) {
        final List<GraphNodeRenderObject> nodes = _nodes.values.toList();
        for (final GraphNodeRenderObject node in nodes.reversed) {
          result.addWithPaintOffset(
            offset: node.parentData.positionWithDragOffset,
            position: position,
            hitTest: node.hitTest,
          );
        }

        final List<(GraphEdgeRenderObject, double)> edgesWithDist = _edges.values
            .map((edge) {
              return (edge, edge.getDistanceSquaredTo(position));
            })
            .where((edgeDist) => edgeDist.$2 != null)
            .map((edgeDist) => (edgeDist.$1, edgeDist.$2!))
            .toList();
        edgesWithDist.sort((edgeDist1, edgeDist2) => edgeDist1.$2.compareTo(edgeDist2.$2));

        for (final GraphEdgeRenderObject edge in edgesWithDist.map((edgeDist) => edgeDist.$1)) {
          edge.hitTest(result, position);
        }

        return true;
      },
    );
  }

  PointerDownEventListener? onPointerDown;
  PointerPanZoomStartEventListener? onPointerPanZoomStart;
  PointerSignalEventListener? onPointerSignal;

  @override
  void handleEvent(PointerEvent event, covariant HitTestEntry<HitTestTarget> entry) {
    return switch (event) {
      PointerDownEvent() => onPointerDown?.call(event),
      PointerPanZoomStartEvent() => onPointerPanZoomStart?.call(event),
      PointerSignalEvent() => onPointerSignal?.call(event),
      _ => null,
    };
  }

  Offset _startingViewportPosition = Offset.zero;

  Offset _startingPointerViewportPosition = Offset.zero;
  Offset _pointerViewportPosition = Offset.zero;

  bool _isDraggingNodes = false;

  Set<NodeIdType> _movingNodeIds = {};

  /// The NodeIds that are marked for being moved when dragging a Node.
  UnmodifiableSetView<NodeIdType> get movingNodeIds => UnmodifiableSetView(_movingNodeIds);

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
      UnmodifiableSetView(Set.from(_showOnScreenAnimationData?.targetNodeIds ?? const {}));

  UnmodifiableSetView<EdgeIdType> get animationTargetEdgeIds =>
      UnmodifiableSetView(Set.from(_showOnScreenAnimationData?.targetEdgeIds ?? const {}));

  Offset get movingNodeOffset => (_isDraggingNodes && movingNodeIds.isNotEmpty)
      ? (_transform.position - _startingViewportPosition) +
            ((_pointerViewportPosition - _startingPointerViewportPosition) / _transform.scale)
      : Offset.zero;

  _ShowOnScreenAnimationData<NodeIdType, EdgeIdType>? _showOnScreenAnimationData;

  void onNodeDragDown(GraphViewportDragDownDetails details) {
    transform.onNodeDragDown(details);

    _startingViewportPosition = _transform.position;
    _startingPointerViewportPosition = details.viewportPosition;
    _pointerViewportPosition = details.viewportPosition;
  }

  void onNodeDragStart(GraphViewportDragStartDetails details) {
    transform.onNodeDragStart(details);

    _isDraggingNodes = true;
  }

  void onNodeDragUpdate(GraphViewportDragUpdateDetails details) {
    transform.onNodeDragUpdate(details);

    _pointerViewportPosition = details.viewportPosition;

    for (final NodeIdType nodeId in inFlightNodeIds) {
      markNodeNeedsLayout(nodeId);
    }
    for (final EdgeIdType edgeId in inFlightEdgeIds) {
      markEdgeNeedsLayout(edgeId);
    }

    markNeedsLayout();
  }

  void onNodeDragEnd(GraphViewportDragEndDetails details) {
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
  }

  @protected
  void maybeStartShowOnScreenAnimation() {
    assert(
      debugDoingThisLayout,
      "RenderGraphViewportBase.maybeStartShowOnScreenAnimation should only be called from performLayout()",
    );

    if (_showOnScreenAnimationData == null) return;
    if (_isDraggingNodes) return;

    final animationData = _showOnScreenAnimationData!;
    _showOnScreenAnimationData = null;

    final Set<GraphChildRenderObject> targetRenderObjects = {
      ...animationData.targetNodeIds.map((nodeId) => getNode(nodeId)!),
      ...animationData.targetEdgeIds.map((edgeId) => getEdge(edgeId)!),
    };

    final Rect? targetGraphSpaceRect = targetRenderObjects.fold(
      null,
      (Rect? previousValue, GraphChildRenderObject childRenderObject) {
        final Rect childRect = childRenderObject.paintBounds;
        return previousValue?.expandToInclude(childRect) ?? childRect;
      },
    );

    if (targetGraphSpaceRect == null) return;

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
      targetNodeIds: nodeIds,

      padding: padding,
      margin: margin,
      duration: duration,
      curve: curve,
    );

    markNeedsLayout();

    return completer.future;
  }

  /// {@template render_graph_viewport_base.show_edges_on_screen}
  /// Animate the given [edgeIds] to be visible in the viewport.
  ///
  /// [margin] defines the insets _(in screen space)_ of the viewport that are obscured by overlaying UI elements (e.g.
  /// toolbars or sidebars). Defaults to [EdgeInsets.zero].
  /// [padding] defines how far _(in screen space)_ from the ([margin]-adjusted) viewport edges the target edges should
  /// be inset by. Defaults to [EdgeInsets.zero].
  ///
  /// [duration] and [curve] together define the animation of the movement. [duration] defaults to [Duration.zero].
  /// [curve] defaults to [Curves.linear].
  ///
  /// Returns a [Future] that resolves to `true` when the target was fully reached, and `false` if the animation was
  /// stopped prematurely - e.g. because the user initiated a drag.
  /// {@endtemplate}
  Future<bool> showEdgesOnScreen(
    Set<EdgeIdType> edgeIds, {
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
      targetEdgeIds: edgeIds,
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

    assert(descendant is GraphChildRenderObject);

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
class _ShowOnScreenAnimationData<NodeIdType, EdgeIdType> {
  const _ShowOnScreenAnimationData({
    required this.completer,
    this.targetNodeIds = const {},
    this.targetEdgeIds = const {},
    required this.padding,
    required this.margin,
    required this.duration,
    required this.curve,
  });

  final Completer<bool> completer;
  final Set<NodeIdType> targetNodeIds;
  final Set<EdgeIdType> targetEdgeIds;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final Duration duration;
  final Curve curve;
}
