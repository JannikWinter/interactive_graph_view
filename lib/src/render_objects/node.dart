import "dart:math";

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";

import "../config.dart";
import "../parent_data.dart";
import "../widgets/node.dart";
import "graph_element.dart";

final class GraphNodeRenderObject extends GraphElementRenderObject
    with SlottedContainerRenderObjectMixin<NodeWidgetSlot, RenderBox> {
  GraphNodeRenderObject({
    required Radius borderRadius,
    required NodeOverlayConfig? overlayConfig,
  }) : _borderRadius = borderRadius,
       _overlayConfig = overlayConfig;

  Offset get position => (parentData as GraphViewportNodeParentData).positionWithDragOffset;

  Radius _borderRadius;
  Radius get borderRadius => _borderRadius;
  set borderRadius(Radius value) {
    if (_borderRadius == value) return;

    _borderRadius = value;
    markParentNeedsLayout();
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
      BoxConstraints(
        maxWidth: Config.nodeMaxWidth, // TODO: make getter/setter for maxWidth in this RenderObject
      ),
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

    context.paintChild(background, position - Offset(background.size.width, background.size.height) / 2);
    context.paintChild(content, position - Offset(content.size.width, content.size.height) / 2);

    if (overlay != null) {
      context.paintChild(
        overlay!,
        position +
            Offset(size.width * overlayConfig!.alignmentInNode.x, size.height * overlayConfig!.alignmentInNode.y) / 2 -
            overlay!.size.center(Offset.zero) +
            Offset(
                  overlay!.size.width * overlayConfig!.alignmentAroundAnchor.x,
                  overlay!.size.height * overlayConfig!.alignmentAroundAnchor.y,
                ) /
                2 +
            overlayConfig!.offset,
      );
    }

    context.canvas.restore();
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.translate(position.dx, position.dy);
    transform.translate(-child.size.width / 2, -child.size.height / 2);
  }

  @override
  Rect get semanticBounds => Rect.fromCenter(center: position, width: size.width, height: size.height);

  @override
  bool hitTest(BoxHitTestResult result, Offset position) {
    final bool wasContentHit = result.addWithPaintOffset(
      offset: -content.size.center(Offset.zero),
      position: position,
      hitTest: (result, position) => content.hitTest(result, position: position),
    );
    final bool wasBackgroundHit = result.addWithPaintOffset(
      offset: -background.size.center(Offset.zero),
      position: position,
      hitTest: (result, position) => background.hitTest(result, position: position),
    );
    final bool wasSelfHit = result.addWithPaintOffset(
      offset: -size.center(Offset.zero),
      position: position,
      hitTest: (result, position) => size.contains(position),
    );

    if (wasSelfHit || wasBackgroundHit || wasContentHit) {
      result.add(HitTestEntry(this));
      return true;
    }

    return false;
  }
}
