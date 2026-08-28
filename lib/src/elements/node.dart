import "package:flutter/gestures.dart";
import "package:flutter/widgets.dart";

import "../interaction/drag_details.dart";
import "../interaction/single_pointer_pan_gesture_recognizer.dart";
import "../interaction/tap_details.dart";
import "../rendering/graph_viewport.dart";
import "../rendering/graph_viewport_base.dart";
import "../rendering/node.dart";
import "../widgets/node.dart";

class NodeElement extends SlottedRenderObjectElement<NodeWidgetSlot, RenderBox> {
  NodeElement(NodeWidget super.widget);

  late TapGestureRecognizer _tapRecognizer;
  late DoubleTapGestureRecognizer _doubleTapRecognizer;
  late LongPressGestureRecognizer _longPressRecognizer;
  late SinglePointerPanGestureRecognizer _panRecognizer;

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

    final Offset globalPosition = details.globalPosition;
    final Offset viewportPosition = details.globalPosition - viewportBase.globalPaintOffset;
    final Offset graphPosition;
    if (viewportBase is RenderGraphViewport) {
      graphPosition = viewportBase.transform.toGraphSpacePosition(viewportPosition);
    } else {
      graphPosition = viewportPosition;
    }

    final newDetails = GraphViewportTapDownDetails(
      globalPosition: globalPosition,
      viewportPosition: viewportPosition,
      graphPosition: graphPosition,
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

    final Offset globalPosition = details.globalPosition;
    final Offset viewportPosition = details.globalPosition - viewportBase.globalPaintOffset;
    final Offset graphPosition;
    if (viewportBase is RenderGraphViewport) {
      graphPosition = viewportBase.transform.toGraphSpacePosition(viewportPosition);
    } else {
      graphPosition = viewportPosition;
    }

    final newDetails = GraphViewportDragDownDetails(
      globalPosition: globalPosition,
      viewportPosition: viewportPosition,
      graphPosition: graphPosition,
    );

    (widget as NodeWidget).onDragDown?.call(newDetails);
    if (viewportBase is RenderGraphViewport) {
      viewportBase.onNodeDragDown(newDetails);
    }
  }

  void _onDragStart(DragStartDetails details) {
    final RenderGraphViewportBase viewportBase = RenderGraphViewportBase.of(renderObject);

    final Offset globalPosition = details.globalPosition;
    final Offset viewportPosition = details.globalPosition - viewportBase.globalPaintOffset;
    final Offset graphPosition;
    if (viewportBase is RenderGraphViewport) {
      graphPosition = viewportBase.transform.toGraphSpacePosition(viewportPosition);
    } else {
      graphPosition = viewportPosition;
    }

    final newDetails = GraphViewportDragStartDetails(
      globalPosition: globalPosition,
      viewportPosition: viewportPosition,
      graphPosition: graphPosition,
    );

    (widget as NodeWidget).onDragStart?.call(newDetails);
    if (viewportBase is RenderGraphViewport) {
      viewportBase.onNodeDragStart(newDetails);
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final RenderGraphViewportBase viewportBase = RenderGraphViewportBase.of(renderObject);

    final Offset globalPosition = details.globalPosition;
    final Offset viewportPosition = details.globalPosition - viewportBase.globalPaintOffset;
    final Offset viewportDelta = details.delta;
    final Offset graphPosition;
    final Offset graphDelta;
    if (viewportBase is RenderGraphViewport) {
      graphPosition = viewportBase.transform.toGraphSpacePosition(viewportPosition);
      graphDelta = viewportBase.transform.toGraphSpaceOffset(viewportDelta);
    } else {
      graphPosition = viewportPosition;
      graphDelta = viewportDelta;
    }

    final newDetails = GraphViewportDragUpdateDetails(
      globalPosition: globalPosition,
      viewportPosition: viewportPosition,
      viewportDelta: viewportDelta,
      graphPosition: graphPosition,
      graphDelta: graphDelta,
    );

    (widget as NodeWidget).onDragUpdate?.call(newDetails);
    if (viewportBase is RenderGraphViewport) {
      viewportBase.onNodeDragUpdate(newDetails);
    }
  }

  void _onDragEnd(DragEndDetails details) {
    final RenderGraphViewportBase viewportBase = RenderGraphViewportBase.of(renderObject);

    final newDetails = GraphViewportDragEndDetails();

    (widget as NodeWidget).onDragEnd?.call(newDetails);
    if (viewportBase is RenderGraphViewport) {
      viewportBase.onNodeDragEnd(newDetails);
    }
  }

  void _onDragCancel() {
    final RenderGraphViewportBase viewportBase = RenderGraphViewportBase.of(renderObject);

    (widget as NodeWidget).onDragCancel?.call();
    if (viewportBase is RenderGraphViewport) {
      viewportBase.onNodeDragCancel();
    }
  }
}
