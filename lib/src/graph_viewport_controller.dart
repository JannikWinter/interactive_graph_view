import "dart:collection";

import "package:flutter/widgets.dart";

import "edge_data.dart";
import "graph_viewport_node_model.dart";
import "rendering/graph_viewport.dart";

/// The controller that is used to programmatically control a [GraphViewport].
class GraphViewportController<NodeIdType, EdgeIdType, NodeModelType extends GraphViewportNodeModel> {
  /// Constructs a viewport controller with all [initialNodeIds] and [initialEdgeIds] that exist.
  GraphViewportController({
    required Map<NodeIdType, GraphViewportNodeModel> initialNodes,
    required Iterable<EdgeData<NodeIdType, EdgeIdType>> initialEdges,
  }) : _nodes = Map.from(initialNodes),
       _edges = {for (final edgeData in initialEdges) edgeData.edgeId: edgeData};

  Map<NodeIdType, GraphViewportNodeModel> _nodes;
  Map<EdgeIdType, EdgeData<NodeIdType, EdgeIdType>> _edges;

  RenderGraphViewport<NodeIdType, EdgeIdType, NodeModelType>? _viewport;

  /// Whether this viewport controller is attached to any [GraphViewport].
  bool get isAttached => _viewport != null;

  /// Notifies this viewport controller that it has been attached to [viewport].
  ///
  /// This method is called internally and you should usually not call it yourself.
  void onAttach(RenderGraphViewport<NodeIdType, EdgeIdType, NodeModelType> viewport) {
    assert(!isAttached);

    _viewport = viewport;
  }

  /// Notifies this viewport controller that it has been detached from [viewport].
  ///
  /// This method is called internally and you should usually not call it yourself.
  void onDetach(RenderGraphViewport<NodeIdType, EdgeIdType, NodeModelType>? viewport) {
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
  void setNode(NodeIdType nodeId, GraphViewportNodeModel node) {
    if (_nodes[nodeId] == node) return;

    final GraphViewportNodeModel? previous = _nodes[nodeId];

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
  void insertEdge(EdgeData<NodeIdType, EdgeIdType> edge) {
    if (_edges[edge.edgeId] == edge) return;

    _edges[edge.edgeId] = edge;
    _viewport!.markEdgeNeedsRebuild(edge.edgeId);
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

    _nodes.remove(nodeId);
    _viewport!.removeNode(nodeId);

    _viewport!.markNeedsLayout();
  }

  /// Remove an edge from the [GraphViewport] that this controller is attached to.
  void removeEdge(EdgeIdType edgeId) {
    assert(_edges.containsKey(edgeId));

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
  void setNodes(Map<NodeIdType, GraphViewportNodeModel> nodes) {
    final Set<NodeIdType> previousNodeIds = _nodes.keys.toSet();
    final Set<NodeIdType> newNodeIds = nodes.keys.toSet();

    final Set<NodeIdType> removedNodeIds = previousNodeIds.difference(newNodeIds);
    final Set<NodeIdType> addedNodeIds = newNodeIds.difference(previousNodeIds);

    for (final nodeId in removedNodeIds) {
      final GraphViewportNodeModel node = _nodes[nodeId]!;
      if (node is DynamicGraphViewportNodeModel) {
        assert(node.onNeedsRebuild != null);
        node.onNeedsRebuild = null;
      }

      _viewport!.removeNode(nodeId);
    }
    for (final nodeId in addedNodeIds) {
      final GraphViewportNodeModel node = nodes[nodeId]!;
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
  void setEdges(Iterable<EdgeData<NodeIdType, EdgeIdType>> edges) {
    final Set<EdgeIdType> previousEdgeIds = _edges.keys.toSet();
    final Set<EdgeIdType> newEdgeIds = edges.map((edge) => edge.edgeId).toSet();

    final Set<EdgeIdType> removedEdgeIds = previousEdgeIds.difference(newEdgeIds);
    final Set<EdgeIdType> addedEdgeIds = newEdgeIds.difference(previousEdgeIds);

    for (final edgeId in removedEdgeIds) {
      _viewport!.removeEdge(edgeId);
    }
    for (final edgeId in addedEdgeIds) {
      _viewport!.markEdgeNeedsRebuild(edgeId);
    }

    _edges = {for (final edgeData in edges) edgeData.edgeId: edgeData};

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
  UnmodifiableMapView<NodeIdType, GraphViewportNodeModel> get allNodes => UnmodifiableMapView(_nodes);

  /// An iterable over all edge IDs managed by this controller.
  UnmodifiableMapView<EdgeIdType, EdgeData<NodeIdType, EdgeIdType>> get allEdges => UnmodifiableMapView(_edges);
}
