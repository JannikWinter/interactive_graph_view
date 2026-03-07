import "dart:collection";

import "package:flutter/widgets.dart";

import "graph_viewport_behavior.dart";
import "render_objects/graph_viewport_base.dart";

typedef NodesMovedCallback<NodeIdType> = void Function(Set<NodeIdType> nodeIds, Offset offset);

/// Manages all nodes and edges that are to be displayed in the viewport and the current selection.
/// Also handles changes on any nodes, edges or the selection and reflects those changes back to any listeners.
class GraphViewportController<NodeIdType, EdgeIdType> {
  GraphViewportController({
    required Iterable<NodeIdType> initialNodeIds,
    required Iterable<EdgeIdType> initialEdgeIds,
    NodesMovedCallback? onNodesMoved,
  }) : _nodeIds = Set.from(initialNodeIds),
       _edgeIds = Set.from(initialEdgeIds),
       _onNodesMoved = onNodesMoved;

  final Set<NodeIdType> _nodeIds;
  final Set<EdgeIdType> _edgeIds;
  final NodesMovedCallback? _onNodesMoved;

  RenderGraphViewportBase<NodeIdType, EdgeIdType>? _viewport;

  bool get isAttached => _viewport != null;

  void onAttach(RenderGraphViewportBase<NodeIdType, EdgeIdType> viewport) {
    assert(!isAttached);

    _viewport = viewport;
  }

  void onDetach(RenderGraphViewportBase<NodeIdType, EdgeIdType>? viewport) {
    assert(_viewport == viewport);

    _viewport = null;
  }

  UnmodifiableSetView<NodeIdType> get movingNodeIds => _viewport!.movingNodeIds;
  set movingNodeIds(Set<NodeIdType> value) => _viewport!.movingNodeIds = value;

  void rebuildNode(NodeIdType nodeId) {
    assert(_nodeIds.contains(nodeId));

    _viewport!.markNodeNeedsRebuild(nodeId);
  }

  void rebuildEdge(EdgeIdType edgeId) {
    assert(_edgeIds.contains(edgeId));

    _viewport!.markEdgeNeedsRebuild(edgeId);
  }

  void insertNode(NodeIdType nodeId) {
    if (_nodeIds.add(nodeId)) {
      _viewport!.markNodeNeedsRebuild(nodeId);
    }
  }

  void insertEdge(EdgeIdType edgeId) {
    if (_edgeIds.add(edgeId)) {
      _viewport!.markEdgeNeedsRebuild(edgeId);
    }
  }

  void removeNode(NodeIdType nodeId) {
    assert(_nodeIds.contains(nodeId));

    _viewport!.markNeedsLayout();
  }

  void removeEdge(EdgeIdType edgeId) {
    assert(_edgeIds.contains(edgeId));

    _viewport!.markNeedsLayout();
  }

  void notifyNodesMoved(Set<NodeIdType> movedNodeIds, Offset offset) {
    _onNodesMoved?.call(movedNodeIds, offset);
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

  Iterable<NodeIdType> get allNodeIds => _nodeIds;
  Iterable<EdgeIdType> get allEdgeIds => _edgeIds;
}
