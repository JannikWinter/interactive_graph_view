import "dart:collection";

import "package:flutter/material.dart";

import "edge_data.dart";
import "graph_viewport_transform.dart";
import "node_data.dart";
import "render_objects/graph_viewport_base.dart";

typedef NodeDataListener<NodeIdType, NodeDataType extends NodeData<NodeIdType>> =
    void Function(NodeIdType nodeId, NodeDataType? previous, NodeDataType? next);
typedef EdgeDataListener<EdgeIdType, EdgeDataType extends EdgeData<EdgeIdType, NodeIdType>, NodeIdType> =
    void Function(EdgeIdType edgeId, EdgeDataType? previous, EdgeDataType? next);

/// Manages all nodes and edges that are to be displayed in the viewport and the current selection.
/// Also handles changes on any nodes, edges or the selection and reflects those changes back to any listeners.
class GraphViewportController<
  NodeIdType,
  NodeDataType extends NodeData<NodeIdType>,
  EdgeIdType,
  EdgeDataType extends EdgeData<EdgeIdType, NodeIdType>
> {
  GraphViewportController({
    required Set<NodeDataType> initialNodes,
    required Set<EdgeDataType> initialEdges,
  }) : _nodes = {for (final NodeDataType node in initialNodes) node.id: node},
       _edges = {for (final EdgeDataType edge in initialEdges) edge.id: edge};

  final Set<NodeDataListener<NodeIdType, NodeDataType>> _nodeListeners = {};
  final Set<EdgeDataListener<EdgeIdType, EdgeDataType, NodeIdType>> _edgeListeners = {};

  final Map<NodeIdType, NodeDataType> _nodes;
  final Map<EdgeIdType, EdgeDataType> _edges;

  RenderGraphViewportBase<NodeIdType, NodeDataType, EdgeIdType, EdgeDataType>? _viewport;

  bool get isAttached => _viewport != null;

  void onAttach(RenderGraphViewportBase<NodeIdType, NodeDataType, EdgeIdType, EdgeDataType> viewport) {
    assert(!isAttached);

    _viewport = viewport;
  }

  void onDetach(RenderGraphViewportBase<NodeIdType, NodeDataType, EdgeIdType, EdgeDataType>? viewport) {
    assert(_viewport == viewport);

    _viewport = null;
  }

  UnmodifiableSetView<NodeIdType> get movingNodeIds => _viewport!.movingNodeIds;
  set movingNodeIds(Set<NodeIdType> value) => _viewport!.movingNodeIds = value;

  void rebuildNode(NodeIdType nodeId) {
    assert(_nodes.containsKey(nodeId));

    final NodeDataType previous = _nodes[nodeId]!;

    _notifyNodeListeners(nodeId, previous, previous);
  }

  void rebuildEdge(EdgeIdType edgeId) {
    assert(_edges.containsKey(edgeId));

    final EdgeDataType previous = _edges[edgeId]!;

    _notifyEdgeListeners(edgeId, previous, previous);
  }

  void putNode(NodeDataType viewNode) {
    final NodeIdType nodeId = viewNode.id;

    if (_nodes[nodeId] == viewNode) return;

    final NodeDataType? previous = _nodes[nodeId];

    _nodes[nodeId] = viewNode;

    _notifyNodeListeners(nodeId, previous, viewNode);
  }

  void removeNode(NodeIdType nodeId) {
    assert(_nodes.containsKey(nodeId));

    final NodeDataType previous = _nodes.remove(nodeId)!;

    _notifyNodeListeners(nodeId, previous, null);
  }

  void putEdge(EdgeDataType viewEdge) {
    final EdgeIdType edgeId = viewEdge.id;

    if (_edges[edgeId] == viewEdge) return;

    final EdgeDataType? previous = _edges[edgeId];

    _edges[edgeId] = viewEdge;

    _notifyEdgeListeners(edgeId, previous, viewEdge);
  }

  void removeEdge(EdgeIdType edgeId) {
    assert(_edges.containsKey(edgeId));

    final EdgeDataType previous = _edges.remove(edgeId)!;

    _notifyEdgeListeners(edgeId, previous, null);
  }

  Future<void> showNodesOnScreen(
    Set<NodeIdType> nodeIds, {
    EdgeInsets padding = EdgeInsets.zero,
    EdgeInsets margin = EdgeInsets.zero,
    bool zoomInToFit = false,
    bool zoomOutToFit = true,
    GraphViewportBehaviorResolver? behavior,
    Duration? duration,
    Curve? curve,
  }) async {
    await _viewport!.showNodesOnScreen(
      nodeIds,
      padding: padding,
      margin: margin,
      behavior: behavior,
      duration: duration,
      curve: curve,
    );
  }

  void addNodeListener(NodeDataListener<NodeIdType, NodeDataType> listener) {
    _nodeListeners.add(listener);
  }

  void removeNodeListener(NodeDataListener<NodeIdType, NodeDataType> listener) {
    _nodeListeners.remove(listener);
  }

  void _notifyNodeListeners(NodeIdType nodeId, NodeDataType? previous, NodeDataType? next) {
    for (final listener in _nodeListeners) {
      listener(nodeId, previous, next);
    }
  }

  void addEdgeListener(EdgeDataListener<EdgeIdType, EdgeDataType, NodeIdType> listener) {
    _edgeListeners.add(listener);
  }

  void removeEdgeListener(EdgeDataListener<EdgeIdType, EdgeDataType, NodeIdType> listener) {
    _edgeListeners.remove(listener);
  }

  void _notifyEdgeListeners(EdgeIdType edgeId, EdgeDataType? previous, EdgeDataType? next) {
    for (final listener in _edgeListeners) {
      listener(edgeId, previous, next);
    }
  }

  Iterable<EdgeIdType> getConnectingEdgeIds(NodeIdType nodeId) {
    return _edges.values.where((edge) => nodeId == edge.startNodeId || nodeId == edge.endNodeId).map((edge) => edge.id);
  }

  /// Returns the ViewNode for the given [NodeIdType], or `null` if the given [NodeIdType] is not present.
  NodeDataType? getNode(NodeIdType nodeId) => _nodes[nodeId];

  /// Returns the ViewEdge for the given [EdgeIdType], or `null` if the given [EdgeIdType] is not present.
  EdgeDataType? getEdge(EdgeIdType edgeId) => _edges[edgeId];

  Iterable<NodeIdType> get allNodeIds => _nodes.keys;
  Iterable<EdgeIdType> get allEdgeIds => _edges.keys;

  Iterable<NodeDataType> get nodes => _nodes.keys.map((nodeId) => getNode(nodeId)!);
  Iterable<EdgeDataType> get edges => _edges.values;
}
