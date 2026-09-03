import "dart:collection";

import "package:flutter/widgets.dart";

import "graph_viewport_edge_model.dart";
import "graph_viewport_node_model.dart";
import "rendering/graph_viewport.dart";

/// The controller that is used to programmatically control a [GraphViewport].
class GraphViewportController<
  NodeIdType,
  EdgeIdType,
  NodeModelType extends GraphViewportNodeModel,
  EdgeModelType extends GraphViewportEdgeModel<NodeIdType>
> {
  /// Constructs a viewport controller with all [initialNodeIds] and [initialEdgeIds] that exist.
  GraphViewportController({
    required Map<NodeIdType, NodeModelType> initialNodes,
    required Map<EdgeIdType, EdgeModelType> initialEdges,
  }) : _nodes = Map.from(initialNodes),
       _edges = Map.from(initialEdges) {
    for (final (nodeId, node) in _nodes.entries.map((e) => (e.key, e.value))) {
      if (node is DynamicGraphViewportNodeModel) {
        assert(node.onNeedsRebuild == null);
        node.onNeedsRebuild = () => _viewport!.markNodeNeedsRebuild(nodeId);
      }
    }
    for (final (edgeId, edge) in _edges.entries.map((e) => (e.key, e.value))) {
      if (edge is DynamicGraphViewportEdgeModel<NodeIdType>) {
        assert(edge.onNeedsRebuild == null);
        edge.onNeedsRebuild = () => _viewport!.markEdgeNeedsRebuild(edgeId);
      }
    }
  }

  Map<NodeIdType, NodeModelType> _nodes;
  Map<EdgeIdType, EdgeModelType> _edges;

  RenderGraphViewport<NodeIdType, EdgeIdType, NodeModelType, EdgeModelType>? _viewport;

  /// Whether this viewport controller is attached to any [GraphViewport].
  bool get isAttached => _viewport != null;

  /// Notifies this viewport controller that it has been attached to [viewport].
  ///
  /// This method is called internally and you should usually not call it yourself.
  void onAttach(RenderGraphViewport<NodeIdType, EdgeIdType, NodeModelType, EdgeModelType> viewport) {
    assert(!isAttached);

    _viewport = viewport;
  }

  /// Notifies this viewport controller that it has been detached from [viewport].
  ///
  /// This method is called internally and you should usually not call it yourself.
  void onDetach(RenderGraphViewport<NodeIdType, EdgeIdType, NodeModelType, EdgeModelType>? viewport) {
    assert(_viewport == viewport);

    _viewport = null;
  }

  /// Mark a node for rebuilding.
  ///
  /// In the next frame [GraphViewport.nodeBuilder] will be called for the given [nodeId].
  void rebuildNode(NodeIdType nodeId) {
    assert(_nodes.containsKey(nodeId));

    _viewport!.markNodeNeedsRebuild(nodeId);
  }

  /// Mark an edge for rebuilding.
  ///
  /// In the next frame [GraphViewport.edgeBuilder] will be called for the given [edgeId].
  void rebuildEdge(EdgeIdType edgeId) {
    assert(_edges.containsKey(edgeId));

    _viewport!.markEdgeNeedsRebuild(edgeId);
  }

  /// Insert a node into the [GraphViewport] that this controller is attached to.
  ///
  /// The framework will automatically build this node with [GraphViewport.nodeBuilder] in the next frame.
  void setNode(NodeIdType nodeId, NodeModelType node) {
    final NodeModelType? previous = _nodes[nodeId];

    if (previous == node) return;

    _nodes[nodeId] = node;

    if (previous is DynamicGraphViewportNodeModel) {
      assert(previous.onNeedsRebuild != null);
      previous.onNeedsRebuild = null;
    }

    switch (node) {
      case StaticGraphViewportNodeModel():
        if (previous is! StaticGraphViewportNodeModel || node.shouldRebuild(previous)) {
          _viewport!.markNodeNeedsRebuild(nodeId);
        }

      case DynamicGraphViewportNodeModel():
        assert(node.onNeedsRebuild == null);
        node.onNeedsRebuild = () => _viewport!.markNodeNeedsRebuild(nodeId);
        _viewport!.markNodeNeedsRebuild(nodeId);
    }
  }

  /// Insert an edge into the [GraphViewport] that this controller is attached to.
  ///
  /// The framework will automatically build this node with [GraphViewport.edgeBuilder] in the next frame.
  void setEdge(EdgeIdType edgeId, EdgeModelType edge) {
    final EdgeModelType? previous = _edges[edgeId];

    if (previous == edge) return;

    _edges[edgeId] = edge;

    if (previous is DynamicGraphViewportEdgeModel<NodeIdType>) {
      assert(previous.onNeedsRebuild != null);
      previous.onNeedsRebuild = null;
    }

    switch (edge) {
      case StaticGraphViewportEdgeModel<NodeIdType>():
        if (previous is! StaticGraphViewportEdgeModel<NodeIdType> || edge.shouldRebuild(previous)) {
          _viewport!.markEdgeNeedsRebuild(edgeId);
        }

      case DynamicGraphViewportEdgeModel<NodeIdType>():
        assert(edge.onNeedsRebuild == null);
        edge.onNeedsRebuild = () => _viewport!.markEdgeNeedsRebuild(edgeId);
        _viewport!.markEdgeNeedsRebuild(edgeId);
    }
  }

  /// Whether the [GraphViewport] that this controller is attached to contains a node with the given [nodeId].
  bool containsNode(NodeIdType nodeId) {
    return _nodes.containsKey(nodeId);
  }

  /// Whether the [GraphViewport] that this controller is attached to contains an edge with the given [edgeId].
  bool containsEdge(EdgeIdType edgeId) {
    return _edges.containsKey(edgeId);
  }

  /// Remove a node from the [GraphViewport] that this controller is attached to.
  void removeNode(
    NodeIdType nodeId,
  ) {
    assert(_nodes.containsKey(nodeId));

    final NodeModelType node = _nodes[nodeId]!;

    if (node is DynamicGraphViewportNodeModel) {
      assert(node.onNeedsRebuild != null);
      node.onNeedsRebuild = null;
    }

    _nodes.remove(nodeId);
    _viewport!.removeNode(nodeId);

    _viewport!.markNeedsLayout();
  }

  /// Remove an edge from the [GraphViewport] that this controller is attached to.
  void removeEdge(EdgeIdType edgeId) {
    assert(_edges.containsKey(edgeId));

    final EdgeModelType edge = _edges[edgeId]!;

    if (edge is DynamicGraphViewportEdgeModel<NodeIdType>) {
      assert(edge.onNeedsRebuild != null);
      edge.onNeedsRebuild = null;
    }

    _edges.remove(edgeId);
    _viewport!.removeEdge(edgeId);

    _viewport!.markNeedsLayout();
  }

  /// Replace the nodes of the [GraphViewport] that this controller is attached to.
  ///
  /// This will automatically:
  /// - remove all nodes that were contained in the viewport and are not contained in [nodeIds]
  /// - insert and build all nodes that were not contained in the viewport and are contained in [nodeIds]
  ///
  /// Nodes that both were contained in the viewport before and are also contained in [nodeIds] will **not** be rebuilt
  /// automatically.
  void setNodes(Map<NodeIdType, NodeModelType> nodes) {
    final Set<NodeIdType> previousNodeIds = _nodes.keys.toSet();
    final Set<NodeIdType> newNodeIds = nodes.keys.toSet();

    final Set<NodeIdType> removedNodeIds = previousNodeIds.difference(newNodeIds);
    final Set<NodeIdType> addedNodeIds = newNodeIds.difference(previousNodeIds);

    for (final nodeId in removedNodeIds) {
      final NodeModelType node = _nodes[nodeId]!;
      if (node is DynamicGraphViewportNodeModel) {
        assert(node.onNeedsRebuild != null);
        node.onNeedsRebuild = null;
      }
      _viewport!.removeNode(nodeId);
    }
    for (final nodeId in addedNodeIds) {
      final NodeModelType node = nodes[nodeId]!;
      if (node is DynamicGraphViewportNodeModel) {
        assert(node.onNeedsRebuild == null);
        node.onNeedsRebuild = () => _viewport!.markNodeNeedsRebuild(nodeId);
      }
      _viewport!.markNodeNeedsRebuild(nodeId);
    }

    _nodes = Map.from(nodes);

    _viewport!.markNeedsLayout();
  }

  /// Replace the edges of the [GraphViewport] that this controller is attached to.
  ///
  /// This will automatically:
  /// - remove all edges that were contained in the viewport and are not contained in [edgeIds]
  /// - insert and build all edges that were not contained in the viewport and are contained in [edgeIds]
  ///
  /// Edges that both were contained in the viewport before and are also contained in [edgeIds] will **not** be rebuilt
  /// automatically.
  void setEdges(Map<EdgeIdType, EdgeModelType> edges) {
    final Set<EdgeIdType> previousEdgeIds = _edges.keys.toSet();
    final Set<EdgeIdType> newEdgeIds = edges.keys.toSet();

    final Set<EdgeIdType> removedEdgeIds = previousEdgeIds.difference(newEdgeIds);
    final Set<EdgeIdType> addedEdgeIds = newEdgeIds.difference(previousEdgeIds);

    for (final edgeId in removedEdgeIds) {
      final EdgeModelType edge = _edges[edgeId]!;
      if (edge is DynamicGraphViewportEdgeModel<NodeIdType>) {
        assert(edge.onNeedsRebuild != null);
        edge.onNeedsRebuild = null;
      }
      _viewport!.removeEdge(edgeId);
    }
    for (final edgeId in addedEdgeIds) {
      final EdgeModelType edge = edges[edgeId]!;
      if (edge is DynamicGraphViewportEdgeModel<NodeIdType>) {
        assert(edge.onNeedsRebuild == null);
        edge.onNeedsRebuild = () => _viewport!.markEdgeNeedsRebuild(edgeId);
      }
      _viewport!.markEdgeNeedsRebuild(edgeId);
    }

    _edges = Map.from(edges);

    _viewport!.markNeedsLayout();
  }

  /// {@macro render_graph_viewport_base.show_nodes_on_screen}
  Future<bool> showNodesOnScreen(
    Set<NodeIdType> nodeIds, {
    EdgeInsets margin = EdgeInsets.zero,
    EdgeInsets padding = EdgeInsets.zero,
    Duration duration = Duration.zero,
    Curve curve = Curves.linear,
  }) => _viewport!.showNodesOnScreen(
    nodeIds,
    padding: padding,
    margin: margin,
    duration: duration,
    curve: curve,
  );

  /// {@macro render_graph_viewport_base.show_edges_on_screen}
  Future<bool> showEdgesOnScreen(
    Set<EdgeIdType> edgeIds, {
    EdgeInsets margin = EdgeInsets.zero,
    EdgeInsets padding = EdgeInsets.zero,
    Duration duration = Duration.zero,
    Curve curve = Curves.linear,
  }) => _viewport!.showEdgesOnScreen(
    edgeIds,
    padding: padding,
    margin: margin,
    duration: duration,
    curve: curve,
  );

  /// An iterable over all node IDs managed by this controller.
  UnmodifiableMapView<NodeIdType, NodeModelType> get allNodes => UnmodifiableMapView(_nodes);

  /// An iterable over all edge IDs managed by this controller.
  UnmodifiableMapView<EdgeIdType, EdgeModelType> get allEdges => UnmodifiableMapView(_edges);
}
