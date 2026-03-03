import "package:flutter/gestures.dart";
import "package:flutter/material.dart";

import "../drag_details.dart";
import "../render_objects/graph_viewport_base.dart";
import "../render_objects/node.dart";
import "../widgets/node.dart";

class NodeElement<NodeIdType> extends SlottedRenderObjectElement<NodeWidgetSlot, RenderBox> {
  NodeElement(NodeWidget super.widget);

  late TapGestureRecognizer _tapRecognizer;
  late DoubleTapGestureRecognizer _doubleTapRecognizer;
  late LongPressGestureRecognizer _longPressRecognizer;
  late PanGestureRecognizer _panRecognizer;

  @override
  GraphNodeRenderObject get renderObject => super.renderObject as GraphNodeRenderObject;

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);

    final NodeWidget widget = this.widget as NodeWidget;

    _initializeRecognizers(widget);

    renderObject.onPointerDown = _handlePointerDown;
    renderObject.onPointerPanZoomStart = _handlePointerPanZoomStart;
  }

  @override
  void update(NodeWidget newWidget) {
    super.update(newWidget);

    _initializeRecognizers(newWidget);
  }

  void _initializeRecognizers(NodeWidget widget) {
    _tapRecognizer = TapGestureRecognizer(debugOwner: this);
    _tapRecognizer.onTap = widget.onTap;

    _doubleTapRecognizer = DoubleTapGestureRecognizer(debugOwner: this);
    _doubleTapRecognizer.onDoubleTap = widget.onDoubleTap;

    _longPressRecognizer = LongPressGestureRecognizer(debugOwner: this);
    _longPressRecognizer.onLongPress = widget.onLongPress;

    _panRecognizer = PanGestureRecognizer(debugOwner: this);
    if (widget.isDragEnabled) {
      _panRecognizer.onDown = _onDragDown;
      _panRecognizer.onStart = _onDragStart;
      _panRecognizer.onUpdate = _onDragUpdate;
      _panRecognizer.onEnd = _onDragEnd;
      _panRecognizer.onCancel = _onDragCancel;
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    _tapRecognizer.addPointer(event);
    _doubleTapRecognizer.addPointer(event);
    _longPressRecognizer.addPointer(event);
    _panRecognizer.addPointer(event);
  }

  void _handlePointerPanZoomStart(PointerPanZoomStartEvent event) {
    _tapRecognizer.addPointerPanZoom(event);
    _doubleTapRecognizer.addPointerPanZoom(event);
    _longPressRecognizer.addPointerPanZoom(event);
    _panRecognizer.addPointerPanZoom(event);
  }

  void _onDragDown(DragDownDetails details) {
    final RenderGraphViewportBase viewportBase = RenderGraphViewportBase.of(renderObject);
    final NodeDragDownDetails newDetails = viewportBase.convertDragDownDetails(details);

    (widget as NodeWidget).onDragDown?.call(newDetails);
    viewportBase.onNodeDragDown(newDetails);
  }

  void _onDragStart(DragStartDetails details) {
    final RenderGraphViewportBase viewportBase = RenderGraphViewportBase.of(renderObject);
    final NodeDragStartDetails newDetails = viewportBase.convertDragStartDetails(details);

    (widget as NodeWidget).onDragStart?.call(newDetails);
    viewportBase.onNodeDragStart(newDetails);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final RenderGraphViewportBase viewportBase = RenderGraphViewportBase.of(renderObject);
    final NodeDragUpdateDetails newDetails = viewportBase.convertDragUpdateDetails(details);

    (widget as NodeWidget).onDragUpdate?.call(newDetails);
    viewportBase.onNodeDragUpdate(newDetails);
  }

  void _onDragEnd(DragEndDetails details) {
    final RenderGraphViewportBase viewportBase = RenderGraphViewportBase.of(renderObject);
    final NodeDragEndDetails newDetails = viewportBase.convertDragEndDetails(details);

    (widget as NodeWidget).onDragEnd?.call(newDetails);
    viewportBase.onNodeDragEnd(newDetails);
  }

  void _onDragCancel() {
    final RenderGraphViewportBase viewportBase = RenderGraphViewportBase.of(renderObject);

    (widget as NodeWidget).onDragCancel?.call();
    viewportBase.onNodeDragCancel();
  }
}
