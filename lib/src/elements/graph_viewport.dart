import "package:flutter/gestures.dart";
import "package:flutter/widgets.dart";

import "../graph_viewport_controller.dart";
import "../rendering/edge.dart";
import "../rendering/graph_element.dart";
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

class GraphViewportElement<NodeIdType, EdgeIdType> extends RenderObjectElement implements GraphViewportLayoutHelper {
  GraphViewportElement(GraphViewport super.widget);

  late ScaleGestureRecognizer _scaleRecognizer;
  late TapGestureRecognizer _tapRecognizer;
  late DoubleTapGestureRecognizer _doubleTapRecognizer;

  @override
  RenderGraphViewport<NodeIdType, EdgeIdType> get renderObject =>
      super.renderObject as RenderGraphViewport<NodeIdType, EdgeIdType>;

  Map<NodeIdType, Element> _nodes = {};
  Map<EdgeIdType, Element> _edges = {};

  Map<NodeIdType, Element> _lastNodes = {};
  Map<EdgeIdType, Element> _lastEdges = {};

  late GraphViewportController<NodeIdType, EdgeIdType> _viewportController;
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
    final Element? oldNodeElement = _nodes[nodeId];
    final Element newNodeElement = updateChild(oldNodeElement, newNodeWidget, newNodeSlot)!;

    return newNodeElement;
  }

  Element _buildEdge(EdgeIdType edgeId) {
    final GraphViewportEdgeSlot newEdgeSlot = GraphViewportEdgeSlot(edgeId);
    final EdgeWidget newEdgeWidget = _edgeBuilder(this, edgeId);
    final Element? oldEdgeElement = _edges[edgeId];
    final Element newEdgeElement = updateChild(oldEdgeElement, newEdgeWidget, newEdgeSlot)!;

    return newEdgeElement;
  }

  void _buildAllNodes() {
    for (final NodeIdType nodeId in _viewportController.allNodeIds) {
      _nodes[nodeId] = _buildNode(nodeId);
    }
  }

  void _buildAllEdges() {
    for (final EdgeIdType edgeId in _viewportController.allEdgeIds) {
      _edges[edgeId] = _buildEdge(edgeId);
    }
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);

    final GraphViewport<NodeIdType, EdgeIdType> widget = this.widget as GraphViewport<NodeIdType, EdgeIdType>;

    _viewportController = widget.viewportController;
    _nodeBuilder = widget.nodeBuilder;
    _edgeBuilder = widget.edgeBuilder;

    _scaleRecognizer = ScaleGestureRecognizer(debugOwner: this, trackpadScrollCausesScale: true);
    _scaleRecognizer.onStart = widget.onScaleStart;
    _scaleRecognizer.onUpdate = widget.onScaleUpdate;
    _scaleRecognizer.onEnd = widget.onScaleEnd;

    _tapRecognizer = TapGestureRecognizer(debugOwner: this);
    _tapRecognizer.onTapDown = widget.onTapDown;
    _tapRecognizer.onTap = widget.onTap;

    _doubleTapRecognizer = DoubleTapGestureRecognizer(debugOwner: this);
    _doubleTapRecognizer.onDoubleTapDown = widget.onDoubleTapDown;
    _doubleTapRecognizer.onDoubleTap = widget.onDoubleTap;

    renderObject.onPointerDown = _handlePointerDown;
    renderObject.onPointerPanZoomStart = _handlePointerPanZoomStart;
    renderObject.onPointerSignal = _handlePointerSignal;

    _buildAllNodes();
    _buildAllEdges();
    renderObject.markNeedsFirstLayout();
  }

  @override
  void update(GraphViewport<NodeIdType, EdgeIdType> newWidget) {
    super.update(newWidget);

    _viewportController = newWidget.viewportController;
    _nodeBuilder = newWidget.nodeBuilder;
    _edgeBuilder = newWidget.edgeBuilder;

    _scaleRecognizer.onStart = newWidget.onScaleStart;
    _scaleRecognizer.onUpdate = newWidget.onScaleUpdate;
    _scaleRecognizer.onEnd = newWidget.onScaleEnd;

    _tapRecognizer.onTapDown = newWidget.onTapDown;
    _tapRecognizer.onTap = newWidget.onTap;

    _doubleTapRecognizer.onDoubleTapDown = newWidget.onDoubleTapDown;
    _doubleTapRecognizer.onDoubleTap = newWidget.onDoubleTap;

    renderObject.onPointerDown = _handlePointerDown;
    renderObject.onPointerPanZoomStart = _handlePointerPanZoomStart;
    renderObject.onPointerSignal = _handlePointerSignal;

    if (newWidget.rebuildAllChildrenOnWidgetUpdate) {
      _buildAllNodes();
      _buildAllEdges();
      renderObject.markNeedsFirstLayout();
    }
  }

  @override
  void forgetChild(Element child) {
    super.forgetChild(child);

    _nodes.removeWhere((key, nodeElem) => nodeElem == child);
    _edges.removeWhere((key, edgeElem) => edgeElem == child);
  }

  @override
  void insertRenderObjectChild(GraphElementRenderObject child, GraphViewportChildSlot slot) {
    renderObject.setupParentData(child);

    switch (child) {
      case GraphNodeRenderObject():
        renderObject.insertNode(child, (slot as GraphViewportNodeSlot).nodeId);

      case GraphEdgeRenderObject():
        renderObject.insertEdge(child, (slot as GraphViewportEdgeSlot).edgeId);
    }
  }

  @override
  void moveRenderObjectChild(
    GraphElementRenderObject child,
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
  void removeRenderObjectChild(GraphElementRenderObject child, GraphViewportChildSlot slot) {
    switch (child) {
      case GraphNodeRenderObject():
        renderObject.removeNode((slot as GraphViewportNodeSlot).nodeId);

      case GraphEdgeRenderObject():
        renderObject.removeEdge((slot as GraphViewportEdgeSlot).edgeId);
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
      (PointerSignalEvent event) {
        final GraphViewport widget = this.widget as GraphViewport;
        widget.onPointerSignal?.call(event);
      },
    );
  }
}
