import "dart:collection";

import "package:flutter/widgets.dart";

import "edge_data.dart";
import "node_data.dart";
import "rendering/graph_viewport.dart";

/// This callback is called whenever nodes were dragged and that drag ended.
typedef NodesMovedCallback<NodeIdType> = void Function(Set<NodeIdType> nodeIds, Offset offset);

/// The controller that is used to programmatically control a [GraphViewport].
class GraphViewportController<NodeIdType, EdgeIdType> {
  /// Constructs a viewport controller with all [initialNodeIds] and [initialEdgeIds] that exist.
  GraphViewportController({
    required Iterable<NodeData<NodeIdType>> initialNodes,
    required Iterable<EdgeData<NodeIdType, EdgeIdType>> initialEdges,
    NodesMovedCallback<NodeIdType>? onNodesMoved,
  }) : _nodes = {for (final nodeData in initialNodes) nodeData.nodeId: nodeData},
       _edges = {for (final edgeData in initialEdges) edgeData.edgeId: edgeData},
       _onNodesMoved = onNodesMoved;

  Map<NodeIdType, NodeData<NodeIdType>> _nodes;
  Map<EdgeIdType, EdgeData<NodeIdType, EdgeIdType>> _edges;
  final NodesMovedCallback<NodeIdType>? _onNodesMoved;

  RenderGraphViewport<NodeIdType, EdgeIdType>? _viewport;

  /// Whether this viewport controller is attached to any [GraphViewport].
  bool get isAttached => _viewport != null;

  /// Notifies this viewport controller that it has been attached to [viewport].
  ///
  /// This method is called internally and you should usually not call it yourself.
  void onAttach(RenderGraphViewport<NodeIdType, EdgeIdType> viewport) {
    assert(!isAttached);

    _viewport = viewport;
  }

  /// Notifies this viewport controller that it has been detached from [viewport].
  ///
  /// This method is called internally and you should usually not call it yourself.
  void onDetach(RenderGraphViewport<NodeIdType, EdgeIdType>? viewport) {
    assert(_viewport == viewport);

    _viewport = null;
  }

  /// The IDs of all the nodes that are marked to be dragged, when any node is dragged.
  ///
  /// See [NodeWidget.isDragEnabled].
  ///
  /// When the drag gesture on a node ended, the [NodesMovedCallback] (supplied in [GraphViewportController.new])
  /// will be called.
  Set<NodeIdType> get movingNodeIds => _viewport!.movingNodeIds;
  set movingNodeIds(Set<NodeIdType> value) => _viewport!.movingNodeIds = Set.from(value);

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
  void insertNode(NodeData<NodeIdType> node) {
    if (_nodes[node.nodeId] == node) return;

    _nodes[node.nodeId] = node;
    _viewport!.markNodeNeedsRebuild(node.nodeId);
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
  void setNodes(Iterable<NodeData<NodeIdType>> nodes) {
    final Set<NodeIdType> previousNodeIds = _nodes.keys.toSet();
    final Set<NodeIdType> newNodeIds = nodes.map((node) => node.nodeId).toSet();

    final Set<NodeIdType> removedNodeIds = previousNodeIds.difference(newNodeIds);
    final Set<NodeIdType> addedNodeIds = newNodeIds.difference(previousNodeIds);

    for (final nodeId in removedNodeIds) {
      _viewport!.removeNode(nodeId);
    }
    for (final nodeId in addedNodeIds) {
      _viewport!.markNodeNeedsRebuild(nodeId);
    }

    _nodes = {for (final nodeData in nodes) nodeData.nodeId: nodeData};

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

  /// Notifies the [NodesMovedCallback], which was supplied in [GraphViewportController.new].
  ///
  /// This method is called internally and you should usually not call this method yourself.
  void notifyNodesMoved(Set<NodeIdType> movedNodeIds, Offset offset) {
    _onNodesMoved?.call(movedNodeIds, offset);
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
  UnmodifiableMapView<NodeIdType, NodeData<NodeIdType>> get allNodes => UnmodifiableMapView(_nodes);

  /// An iterable over all edge IDs managed by this controller.
  UnmodifiableMapView<EdgeIdType, EdgeData<NodeIdType, EdgeIdType>> get allEdges => UnmodifiableMapView(_edges);
}
