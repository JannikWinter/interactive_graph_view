import "package:flutter/gestures.dart";
import "package:flutter/material.dart";

import "../render_objects/edge.dart";
import "../widgets/edge.dart";

class EdgeElement extends LeafRenderObjectElement {
  EdgeElement(EdgeWidget super.widget);

  late TapGestureRecognizer _tapRecognizer;

  @override
  GraphEdgeRenderObject get renderObject => super.renderObject as GraphEdgeRenderObject;

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);

    final EdgeWidget widget = this.widget as EdgeWidget;

    _tapRecognizer = TapGestureRecognizer(debugOwner: this);
    _tapRecognizer.onTap = widget.onTap;

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
  }

  void _handlePointerPanZoomStart(PointerPanZoomStartEvent event) {
    _tapRecognizer.addPointerPanZoom(event);
  }
}
