import "package:flutter/gestures.dart";
import "package:flutter/material.dart" show Theme;
import "package:flutter/widgets.dart";

import "../drag_details.dart";
import "../elements/node.dart";
import "../node_overlay.dart";
import "../render_objects/node.dart";
import "../style/node_style.dart";

enum NodeWidgetSlot { content, background, overlay }

typedef GestureNodeDragDownCallback = void Function(NodeDragDownDetails details);
typedef GestureNodeDragStartCallback = void Function(NodeDragStartDetails details);
typedef GestureNodeDragUpdateCallback = void Function(NodeDragUpdateDetails details);
typedef GestureNodeDragEndCallback = void Function(NodeDragEndDetails details);
typedef GestureNodeDragCancelCallback = void Function();

class NodeWidget extends SlottedMultiChildRenderObjectWidget<NodeWidgetSlot, RenderBox> {
  static const Radius kDefaultBorderRadius = Radius.zero;
  static const Clip kDefaultClipBehavior = Clip.none;

  const NodeWidget.custom({
    super.key,
    required this.position,
    required this.content,
    required this.background,
    this.overlay,
    this.borderRadius = kDefaultBorderRadius,
    this.clipBehavior = kDefaultClipBehavior,
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

  factory NodeWidget.basic({
    Key? key,
    required Offset position,
    required String text,
    NodeStyle? style,
    NodeOverlay? overlay,
    Radius borderRadius = kDefaultBorderRadius,
    Clip clipBehavior = kDefaultClipBehavior,
    GestureTapCallback? onTap,
    GestureDoubleTapCallback? onDoubleTap,
    GestureLongPressCallback? onLongPress,
    required bool isDragEnabled,
    GestureNodeDragDownCallback? onDragDown,
    GestureNodeDragStartCallback? onDragStart,
    GestureNodeDragUpdateCallback? onDragUpdate,
    GestureNodeDragEndCallback? onDragEnd,
    GestureNodeDragCancelCallback? onDragCancel,
  }) {
    return NodeWidget.custom(
      key: key,
      position: position,
      content: _SimpleNodeContent(text: text, style: style),
      background: _SimpleNodeBackground(
        style: style,
        borderRadius: borderRadius,
      ),
      overlay: overlay,
      borderRadius: borderRadius,
      clipBehavior: clipBehavior,
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      onLongPress: onLongPress,
      isDragEnabled: isDragEnabled,
      onDragDown: onDragDown,
      onDragStart: onDragStart,
      onDragUpdate: onDragUpdate,
      onDragEnd: onDragEnd,
      onDragCancel: onDragCancel,
    );
  }

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

class _SimpleNodeContent extends StatelessWidget {
  const _SimpleNodeContent({required this.text, this.style});

  final String text;
  final NodeStyle? style;

  @override
  Widget build(BuildContext context) {
    // TODO: implement correct merging of style components
    final NodeStyle effectiveStyle = style ?? Theme.of(context).extension<NodeStyle>() ?? NodeStyle.fallback();

    return Padding(
      padding: effectiveStyle.padding,
      child: Text(
        text,
        style: effectiveStyle.textStyle,
      ),
    );
  }
}

class _SimpleNodeBackground extends StatelessWidget {
  const _SimpleNodeBackground({required this.borderRadius, this.style});

  final Radius borderRadius;
  final NodeStyle? style;

  @override
  Widget build(BuildContext context) {
    // TODO: implement correct merging of style components
    final NodeStyle effectiveStyle = style ?? Theme.of(context).extension<NodeStyle>() ?? NodeStyle.fallback();

    return Container(
      decoration: BoxDecoration(
        color: effectiveStyle.backgroundColor,
        border: effectiveStyle.borderSide != null ? Border.fromBorderSide(effectiveStyle.borderSide!) : null,
        borderRadius: BorderRadius.all(borderRadius),
      ),
    );
  }
}
