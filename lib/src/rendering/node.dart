import "dart:math";

import "package:flutter/rendering.dart";
import "package:flutter/widgets.dart";

import "../widgets/node.dart";
import "../widgets/node_overlay.dart";
import "graph_element.dart";
import "graph_viewport.dart";
import "node_parent_data.dart";

final class GraphNodeRenderObject<NodeIdType> extends GraphElementRenderObject
    with SlottedContainerRenderObjectMixin<NodeWidgetSlot, RenderBox> {
  GraphNodeRenderObject({
    required this.nodeId,
    required Offset position,
    required BoxConstraints contentConstraints,
    required Radius borderRadius,
    required Clip clipBehavior,
    required NodeOverlayConfig? overlayConfig,
  }) : _position = position,
       _contentConstraints = contentConstraints,
       _borderRadius = borderRadius,
       _clipBehavior = clipBehavior,
       _overlayConfig = overlayConfig;

  final NodeIdType nodeId;

  Offset get positionWithDragOffset => position + (parentData as GraphViewportNodeParentData).dragOffset;

  Offset _position;
  Offset get position => _position;
  set position(Offset value) {
    if (_position == value) return;

    _position = value;
    markNeedsLayout();
  }

  BoxConstraints _contentConstraints;
  BoxConstraints get contentConstraints => _contentConstraints;
  set contentConstraints(BoxConstraints value) {
    if (_contentConstraints == value) return;

    _contentConstraints = value;
    markNeedsLayout();
  }

  Radius _borderRadius;
  Radius get borderRadius => _borderRadius;
  set borderRadius(Radius value) {
    if (_borderRadius == value) return;

    _borderRadius = value;
    markNeedsLayout();
  }

  Clip _clipBehavior;
  Clip get clipBehavior => _clipBehavior;
  set clipBehavior(Clip value) {
    if (_clipBehavior == value) return;

    _clipBehavior = value;
    markNeedsPaint();
  }

  NodeOverlayConfig? _overlayConfig;
  NodeOverlayConfig? get overlayConfig => _overlayConfig;
  set overlayConfig(NodeOverlayConfig? value) {
    if (_overlayConfig == value) return;

    _overlayConfig = value;
    markNeedsPaint();
  }

  RenderBox get content => childForSlot(NodeWidgetSlot.content)!;
  RenderBox get background => childForSlot(NodeWidgetSlot.background)!;
  RenderBox? get overlay => childForSlot(NodeWidgetSlot.overlay);

  bool get hasSize => _size != null;
  Size get size {
    assert(hasSize, "GraphNodeRenderObject was not laid out: $this");
    return _size!;
  }

  Size? _size;
  @protected
  set size(Size value) {
    _size = value;
  }

  @override
  void performLayout() {
    content.layout(
      contentConstraints,
      parentUsesSize: true,
    );

    size = Size(
      max(content.size.width, borderRadius.x * 2),
      max(content.size.height, borderRadius.y * 2),
    );

    background.layout(
      BoxConstraints.tight(size),
    );

    if (overlay != null) {
      overlay!.layout(BoxConstraints(), parentUsesSize: true);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.canvas.save();
    context.canvas.translate(offset.dx, offset.dy);
    context.canvas.translate(positionWithDragOffset.dx, positionWithDragOffset.dy);

    if (clipBehavior != Clip.none) {
      context.pushClipRRect(
        needsCompositing,
        Offset.zero,
        Rect.fromCenter(center: Offset.zero, width: size.width, height: size.height),
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: size.width, height: size.height),
          borderRadius,
        ),
        (context, offset) => _paintChildren(context),
        clipBehavior: clipBehavior,
      );
    } else {
      _paintChildren(context);
    }

    _paintOverlay(context);

    context.canvas.restore();
  }

  void _paintChildren(PaintingContext context) {
    context.paintChild(background, -Offset(background.size.width, background.size.height) / 2);
    context.paintChild(content, -Offset(content.size.width, content.size.height) / 2);
  }

  void _paintOverlay(PaintingContext context) {
    if (overlay != null) {
      context.paintChild(
        overlay!,
        overlayPaintOffset,
      );
    }
  }

  Offset get overlayPaintOffset =>
      Offset(size.width * overlayConfig!.alignmentInNode.x, size.height * overlayConfig!.alignmentInNode.y) / 2 -
      overlay!.size.center(Offset.zero) +
      Offset(
            overlay!.size.width * overlayConfig!.alignmentAroundAnchor.x,
            overlay!.size.height * overlayConfig!.alignmentAroundAnchor.y,
          ) /
          2 +
      overlayConfig!.offset;

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.translateByDouble(positionWithDragOffset.dx, positionWithDragOffset.dy, 0, 1);
    transform.translateByDouble(-child.size.width / 2, -child.size.height / 2, 0, 1);
  }

  @override
  Rect get semanticBounds => Rect.fromCenter(center: positionWithDragOffset, width: size.width, height: size.height);

  @override
  Rect get paintBounds {
    if (overlay == null) {
      return semanticBounds;
    } else {
      final Offset overlayLeftTop = positionWithDragOffset + overlayPaintOffset;
      final Rect overlayBounds = Rect.fromLTWH(
        overlayLeftTop.dx,
        overlayLeftTop.dy,
        overlay!.size.width,
        overlay!.size.height,
      );
      return semanticBounds.expandToInclude(overlayBounds);
    }
  }

  @override
  bool hitTest(BoxHitTestResult result, Offset position) {
    if (overlayConfig != null) {
      result.addWithPaintOffset(
        offset: overlayPaintOffset,
        position: position,
        hitTest: (result, position) => overlay!.hitTest(result, position: position),
      );
    }

    final bool wasSelfHit = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: max(size.width, borderRadius.x * 2),
        height: max(size.height, borderRadius.y * 2),
      ),
      borderRadius,
    ).contains(position);

    if (wasSelfHit) {
      result.addWithPaintOffset(
        offset: -content.size.center(Offset.zero),
        position: position,
        hitTest: (result, position) => content.hitTest(result, position: position),
      );
      result.addWithPaintOffset(
        offset: -background.size.center(Offset.zero),
        position: position,
        hitTest: (result, position) => background.hitTest(result, position: position),
      );
      result.add(HitTestEntry(this));
    }

    return false;
  }

  @override
  void markNeedsLayout() {
    markParentNeedsLayout();
  }

  @override
  void markParentNeedsLayout() {
    super.markParentNeedsLayout();
    (parent as RenderGraphViewport).markNeedsLayoutForNodeChange(nodeId);
  }
}
