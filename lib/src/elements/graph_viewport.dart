import "package:flutter/gestures.dart";
import "package:flutter/widgets.dart";

import "../graph_viewport_node_model.dart";
import "../graph_viewport_transform.dart";
import "../interaction/scale_details.dart";
import "../interaction/tap_details.dart";
import "../rendering/edge.dart";
import "../rendering/graph_child.dart";
import "../rendering/graph_viewport.dart";
import "../rendering/node.dart";
import "../widgets/edge.dart";
import "../widgets/graph_viewport.dart";
import "../widgets/node.dart";

base class GraphViewportChildSlot {}

final class GraphViewportNodeSlot<NodeIdType> extends GraphViewportChildSlot {
  GraphViewportNodeSlot(this.nodeId);

  final NodeIdType nodeId;

  @override
  bool operator ==(other) {
    if (other is! GraphViewportNodeSlot<NodeIdType>) return false;

    return nodeId == other.nodeId;
  }

  @override
  int get hashCode => nodeId.hashCode;
}

final class GraphViewportEdgeSlot<EdgeIdType> extends GraphViewportChildSlot {
  GraphViewportEdgeSlot(this.edgeId);

  final EdgeIdType edgeId;

  @override
  bool operator ==(other) {
    if (other is! GraphViewportEdgeSlot<EdgeIdType>) return false;

    return edgeId == other.edgeId;
  }

  @override
  int get hashCode => edgeId.hashCode;
}

abstract interface class GraphViewportLayoutHelper {
  void startLayout();
  void buildChild(GraphViewportChildSlot slot);
  void reuseChild(GraphViewportChildSlot slot);
  void endLayout();
}

class GraphViewportElement<NodeIdType, EdgeIdType, NodeModelType extends GraphViewportNodeModel>
    extends RenderObjectElement
    implements GraphViewportLayoutHelper {
  GraphViewportElement(GraphViewport super.widget);

  late ScaleGestureRecognizer _scaleRecognizer;
  late TapGestureRecognizer _tapRecognizer;
  late DoubleTapGestureRecognizer _doubleTapRecognizer;

  @override
  RenderGraphViewport<NodeIdType, EdgeIdType, NodeModelType> get renderObject =>
      super.renderObject as RenderGraphViewport<NodeIdType, EdgeIdType, NodeModelType>;

  Map<NodeIdType, Element> _nodes = {};
  Map<EdgeIdType, Element> _edges = {};

  Map<NodeIdType, Element> _lastNodes = {};
  Map<EdgeIdType, Element> _lastEdges = {};

  late NodeBuilder<NodeIdType> _nodeBuilder;
  late EdgeBuilder<EdgeIdType> _edgeBuilder;

  @override
  void startLayout() {
    _lastNodes = _nodes;
    _lastEdges = _edges;

    _nodes = {};
    _edges = {};
  }

  @override
  void buildChild(GraphViewportChildSlot slot) {
    owner!.buildScope(this, () {
      switch (slot) {
        case GraphViewportNodeSlot(nodeId: final nodeId):
          _nodes[nodeId] = _buildNode(nodeId);

        case GraphViewportEdgeSlot(edgeId: final edgeId):
          _edges[edgeId] = _buildEdge(edgeId);
      }
    });
  }

  @override
  void reuseChild(GraphViewportChildSlot slot) {
    switch (slot) {
      case GraphViewportNodeSlot(nodeId: final nodeId):
        _nodes[nodeId] = _lastNodes[nodeId]!;

      case GraphViewportEdgeSlot(edgeId: final edgeId):
        _edges[edgeId] = _lastEdges[edgeId]!;
    }
  }

  @override
  void endLayout() {
    for (final NodeIdType nodeId in _lastNodes.keys) {
      if (!_nodes.keys.contains(nodeId)) {
        Element oldNode = _lastNodes[nodeId]!;

        updateChild(oldNode, null, GraphViewportNodeSlot(nodeId));
      }
    }
    for (final EdgeIdType edgeId in _lastEdges.keys) {
      if (!_edges.keys.contains(edgeId)) {
        Element oldEdge = _lastEdges[edgeId]!;

        updateChild(oldEdge, null, GraphViewportEdgeSlot(edgeId));
      }
    }
  }

  Element _buildNode(NodeIdType nodeId) {
    final GraphViewportNodeSlot newNodeSlot = GraphViewportNodeSlot(nodeId);
    final NodeWidget newNodeWidget = _nodeBuilder(this, nodeId);
    final Element? oldNodeElement = _lastNodes[nodeId];
    final Element newNodeElement = updateChild(oldNodeElement, newNodeWidget, newNodeSlot)!;

    return newNodeElement;
  }

  Element _buildEdge(EdgeIdType edgeId) {
    final GraphViewportEdgeSlot newEdgeSlot = GraphViewportEdgeSlot(edgeId);
    final EdgeWidget newEdgeWidget = _edgeBuilder(this, edgeId);
    final Element? oldEdgeElement = _lastEdges[edgeId];
    final Element newEdgeElement = updateChild(oldEdgeElement, newEdgeWidget, newEdgeSlot)!;

    return newEdgeElement;
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);

    _initialize(widget as GraphViewport<NodeIdType, EdgeIdType, NodeModelType>);
  }

  @override
  void update(GraphViewport<NodeIdType, EdgeIdType, NodeModelType> newWidget) {
    super.update(newWidget);

    _initialize(newWidget);
  }

  void _initialize(GraphViewport<NodeIdType, EdgeIdType, NodeModelType> widget) {
    _nodeBuilder = widget.nodeBuilder;
    _edgeBuilder = widget.edgeBuilder;

    _scaleRecognizer = ScaleGestureRecognizer(debugOwner: this, trackpadScrollCausesScale: true);
    _scaleRecognizer.onStart = _onScaleStart;
    _scaleRecognizer.onUpdate = _onScaleUpdate;
    _scaleRecognizer.onEnd = _onScaleEnd;

    _tapRecognizer = TapGestureRecognizer(debugOwner: this);
    _tapRecognizer.onTapDown = _onTapDown;
    _tapRecognizer.onTap = _onTap;

    _doubleTapRecognizer = DoubleTapGestureRecognizer(debugOwner: this);
    _doubleTapRecognizer.onDoubleTapDown = _onTapDown;
    _doubleTapRecognizer.onDoubleTap = _onDoubleTap;

    renderObject.onPointerDown = _handlePointerDown;
    renderObject.onPointerPanZoomStart = _handlePointerPanZoomStart;
    renderObject.onPointerSignal = _handlePointerSignal;

    renderObject.movingNodeIds = widget.movingNodeIds;
    renderObject.onNodesMoved = widget.onNodesMoved;
  }

  @override
  void reassemble() {
    super.reassemble();

    // TODO: implement for hot reload
  }

  @override
  void forgetChild(Element child) {
    super.forgetChild(child);

    _nodes.removeWhere((key, nodeElem) => nodeElem == child);
    _edges.removeWhere((key, edgeElem) => edgeElem == child);
  }

  @override
  void insertRenderObjectChild(GraphChildRenderObject child, GraphViewportChildSlot slot) {
    renderObject.setupParentData(child);

    switch (child) {
      case GraphNodeRenderObject():
        renderObject.adoptNode((slot as GraphViewportNodeSlot).nodeId, child);

      case GraphEdgeRenderObject():
        renderObject.adoptEdge((slot as GraphViewportEdgeSlot).edgeId, child);
    }
  }

  @override
  void moveRenderObjectChild(
    GraphChildRenderObject child,
    GraphViewportChildSlot oldSlot,
    GraphViewportChildSlot newSlot,
  ) {
    assert(
      false,
      "updateChild() was called with an existing Element child and a slot that "
      "differs from the slot that element was previously given",
    );
  }

  @override
  void removeRenderObjectChild(GraphChildRenderObject child, GraphViewportChildSlot slot) {
    switch (child) {
      case GraphNodeRenderObject():
        renderObject.dropNode((slot as GraphViewportNodeSlot).nodeId);

      case GraphEdgeRenderObject():
        renderObject.dropEdge((slot as GraphViewportEdgeSlot).edgeId);
    }
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    for (final Element node in _nodes.values) {
      visitor(node);
    }
    for (final Element edge in _edges.values) {
      visitor(edge);
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    _scaleRecognizer.addPointer(event);
    _tapRecognizer.addPointer(event);
    _doubleTapRecognizer.addPointer(event);
  }

  void _handlePointerPanZoomStart(PointerPanZoomStartEvent event) {
    _scaleRecognizer.addPointerPanZoom(event);
    _tapRecognizer.addPointerPanZoom(event);
    _doubleTapRecognizer.addPointerPanZoom(event);
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    GestureBinding.instance.pointerSignalResolver.register(
      event,
      _onPointerSignal,
    );
  }

  void _onTapDown(TapDownDetails details) {
    final GraphViewportTransform viewportTransform = RenderGraphViewport.of(renderObject).transform;
    final GraphViewportTapDownDetails newDetails = GraphViewportTapDownDetails(
      globalPosition: details.globalPosition,
      viewportPosition: details.localPosition,
      graphPosition: viewportTransform.toGraphSpacePosition(details.localPosition),
    );

    (widget as GraphViewport).onTapDown?.call(newDetails);
  }

  void _onTap() {
    (widget as GraphViewport).onTap?.call();
  }

  void _onDoubleTap() {
    (widget as GraphViewport).onDoubleTap?.call();
  }

  void _onScaleStart(ScaleStartDetails details) {
    final RenderGraphViewport viewport = RenderGraphViewport.of(renderObject);
    final GraphViewportTransform viewportTransform = viewport.transform;
    final GraphViewportScaleStartDetails newDetails = GraphViewportScaleStartDetails(
      globalFocalPoint: details.focalPoint,
      viewportFocalPoint: details.localFocalPoint,
      graphFocalPoint: viewportTransform.toGraphSpacePosition(details.localFocalPoint),
      pointerCount: details.pointerCount,
    );

    (widget as GraphViewport).onScaleStart?.call(newDetails);
    viewportTransform.onScaleStart(newDetails);
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final RenderGraphViewport viewport = RenderGraphViewport.of(renderObject);
    final GraphViewportTransform viewportTransform = viewport.transform;
    final GraphViewportScaleUpdateDetails newDetails = GraphViewportScaleUpdateDetails(
      viewportFocalPointDelta: details.focalPointDelta,
      graphFocalPointDelta: viewportTransform.toGraphSpaceOffset(details.focalPointDelta),
      globalFocalPoint: details.focalPoint,
      viewportFocalPoint: details.localFocalPoint,
      graphFocalPoint: viewportTransform.toGraphSpacePosition(details.localFocalPoint),
      scale: details.scale,
      pointerCount: details.pointerCount,
    );

    (widget as GraphViewport).onScaleUpdate?.call(newDetails);
    viewportTransform.onScaleUpdate(newDetails);
  }

  void _onScaleEnd(ScaleEndDetails details) {
    final RenderGraphViewport viewport = RenderGraphViewport.of(renderObject);
    final GraphViewportTransform viewportTransform = viewport.transform;
    final GraphViewportScaleEndDetails newDetails = GraphViewportScaleEndDetails(
      viewportVelocity: details.velocity,
      graphVelocity: Velocity(pixelsPerSecond: details.velocity.pixelsPerSecond / viewportTransform.scale),
      scaleVelocity: details.scaleVelocity,
      pointerCount: details.pointerCount,
    );

    (widget as GraphViewport).onScaleEnd?.call(newDetails);
    viewportTransform.onScaleEnd(newDetails);
  }

  void _onPointerSignal(PointerSignalEvent event) {
    (widget as GraphViewport).onPointerSignal?.call(event);

    final RenderGraphViewport viewport = RenderGraphViewport.of(renderObject);
    final GraphViewportTransform viewportTransform = viewport.transform;
    viewportTransform.onPointerSignal(event);
  }
}
