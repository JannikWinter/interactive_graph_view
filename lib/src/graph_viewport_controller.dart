import "dart:collection";

import "package:flutter/widgets.dart";

import "rendering/graph_viewport_base.dart";

/// This callback is called whenever nodes were dragged and that drag ended.
typedef NodesMovedCallback<NodeIdType> = void Function(Set<NodeIdType> nodeIds, Offset offset);

/// The controller that is used to programmatically control a [GraphViewport].
class GraphViewportController<NodeIdType, EdgeIdType> {
  /// Constructs a viewport controller with all [initialNodeIds] and [initialEdgeIds] that exist.
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

  /// Whether this viewport controller is attached to any [GraphViewport].
  bool get isAttached => _viewport != null;

  /// Notifies this viewport controller that it has been attached to [viewport].
  ///
  /// This method is called internally and you should usually not call it yourself.
  void onAttach(RenderGraphViewportBase<NodeIdType, EdgeIdType> viewport) {
    assert(!isAttached);

    _viewport = viewport;
  }

  /// Notifies this viewport controller that it has been detached from [viewport].
  ///
  /// This method is called internally and you should usually not call it yourself.
  void onDetach(RenderGraphViewportBase<NodeIdType, EdgeIdType>? viewport) {
    assert(_viewport == viewport);

    _viewport = null;
  }

  /// The IDs of all the nodes that are marked to be dragged, when any node is dragged.
  ///
  /// See [NodeWidget.isDragEnabled].
  ///
  /// When the drag gesture on a node ended, the [NodesMovedCallback] (supplied in [GraphViewportController.new])
  /// will be called.
  UnmodifiableSetView<NodeIdType> get movingNodeIds => _viewport!.movingNodeIds;
  set movingNodeIds(Set<NodeIdType> value) => _viewport!.movingNodeIds = value;

  /// Mark a node for rebuilding.
  ///
  /// In the next frame [GraphViewport.nodeBuilder] will be called for the given [nodeId].
  void rebuildNode(NodeIdType nodeId) {
    assert(_nodeIds.contains(nodeId));

    _viewport!.markNodeNeedsRebuild(nodeId);
  }

  /// Mark an edge for rebuilding.
  ///
  /// In the next frame [GraphViewport.edgeBuilder] will be called for the given [edgeId].
  void rebuildEdge(EdgeIdType edgeId) {
    assert(_edgeIds.contains(edgeId));

    _viewport!.markEdgeNeedsRebuild(edgeId);
  }

  /// Insert a node into the [GraphViewport] that this controller is attached to.
  ///
  /// The framework will automatically built this node with [GraphViewport.nodeBuilder] in the next frame.
  void insertNode(NodeIdType nodeId) {
    if (_nodeIds.add(nodeId)) {
      _viewport!.markNodeNeedsRebuild(nodeId);
    }
  }

  /// Insert an edge into the [GraphViewport] that this controller is attached to.
  ///
  /// The framework will automatically built this node with [GraphViewport.edgeBuilder] in the next frame.
  void insertEdge(EdgeIdType edgeId) {
    if (_edgeIds.add(edgeId)) {
      _viewport!.markEdgeNeedsRebuild(edgeId);
    }
  }

  /// Remove a node from the [GraphViewport] that this controller is attached to.
  void removeNode(NodeIdType nodeId) {
    assert(_nodeIds.contains(nodeId));

    _viewport!.markNeedsLayout();
  }

  /// Remove an edge from the [GraphViewport] that this controller is attached to.
  void removeEdge(EdgeIdType edgeId) {
    assert(_edgeIds.contains(edgeId));

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

  // TODO:
  // Future<void> showEdgesOnScreen();

  /// An iterable over all node IDs managed by this controller.
  Iterable<NodeIdType> get allNodeIds => _nodeIds;

  /// An iterable over all edge IDs managed by this controller.
  Iterable<EdgeIdType> get allEdgeIds => _edgeIds;
}
