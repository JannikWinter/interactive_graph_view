import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";

import "../config.dart";
import "../elements/graph_viewport.dart";
import "../graph_viewport_transform.dart";
import "../parent_data.dart";
import "../quad_tree.dart";
import "edge.dart";
import "graph_element.dart";
import "graph_viewport_base.dart";
import "node.dart";

class RenderGraphViewport<NodeIdType, EdgeIdType> extends RenderGraphViewportBase<NodeIdType, EdgeIdType> {
  RenderGraphViewport({
    required super.viewportController,
    required super.transform,
    required GraphViewportLayoutHelper layoutHelper,
    required double cacheExtent,
  }) : _layoutHelper = layoutHelper,
       _cacheExtent = cacheExtent;

  final GraphViewportLayoutHelper _layoutHelper;

  final Map<NodeIdType, GraphNodeRenderObject> _nodes = {};
  final Map<EdgeIdType, GraphEdgeRenderObject> _edges = {};

  late bool _isFirstLayout;

  final QuadTree _childQuadTree = QuadTree();
  final Set<NodeIdType> _nodeIdsNeedingRebuild = {};
  final Set<EdgeIdType> _edgeIdsNeedingRebuild = {};

  double get cacheExtent => _cacheExtent;
  double _cacheExtent;
  set cacheExtent(double value) {
    if (_cacheExtent == value) return;

    _cacheExtent = value;

    markNeedsLayout();
  }

  @override
  GraphNodeRenderObject? getNode(NodeIdType nodeId) => _nodes[nodeId];

  @override
  GraphEdgeRenderObject? getEdge(EdgeIdType edgeId) => _edges[edgeId];

  @protected
  @override
  void markNodeNeedsRebuild(NodeIdType nodeId) {
    _nodeIdsNeedingRebuild.add(nodeId);
  }

  @protected
  @override
  void markEdgeNeedsRebuild(EdgeIdType edgeId) {
    _edgeIdsNeedingRebuild.add(edgeId);
  }

  @protected
  @override
  void markNodeNeedsLayout(NodeIdType nodeId) {
    assert(_nodes.containsKey(nodeId));
    _nodes[nodeId]!.markNeedsLayout();
  }

  @protected
  @override
  void markEdgeNeedsLayout(EdgeIdType edgeId) {
    assert(_edges.containsKey(edgeId));
    _edges[edgeId]!.markNeedsLayout();
  }

  void insertNode(GraphNodeRenderObject node, NodeIdType nodeId) {
    _nodes[nodeId] = node;

    adoptChild(node);
  }

  void insertEdge(GraphEdgeRenderObject edge, EdgeIdType edgeId) {
    _edges[edgeId] = edge;

    adoptChild(edge);
  }

  void removeNode(NodeIdType nodeId) {
    final GraphNodeRenderObject node = _nodes.remove(nodeId)!;

    dropChild(node);
  }

  void removeEdge(EdgeIdType edgeId) {
    final GraphEdgeRenderObject edge = _edges.remove(edgeId)!;

    dropChild(edge);
  }

  GraphViewportNodeParentData _setChildNodeParentData(NodeIdType nodeId, GraphNodeRenderObject node) {
    final GraphViewportNodeParentData nodeParentData = node.parentData! as GraphViewportNodeParentData;

    final ViewNode viewNode = viewportController.getNode(nodeId)!;

    nodeParentData.position = viewNode.position;

    if (movingNodeIds.contains(nodeId)) {
      nodeParentData.dragOffset = movingNodeOffset;
    } else {
      nodeParentData.dragOffset = Offset.zero;
    }

    return nodeParentData;
  }

  GraphViewportEdgeParentData _setChildEdgeParentData(EdgeIdType edgeId, GraphEdgeRenderObject edge) {
    final GraphViewportEdgeParentData edgeParentData = edge.parentData! as GraphViewportEdgeParentData;

    final ViewEdge viewEdge = viewportController.getEdge(edgeId)!;

    final GraphNodeRenderObject startNode = _nodes[viewEdge.startNodeId]!;
    final GraphNodeRenderObject endNode = _nodes[viewEdge.endNodeId]!;

    edgeParentData
      ..startNodeCenter = startNode.position
      ..startNodeSize = startNode.size
      ..startNodeBorderRadius = startNode.borderRadius
      ..endNodeCenter = endNode.position
      ..endNodeSize = endNode.size
      ..endNodeBorderRadius = endNode.borderRadius;

    return edgeParentData;
  }

  void markNeedsFirstLayout() {
    markNeedsLayout();
    _isFirstLayout = true;
  }

  void _layoutNode(NodeIdType nodeId, GraphNodeRenderObject node) {
    _setChildNodeParentData(nodeId, node);
    node.layout(BoxConstraints(), parentUsesSize: true);

    // Remove from QuadTree if this node is currently moving (e.g. during dragging).
    // Not removing a moving node here might result in many unnecessary quadtree updates.
    // movingNodeIds are layouted even if they are not on screen, so they can safely be excluded from the quad tree.
    if (movingNodeIds.contains(nodeId)) {
      _childQuadTree.removeNode(nodeId);
    } else {
      _childQuadTree.putNode(nodeId, node.semanticBounds);
    }
  }

  void _layoutEdge(EdgeIdType edgeId, GraphEdgeRenderObject edge) {
    _setChildEdgeParentData(edgeId, edge);
    edge.layout(BoxConstraints(), parentUsesSize: true);

    // Remove from QuadTree if this edge is currently moving (e.g. during dragging).
    // Not removing a moving edges here might result in many unnecessary quadtree updates.
    // movingEdgeIds are layouted even if they are not on screen, so they can safely be excluded from the quad tree.
    if (movingEdgeIds.contains(edgeId)) {
      _childQuadTree.removeEdge(edgeId);
    } else {
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
      transform.applyViewportDimensions(size, Config.graphMinScale, Config.graphMaxScale);
    }

    {
      // frage QuadTree, was gerade sichtbar ist und baue nur diese Elemente + aktive ELemente +  die Elemente, die geändert wurden

      _layoutHelper.startLayout();

      final Rect visibleRect = transform.visibleRect.inflate(cacheExtent);

      final Set<NodeIdType> usedNodeIds = {
        ..._childQuadTree.getNodeIdsInRect(visibleRect),
        ...movingNodeIds,
        ...animationTargetNodeIds,
        ..._nodeIdsNeedingRebuild,
      };
      final Set<EdgeIdType> usedEdgeIds = {
        ..._childQuadTree.getEdgeIdsInRect(visibleRect),
        ...movingEdgeIds,
        ..._edgeIdsNeedingRebuild,
      };

      for (final EdgeIdType edgeId in usedEdgeIds) {
        _reuseOrBuildEdge(edgeId);

        final ViewEdge edge = viewportController.getEdge(edgeId)!;
        usedNodeIds.addAll([edge.startNodeId, edge.endNodeId]);
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

      Rect newContentRect = _childQuadTree.contentRect;
      for (final NodeIdType movingNodeId in movingNodeIds) {
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
    context.canvas.drawColor(Colors.black, BlendMode.src);

    context.pushTransform(
      needsCompositing,
      offset,
      transform.childTransformMatrix,
      (context, offset) {
        // _childQuadTree.debugPaint(context, offset);

        for (final GraphEdgeRenderObject edge in _edges.values) {
          context.paintChild(edge, offset);
        }

        for (final GraphNodeRenderObject node in _nodes.values) {
          context.paintChild(node, offset);
        }
      },
    );
  }

  @override
  void setupParentData(GraphElementRenderObject child) {
    if (child is GraphEdgeRenderObject && child.parentData is! GraphViewportEdgeParentData) {
      child.parentData = GraphViewportEdgeParentData();
    } else if (child is GraphNodeRenderObject && child.parentData is! GraphViewportNodeParentData) {
      child.parentData = GraphViewportNodeParentData();
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);

    _isFirstLayout = true;

    transform.addListener(_onTransformChanged);
    viewportController.addNodeListener(_onNodeChanged);
    viewportController.addEdgeListener(_onEdgeChanged);

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

    transform.removeListener(markNeedsLayout);
    viewportController.removeNodeListener(_onNodeChanged);
    viewportController.removeEdgeListener(_onEdgeChanged);

    for (final GraphEdgeRenderObject edge in _edges.values) {
      edge.detach();
    }

    for (final GraphNodeRenderObject node in _nodes.values) {
      node.detach();
    }
  }

  void _onTransformChanged() {
    // mark all moving nodes and edges as needing layout
    for (final NodeIdType nodeId in movingNodeIds) {
      _nodes[nodeId]!.markNeedsLayout();
    }
    for (final EdgeIdType edgeId in movingEdgeIds) {
      _edges[edgeId]!.markNeedsLayout();
    }

    markNeedsLayout();
  }

  void _onNodeChanged(NodeIdType nodeId, ViewNode? previous, ViewNode? next) {
    if (next == null) {
      _childQuadTree.removeNode(nodeId);
    } else {
      _nodeIdsNeedingRebuild.add(nodeId);
      for (final EdgeIdType edgeId in viewportController.getConnectingEdgeIds(nodeId)) {
        final GraphEdgeRenderObject? edge = _edges[edgeId];
        if (edge != null) {
          edge.markNeedsLayout();
        } else {
          _edgeIdsNeedingRebuild.add(edgeId);
        }
      }
    }

    markNeedsLayout();
  }

  void _onEdgeChanged(EdgeIdType edgeId, ViewEdge? previous, ViewEdge? next) {
    if (next == null) {
      _childQuadTree.removeEdge(edgeId);
    } else {
      _edgeIdsNeedingRebuild.add(edgeId);
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
  void showOnScreen({
    RenderObject? descendant,
    Rect? rect,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
    GraphViewportBehaviorResolver? behavior,
    bool zoomInToFit = false,
    bool zoomOutToFit = true,
    EdgeInsets padding = EdgeInsets.zero,
    EdgeInsets margin = EdgeInsets.zero,
  }) {
    if (descendant == null) {
      return super.showOnScreen(descendant: descendant, rect: rect, duration: duration, curve: curve);
    }

    assert(descendant is GraphElementRenderObject);

    transform.showInViewport(
      targetRect_GS: rect ?? descendant.paintBounds,
      duration: duration,
      curve: curve,
      behavior: behavior,
      padding: padding,
    );
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
        bool hitAnyChild = false;

        final List<GraphNodeRenderObject> nodes = _nodes.values.toList();
        for (final GraphNodeRenderObject node in nodes.reversed) {
          final bool wasNodeHit = result.addWithPaintOffset(
            offset: node.position,
            position: position,
            hitTest: node.hitTest,
          );

          hitAnyChild |= wasNodeHit;
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
          final bool wasEdgeHit = edge.hitTest(result, position);

          hitAnyChild |= wasEdgeHit;
        }

        return hitAnyChild;
      },
    );
  }

  PointerDownEventListener? onPointerDown;
  PointerPanZoomStartEventListener? onPointerPanZoomStart;

  @override
  void handleEvent(PointerEvent event, covariant HitTestEntry<HitTestTarget> entry) {
    if (event is PointerDownEvent) {
      onPointerDown?.call(event);
    }
    if (event is PointerPanZoomStartEvent) {
      onPointerPanZoomStart?.call(event);
    }
  }
}
