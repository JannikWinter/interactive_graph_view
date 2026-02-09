import "package:flutter/gestures.dart";
import "package:flutter/material.dart";

import "../drag_details.dart";
import "../render_objects/graph_viewport_base.dart";
import "../render_objects/node.dart";
import "../widgets/node.dart";

class NodeElement extends SlottedRenderObjectElement<NodeWidgetSlot, RenderBox> {
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

    _tapRecognizer = TapGestureRecognizer(debugOwner: this);
    _tapRecognizer.onTap = widget.onTap;

    _doubleTapRecognizer = DoubleTapGestureRecognizer(debugOwner: this);
    _doubleTapRecognizer.onDoubleTap = widget.onDoubleTap;

    _longPressRecognizer = LongPressGestureRecognizer(debugOwner: this);
    _longPressRecognizer.onLongPress = widget.onLongPress;

    _panRecognizer = PanGestureRecognizer(debugOwner: this);
    if ([
      widget.onPanDown,
      widget.onPanStart,
      widget.onPanUpdate,
      widget.onPanEnd,
      widget.onPanCancel,
    ].nonNulls.isNotEmpty) {
      _panRecognizer.onDown = _onPanDown;
      _panRecognizer.onStart = _onPanStart;
      _panRecognizer.onUpdate = _onPanUpdate;
      _panRecognizer.onEnd = _onPanEnd;
      _panRecognizer.onCancel = _onPanCancel;
    }

    renderObject.onPointerDown = _handlePointerDown;
    renderObject.onPointerPanZoomStart = _handlePointerPanZoomStart;
  }

  @override
  void update(NodeWidget newWidget) {
    super.update(newWidget);

    _tapRecognizer = TapGestureRecognizer(debugOwner: this);
    _tapRecognizer.onTap = newWidget.onTap;

    _doubleTapRecognizer = DoubleTapGestureRecognizer(debugOwner: this);
    _doubleTapRecognizer.onDoubleTap = newWidget.onDoubleTap;

    _longPressRecognizer = LongPressGestureRecognizer(debugOwner: this);
    _longPressRecognizer.onLongPress = newWidget.onLongPress;

    _panRecognizer = PanGestureRecognizer(debugOwner: this);
    if ([
      newWidget.onPanDown,
      newWidget.onPanStart,
      newWidget.onPanUpdate,
      newWidget.onPanEnd,
      newWidget.onPanCancel,
    ].nonNulls.isNotEmpty) {
      _panRecognizer.onDown = _onPanDown;
      _panRecognizer.onStart = _onPanStart;
      _panRecognizer.onUpdate = _onPanUpdate;
      _panRecognizer.onEnd = _onPanEnd;
      _panRecognizer.onCancel = _onPanCancel;
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

  void _onPanDown(DragDownDetails details) {
    final NodeDragDownDetails newDetails = RenderGraphViewportBase.of(renderObject).convertDragDownDetails(details);
    (widget as NodeWidget).onPanDown?.call(newDetails);
  }

  void _onPanStart(DragStartDetails details) {
    final NodeDragStartDetails newDetails = RenderGraphViewportBase.of(renderObject).convertDragStartDetails(details);
    (widget as NodeWidget).onPanStart?.call(newDetails);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final NodeDragUpdateDetails newDetails = RenderGraphViewportBase.of(renderObject).convertDragUpdateDetails(details);
    (widget as NodeWidget).onPanUpdate?.call(newDetails);
  }

  void _onPanEnd(DragEndDetails details) {
    final NodeDragEndDetails newDetails = RenderGraphViewportBase.of(renderObject).convertDragEndDetails(details);
    (widget as NodeWidget).onPanEnd?.call(newDetails);
  }

  void _onPanCancel() {
    (widget as NodeWidget).onPanCancel?.call();
  }
}
