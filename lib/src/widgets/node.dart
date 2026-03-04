import "package:flutter/gestures.dart";
import "package:flutter/material.dart";

import "../drag_details.dart";
import "../elements/node.dart";
import "../render_objects/node.dart";

enum NodeWidgetSlot { content, background, overlay }

typedef GestureNodeDragDownCallback = void Function(NodeDragDownDetails details);
typedef GestureNodeDragStartCallback = void Function(NodeDragStartDetails details);
typedef GestureNodeDragUpdateCallback = void Function(NodeDragUpdateDetails details);
typedef GestureNodeDragEndCallback = void Function(NodeDragEndDetails details);
typedef GestureNodeDragCancelCallback = void Function();

class NodeOverlayConfig {
  const NodeOverlayConfig({
    this.alignmentInNode = Alignment.center,
    this.alignmentAroundAnchor = Alignment.center,
    this.offset = Offset.zero,
  });

  final Alignment alignmentInNode;
  final Alignment alignmentAroundAnchor;
  final Offset offset;

  @override
  bool operator ==(Object other) {
    if (other is! NodeOverlay) return false;
    return alignmentInNode == other.alignmentInNode &&
        alignmentAroundAnchor == other.alignmentAroundAnchor &&
        offset == other.offset;
  }

  @override
  int get hashCode => Object.hash(
    alignmentInNode,
    alignmentAroundAnchor,
    offset,
  );
}

class NodeOverlay extends NodeOverlayConfig {
  const NodeOverlay({
    super.alignmentInNode,
    super.alignmentAroundAnchor,
    super.offset,
    required this.child,
  });

  final Widget child;

  @override
  bool operator ==(Object other) {
    if (other is! NodeOverlay) return false;
    return super == other && child == other.child;
  }

  @override
  int get hashCode => Object.hash(
    super.hashCode,
    child,
  );
}

class NodeWidget extends SlottedMultiChildRenderObjectWidget<NodeWidgetSlot, RenderBox> {
  static const Clip kDefaultClipBehavior = Clip.none;
  const NodeWidget({
    super.key,
    required this.position,
    required this.content,
    required this.background,
    required this.borderRadius,
    this.clipBehavior = kDefaultClipBehavior,
    this.overlay,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    required this.isDragEnabled,
    this.onDragDown,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.onDragCancel,
  });

  final Offset position;
  final Widget content;
  final Widget background;
  final NodeOverlay? overlay;
  final Radius borderRadius;
  final Clip clipBehavior;

  // Tap callbacks
  final GestureTapCallback? onTap;
  final GestureDoubleTapCallback? onDoubleTap;
  final GestureLongPressCallback? onLongPress;

  // Drag callbacks
  final bool isDragEnabled;
  final GestureNodeDragDownCallback? onDragDown;
  final GestureNodeDragStartCallback? onDragStart;
  final GestureNodeDragUpdateCallback? onDragUpdate;
  final GestureNodeDragEndCallback? onDragEnd;
  final GestureNodeDragCancelCallback? onDragCancel;

  @override
  Widget? childForSlot(NodeWidgetSlot slot) {
    return switch (slot) {
      NodeWidgetSlot.content => content,
      NodeWidgetSlot.background => background,
      NodeWidgetSlot.overlay => overlay?.child,
    };
  }

  @override
  GraphNodeRenderObject createRenderObject(BuildContext context) {
    return GraphNodeRenderObject(
      position: position,
      borderRadius: borderRadius,
      clipBehavior: clipBehavior,
      overlayConfig: overlay,
    );
  }

  @override
  NodeElement createElement() {
    return NodeElement(this);
  }

  @override
  void updateRenderObject(BuildContext context, GraphNodeRenderObject renderObject) {
    renderObject
      ..position = position
      ..borderRadius = borderRadius
      ..clipBehavior = clipBehavior
      ..overlayConfig = overlay;
  }

  @override
  Iterable<NodeWidgetSlot> get slots => NodeWidgetSlot.values;
}
