import "package:flutter/material.dart";

import "drag_details.dart";
import "graph_viewport_transform.dart";
import "render_objects/graph_viewport_base.dart";

/// Manages all nodes and edges that are to be displayed in the viewport and the current selection.
/// Also handles changes on any nodes, edges or the selection and reflects those changes back to any listeners.
class GraphViewportController<NodeIdType, EdgeIdType> {
  GraphViewportController({
    required Set<ViewNode> initialNodes,
    required Set<ViewEdge> initialEdges,
  }) : _nodes = {for (final ViewNode node in initialNodes) node.id: node},
       _edges = {for (final ViewEdge edge in initialEdges) edge.id: edge};

  final Set<ViewNodeListener> _nodeListeners = {};
  final Set<ViewEdgeListener> _edgeListeners = {};

  final Map<NodeIdType, ViewNode> _nodes;
  final Map<EdgeIdType, ViewEdge> _edges;

  RenderGraphViewportBase? _viewport;

  bool get isAttached => _viewport != null;

  void onAttach(RenderGraphViewportBase viewport) {
    assert(!isAttached);

    _viewport = viewport;
  }

  void onDetach(RenderGraphViewportBase viewport) {
    assert(_viewport == viewport);

    _viewport = null;
  }

  void rebuildNode(NodeIdType nodeId) {
    assert(_nodes.containsKey(nodeId));

    final ViewNode previous = _nodes[nodeId]!;

    _notifyNodeListeners(nodeId, previous, previous);
  }

  void rebuildEdge(EdgeIdType edgeId) {
    assert(_edges.containsKey(edgeId));

    final ViewEdge previous = _edges[edgeId]!;

    _notifyEdgeListeners(edgeId, previous, previous);
  }

  void putNode(ViewNode viewNode) {
    final NodeIdType nodeId = viewNode.id;

    if (_nodes[nodeId] == viewNode) return;

    final ViewNode? previous = _nodes[nodeId];

    _nodes[nodeId] = viewNode;

    _notifyNodeListeners(nodeId, previous, viewNode);
  }

  void removeNode(NodeIdType nodeId) {
    assert(_nodes.containsKey(nodeId));

    final ViewNode previous = _nodes.remove(nodeId)!;

    _notifyNodeListeners(nodeId, previous, null);
  }

  void putEdge(ViewEdge viewEdge) {
    final EdgeIdType edgeId = viewEdge.id;

    if (_edges[edgeId] == viewEdge) return;

    final ViewEdge? previous = _edges[edgeId];

    _edges[edgeId] = viewEdge;

    _notifyEdgeListeners(edgeId, previous, viewEdge);
  }

  void removeEdge(EdgeIdType edgeId) {
    assert(_edges.containsKey(edgeId));

    final ViewEdge previous = _edges.remove(edgeId)!;

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

  void addNodeListener(ViewNodeListener listener) {
    _nodeListeners.add(listener);
  }

  void removeNodeListener(ViewNodeListener listener) {
    _nodeListeners.remove(listener);
  }

  void _notifyNodeListeners(NodeIdType nodeId, ViewNode? previous, ViewNode? next) {
    for (final listener in _nodeListeners) {
      listener(nodeId, previous, next);
    }
  }

  void addEdgeListener(ViewEdgeListener listener) {
    _edgeListeners.add(listener);
  }

  void removeEdgeListener(ViewEdgeListener listener) {
    _edgeListeners.remove(listener);
  }

  void _notifyEdgeListeners(EdgeIdType edgeId, ViewEdge? previous, ViewEdge? next) {
    for (final listener in _edgeListeners) {
      listener(edgeId, previous, next);
    }
  }

  Iterable<EdgeIdType> getConnectingEdgeIds(NodeIdType nodeId) {
    return _edges.values.where((edge) => nodeId == edge.startNodeId || nodeId == edge.endNodeId).map((edge) => edge.id);
  }

  /// Returns the ViewNode for the given [NodeIdType], or `null` if the given [NodeIdType] is not present.
  ViewNode? getNode(NodeIdType nodeId) => _nodes[nodeId];

  /// Returns the ViewEdge for the given [EdgeIdType], or `null` if the given [EdgeIdType] is not present.
  ViewEdge? getEdge(EdgeIdType edgeId) => _edges[edgeId];

  Iterable<ViewNode> get nodes => _nodes.keys.map((nodeId) => getNode(nodeId)!);
  Iterable<ViewEdge> get edges => _edges.values;

  void onNodePanDown(NodeIdType nodeId, NodeDragDownDetails details) {
    _viewport!.onNodePanDown(nodeId, details);
  }

  void onNodePanStart(NodeDragStartDetails details, {Set<NodeIdType>? draggedNodeIds}) {
    _viewport!.onNodePanStart(details, draggedNodeIds);
  }

  void onNodePanUpdate(NodeDragUpdateDetails details) {
    _viewport!.onNodePanUpdate(details);
  }

  Offset onNodePanEnd(NodeDragEndDetails details) {
    return _viewport!.onNodePanEnd(details);
  }

  void onNodePanCancel() {
    _viewport!.onNodePanCancel();
  }
}
