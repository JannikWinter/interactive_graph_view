import "package:flutter/gestures.dart";
import "package:flutter/widgets.dart";

import "../graph_viewport_transform.dart";
import "../interaction/drag_details.dart";
import "../interaction/single_pointer_pan_gesture_recognizer.dart";
import "../interaction/tap_details.dart";
import "../rendering/graph_viewport_base.dart";
import "../rendering/node.dart";
import "../widgets/node.dart";
import "graph_viewport.dart";

class NodeElement<NodeIdType> extends SlottedRenderObjectElement<NodeWidgetSlot, RenderBox> {
  NodeElement(NodeWidget super.widget);

  late TapGestureRecognizer _tapRecognizer;
  late DoubleTapGestureRecognizer _doubleTapRecognizer;
  late LongPressGestureRecognizer _longPressRecognizer;
  late SinglePointerPanGestureRecognizer _panRecognizer;

  @override
  GraphNodeRenderObject get renderObject => super.renderObject as GraphNodeRenderObject;

  @override
  GraphViewportNodeSlot<NodeIdType>? get slot => super.slot as GraphViewportNodeSlot<NodeIdType>?;

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
    _tapRecognizer.onTapDown = (widget.onTapDown != null) ? _onTapDown : null;
    _tapRecognizer.onTap = (widget.onTap != null) ? _onTap : null;

    _doubleTapRecognizer = DoubleTapGestureRecognizer(debugOwner: this);
    _doubleTapRecognizer.onDoubleTapDown = (widget.onTapDown != null) ? _onTapDown : null;
    _doubleTapRecognizer.onDoubleTap = (widget.onDoubleTap != null) ? _onDoubleTap : null;

    _longPressRecognizer = LongPressGestureRecognizer(debugOwner: this);
    _longPressRecognizer.onLongPress = (widget.onLongPress != null) ? _onLongPress : null;

    _panRecognizer = SinglePointerPanGestureRecognizer(debugOwner: this);
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

  void _onTapDown(TapDownDetails details) {
    final RenderGraphViewportBase viewportBase = RenderGraphViewportBase.of(renderObject);
    final GraphViewportTransform viewportTransform = viewportBase.transform;
    final Offset viewportPosition = details.globalPosition - viewportBase.globalPaintOffset;
    final GraphViewportTapDownDetails newDetails = GraphViewportTapDownDetails(
      globalPosition: details.globalPosition,
      viewportPosition: viewportPosition,
      graphPosition: viewportTransform.toGraphSpacePosition(viewportPosition),
    );

    (widget as NodeWidget).onTapDown?.call(newDetails);
  }

  void _onTap() {
    (widget as NodeWidget).onTap?.call();
  }

  void _onDoubleTap() {
    (widget as NodeWidget).onDoubleTap?.call();
  }

  void _onLongPress() {
    (widget as NodeWidget).onLongPress?.call();
  }

  void _onDragDown(DragDownDetails details) {
    final RenderGraphViewportBase viewportBase = RenderGraphViewportBase.of(renderObject);
    final GraphViewportTransform viewportTransform = viewportBase.transform;
    final Offset viewportPosition = details.globalPosition - viewportBase.globalPaintOffset;
    final GraphViewportDragDownDetails newDetails = GraphViewportDragDownDetails(
      globalPosition: details.globalPosition,
      viewportPosition: viewportPosition,
      graphPosition: viewportTransform.toGraphSpacePosition(viewportPosition),
    );

    (widget as NodeWidget).onDragDown?.call(newDetails);
    viewportBase.onNodeDragDown(newDetails, slot!.nodeId);
  }

  void _onDragStart(DragStartDetails details) {
    final RenderGraphViewportBase viewportBase = RenderGraphViewportBase.of(renderObject);
    final GraphViewportTransform viewportTransform = viewportBase.transform;
    final Offset viewportPosition = details.globalPosition - viewportBase.globalPaintOffset;
    final GraphViewportDragStartDetails newDetails = GraphViewportDragStartDetails(
      globalPosition: details.globalPosition,
      viewportPosition: viewportPosition,
      graphPosition: viewportTransform.toGraphSpacePosition(viewportPosition),
    );

    (widget as NodeWidget).onDragStart?.call(newDetails);
    viewportBase.onNodeDragStart(newDetails);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final RenderGraphViewportBase viewportBase = RenderGraphViewportBase.of(renderObject);
    final GraphViewportTransform viewportTransform = viewportBase.transform;
    final Offset viewportPosition = details.globalPosition - viewportBase.globalPaintOffset;
    final GraphViewportDragUpdateDetails newDetails = GraphViewportDragUpdateDetails(
      globalPosition: details.globalPosition,
      viewportPosition: viewportPosition,
      graphPosition: viewportTransform.toGraphSpacePosition(viewportPosition),
      viewportDelta: viewportTransform.toGraphSpaceOffset(details.delta),
      graphDelta: details.delta,
    );

    (widget as NodeWidget).onDragUpdate?.call(newDetails);
    viewportBase.onNodeDragUpdate(newDetails);
  }

  void _onDragEnd(DragEndDetails details) {
    final RenderGraphViewportBase viewportBase = RenderGraphViewportBase.of(renderObject);
    final GraphViewportDragEndDetails newDetails = GraphViewportDragEndDetails();

    (widget as NodeWidget).onDragEnd?.call(newDetails);
    viewportBase.onNodeDragEnd(newDetails);
  }

  void _onDragCancel() {
    final RenderGraphViewportBase viewportBase = RenderGraphViewportBase.of(renderObject);

    (widget as NodeWidget).onDragCancel?.call();
    viewportBase.onNodeDragCancel();
  }
}
