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

  /// Determines the set of render objects located at the given position.
  ///
  /// Adds any render objects that contain the point to the
  /// given hit test result, if this render object or one of its descendants
  /// absorbs the hit (preventing objects below this one from being hit).
  ///
  /// The caller is responsible for transforming [position] from global
  /// coordinates to its location relative to the origin of this [GraphElementRenderObject].
  /// This [GraphElementRenderObject] is responsible for checking whether the given position is
  /// within its bounds.
  ///
  /// If transforming is necessary, [HitTestResult.addWithPaintTransform],
  /// [BoxHitTestResult.addWithPaintOffset], or
  /// [BoxHitTestResult.addWithRawTransform] need to be invoked by the caller
  /// to record the required transform operations in the [HitTestResult]. These
  /// methods will also help with applying the transform to `position`.
  ///
  /// Hit testing requires layout to be up-to-date but does not require painting
  /// to be up-to-date. That means a render object can rely upon [performLayout]
  /// having been called in [hitTest] but cannot rely upon [paint] having been
  /// called. For example, a render object might be a child of a [RenderOpacity]
  /// object, which calls [hitTest] on its children when its opacity is zero
  /// even though it does not [paint] its children.
  void hitTest(BoxHitTestResult result, Offset position);

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
