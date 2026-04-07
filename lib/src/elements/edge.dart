import "package:flutter/gestures.dart";
import "package:flutter/widgets.dart";

import "../graph_viewport_transform.dart";
import "../interaction/tap_details.dart";
import "../rendering/edge.dart";
import "../rendering/graph_viewport_base.dart";
import "../widgets/edge.dart";

class EdgeElement extends LeafRenderObjectElement {
  EdgeElement(EdgeWidget super.widget);

  late TapGestureRecognizer _tapRecognizer;
  late LongPressGestureRecognizer _longPressRecognizer;

  @override
  GraphEdgeRenderObject get renderObject => super.renderObject as GraphEdgeRenderObject;

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);

    final EdgeWidget widget = this.widget as EdgeWidget;

    _tapRecognizer = TapGestureRecognizer(debugOwner: this);
    _tapRecognizer.onTapDown = (widget.onTapDown != null) ? _onTapDown : null;
    _tapRecognizer.onTap = (widget.onTap != null) ? _onTap : null;

    _longPressRecognizer = LongPressGestureRecognizer(debugOwner: this);
    _longPressRecognizer.onLongPress = (widget.onLongPress != null) ? _onLongPress : null;

    renderObject.onPointerDown = _handlePointerDown;
    renderObject.onPointerPanZoomStart = _handlePointerPanZoomStart;
  }

  @override
  void update(EdgeWidget newWidget) {
    super.update(newWidget);

    _tapRecognizer.onTap = newWidget.onTap;
  }

  void _handlePointerDown(PointerDownEvent event) {
    _tapRecognizer.addPointer(event);
    _longPressRecognizer.addPointer(event);
  }

  void _handlePointerPanZoomStart(PointerPanZoomStartEvent event) {
    _tapRecognizer.addPointerPanZoom(event);
    _longPressRecognizer.addPointerPanZoom(event);
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

    (widget as EdgeWidget).onTapDown?.call(newDetails);
  }

  void _onTap() {
    (widget as EdgeWidget).onTap?.call();
  }

  void _onLongPress() {
    (widget as EdgeWidget).onLongPress?.call();
  }
}
