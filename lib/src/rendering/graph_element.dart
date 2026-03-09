import "package:flutter/gestures.dart";
import "package:flutter/rendering.dart";

abstract base class GraphElementRenderObject extends RenderObject {
  PointerDownEventListener? onPointerDown;
  PointerPanZoomStartEventListener? onPointerPanZoomStart;

  @override
  void debugAssertDoesMeetConstraints() {
    // Constraints are never given to GraphElements, so nothing to check here
  }

  @override
  void performResize() {
    // This will never be called, because sizedByParent is false
    assert(false);
  }

  bool hitTest(BoxHitTestResult result, Offset position);

  @override
  void handleEvent(PointerEvent event, covariant HitTestEntry<HitTestTarget> entry) {
    if (event is PointerDownEvent) {
      onPointerDown?.call(event);
    }
    if (event is PointerPanZoomStartEvent) {
      onPointerPanZoomStart?.call(event);
    }
  }
}
