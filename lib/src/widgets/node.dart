import "package:flutter/material.dart" show Theme, ThemeData;
import "package:flutter/widgets.dart";

import "../elements/node.dart";
import "../interaction/gesture_callbacks.dart";
import "../rendering/node.dart";
import "../style/node_style.dart";
import "node_overlay.dart";

/// The `SlotType` [NodeWidget] (a [SlottedMultiChildRenderObjectWidget]) uses for configuring its children.
enum NodeWidgetSlot { content, background, overlay }

/// A widget for configuring, interacting with and styling a node in a graph.
///
/// To display this node, it should be constructed as a child of a [GraphViewport] through [GraphViewport.nodeBuilder].
///
/// To build a node, its ID should first be added to a [GraphViewport]'s [GraphViewport.viewportController].
class NodeWidget<NodeIdType> extends SlottedMultiChildRenderObjectWidget<NodeWidgetSlot, RenderBox> {
  /// Constructs a [NodeWidget] at a given [position] while giving you full customizability for the [content],
  /// [background] and [overlay] widgets.
  ///
  /// If you just want to construct a simple node, which only requires a text, you probably want to use
  /// [NodeWidget.basic].
  ///
  /// Note that only the following [NodeStyle]-properties are applied when using this constructor:
  /// - [NodeStyle.maxWidth] will be used for wrapping the content.
  /// - [NodeStyle.clipBehavior], if not [Clip.none], will clip [content] and [background] according to
  /// [NodeStyle.borderRadius].
  /// - [NodeStyle.borderRadius] will be used for correctly displaying an edge's arrow near the corner of this node.
  ///
  /// The other properties would apply to [content] and [background], which you define yourself.
  ///
  /// To apply the style for this widget, we will search for a non-null value for each [NodeStyle]-property. The applied
  /// `NodeStyle`s are searched in the following order:
  /// 1. the given [style].
  /// 2. the node style of the closest [Theme] widget up the tree (see [ThemeData.extensions]).
  /// 3. [NodeStyle.fallback] which will have a fallback value for every property.
  const NodeWidget.custom({
    super.key,
    required this.position,
    required this.content,
    required this.background,
    this.overlay,
    this.style,
    this.onTapDown,
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

  /// Constructs a [NodeWidget] at a given [position] with given [text], [style] and optional [overlay].
  ///
  /// If you want more control over the content and background of the node, you should use [NodeWidget.custom],
  /// where you define the widgets for [content] and [background] yourself.
  ///
  /// To apply the style for this widget, we will search for a non-null value for each [NodeStyle]-property. The applied
  /// `NodeStyle`s are searched in the following order:
  /// 1. the given [style].
  /// 2. the node style of the closest [Theme] widget up the tree (see [ThemeData.extensions]).
  /// 3. [NodeStyle.fallback] which will have a fallback value for every property.
  factory NodeWidget.basic({
    Key? key,
    required Offset position,
    required String text,
    NodeOverlay? overlay,
    NodeStyle? style,
    GestureGraphViewportTapDownCallback? onTapDown,
    GestureTapCallback? onTap,
    GestureGraphViewportDoubleTapCallback? onDoubleTap,
    GestureGraphViewportLongPressCallback? onLongPress,
    required bool isDragEnabled,
    GestureGraphViewportDragDownCallback? onDragDown,
    GestureGraphViewportDragStartCallback? onDragStart,
    GestureGraphViewportDragUpdateCallback? onDragUpdate,
    GestureGraphViewportDragEndCallback? onDragEnd,
    GestureGraphViewportDragCancelCallback? onDragCancel,
  }) {
    return NodeWidget.custom(
      key: key,
      position: position,
      content: BasicNodeContent(text: text, style: style),
      background: BasicNodeBackground(style: style),
      overlay: overlay,
      style: style,
      onTapDown: onTapDown,
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

  /// The position in the [GraphViewport] where this node will be displayed.
  ///
  /// The node is always centered around the position.
  final Offset position;

  /// The widget used to construct the content of this node.
  ///
  /// This will be put in front of the [background] but behind the [overlay].
  final Widget content;

  /// The widget used to construct the background of this node.
  ///
  /// This will be behind the [content], which will itself be behind the [overlay].
  final Widget background;

  /// The overlay that will be put on top of the [background] and [content].
  ///
  /// The overlay is put into its own layer where it is not affected by [NodeStyle.clipBehavior].
  /// It can be beyond the node's bounds.
  final NodeOverlay? overlay;

  /// This node's own style.
  ///
  /// To apply the style for this widget, we will search for a non-null value for each [NodeStyle]-property. The applied
  /// `NodeStyle`s are searched in the following order:
  /// 1. this [style].
  /// 2. the node style of the closest [Theme] widget up the tree (see [ThemeData.extensions]).
  /// 3. [NodeStyle.fallback] which will have a fallback value for every property.
  final NodeStyle? style;

  /// This callback will be called when a TapDown gesture was registered on this node.
  final GestureGraphViewportTapDownCallback? onTapDown;

  /// This callback will be called when a Tap gesture was registered on this node.
  final GestureGraphViewportTapCallback? onTap;

  /// This callback will be called when a DoubleTap gesture was registered on this node.
  final GestureGraphViewportDoubleTapCallback? onDoubleTap;

  /// This callback will be called when a LongPress gesture was registered on this node.
  final GestureGraphViewportLongPressCallback? onLongPress;

  // Drag callbacks

  /// Whether this node responds to Drag gestures.
  ///
  /// If this is set to `true`, drag gestures will automatically be forwarded to the viewport, which moves this node
  /// and all nodes in [GraphViewportController.movingNodeIds]. Upon ending the drag gesture,
  /// [GraphViewportController.onNodesMoved] will be called.
  ///
  /// If this is set to `false`, [onDragDown], [onDragStart], [onDragUpdate], [onDragEnd] and [onDragCancel] will never
  /// be called.
  final bool isDragEnabled;

  /// This callback will be called when a DragDown gesture was registered on this node and [isDragEnabled] is `true`.
  final GestureGraphViewportDragDownCallback? onDragDown;

  /// This callback will be called when a DragStart gesture was registered on this node and [isDragEnabled] is `true`.
  final GestureGraphViewportDragStartCallback? onDragStart;

  /// This callback will be called when a DragUpdate gesture was registered on this node and [isDragEnabled] is `true`.
  final GestureGraphViewportDragUpdateCallback? onDragUpdate;

  /// This callback will be called when a DragEnd gesture was registered on this node and [isDragEnabled] is `true`.
  final GestureGraphViewportDragEndCallback? onDragEnd;

  /// This callback will be called when a DragCancel gesture was registered on this node and [isDragEnabled] is `true`.
  final GestureGraphViewportDragCancelCallback? onDragCancel;

  @override
  Widget? childForSlot(NodeWidgetSlot slot) {
    return switch (slot) {
      NodeWidgetSlot.content => content,
      NodeWidgetSlot.background => background,
      NodeWidgetSlot.overlay => overlay?.child,
    };
  }

  @override
  GraphNodeRenderObject<NodeIdType> createRenderObject(BuildContext context) {
    final NodeIdType nodeId = (context as NodeElement<NodeIdType>).slot!.nodeId;
    final NodeStyle? themeStyle = Theme.of(context).extension<NodeStyle>();
    final NodeStyle fallbackStyle = NodeStyle.fallback();
    final NodeStyle effectiveStyle = fallbackStyle.merge(themeStyle).merge(style);

    return GraphNodeRenderObject(
      nodeId: nodeId,
      position: position,
      overlayConfig: overlay,
      maxWidth: effectiveStyle.maxWidth!,
      borderRadius: effectiveStyle.borderRadius!,
      clipBehavior: effectiveStyle.clipBehavior!,
    );
  }

  @override
  NodeElement createElement() {
    return NodeElement(this);
  }

  @override
  void updateRenderObject(BuildContext context, GraphNodeRenderObject renderObject) {
    final NodeStyle? themeStyle = Theme.of(context).extension<NodeStyle>();
    final NodeStyle fallbackStyle = NodeStyle.fallback();
    final NodeStyle effectiveStyle = fallbackStyle.merge(themeStyle).merge(style);

    renderObject
      ..position = position
      ..overlayConfig = overlay
      ..maxWidth = effectiveStyle.maxWidth!
      ..borderRadius = effectiveStyle.borderRadius!
      ..clipBehavior = effectiveStyle.clipBehavior!;
  }

  @override
  Iterable<NodeWidgetSlot> get slots => NodeWidgetSlot.values;
}

/// The widget that is used by [NodeWidget.basic] to construct the [NodeWidget.content] of a basic node.
///
/// This only uses [NodeStyle.padding] and [NodeStyle.textStyle] of [style].
///
/// To apply the style for this widget, we will search for a non-null value for each [NodeStyle]-property. The applied
/// `NodeStyle`s are searched in the following order:
/// 1. the given [style].
/// 2. the node style of the closest [Theme] widget up the tree (see [ThemeData.extensions]).
/// 3. [NodeStyle.fallback] which will have a fallback value for every property.
class BasicNodeContent extends StatelessWidget {
  const BasicNodeContent({super.key, required this.text, this.style});

  /// The node's text.
  final String text;

  /// The node's own style.
  ///
  /// To apply the style for this widget, we will search for a non-null value for each [NodeStyle]-property. The applied
  /// `NodeStyle`s are searched in the following order:
  /// 1. this [style].
  /// 2. the node style of the closest [Theme] widget up the tree (see [ThemeData.extensions]).
  /// 3. [NodeStyle.fallback] which will have a fallback value for every property.
  final NodeStyle? style;

  @override
  Widget build(BuildContext context) {
    final NodeStyle? themeStyle = Theme.of(context).extension<NodeStyle>();
    final NodeStyle fallbackStyle = NodeStyle.fallback();
    final NodeStyle effectiveStyle = fallbackStyle.merge(themeStyle).merge(style);

    final EdgeInsets effectivePadding = effectiveStyle.padding!;
    final TextStyle effectiveTextStyle = DefaultTextStyle.of(context).style.merge(effectiveStyle.textStyle);

    return Padding(
      padding: effectivePadding,
      child: Text(
        text,
        style: effectiveTextStyle,
      ),
    );
  }
}

/// The widget that is used by [NodeWidget.basic] to construct the [NodeWidget.background] of a basic node.
///
/// This only uses [NodeStyle.backgroundColor], [NodeStyle.borderSide] and [NodeStyle.borderRadius] from [style].
///
/// To apply the style for this widget, we will search for a non-null value for each [NodeStyle]-property. The applied
/// `NodeStyle`s are searched in the following order:
/// 1. the given [style].
/// 2. the node style of the closest [Theme] widget up the tree (see [ThemeData.extensions]).
/// 3. [NodeStyle.fallback] which will have a fallback value for every property.
class BasicNodeBackground extends StatelessWidget {
  const BasicNodeBackground({super.key, this.style});

  /// The node's own style.
  ///
  /// To apply the style for this widget, we will search for a non-null value for each [NodeStyle]-property. The applied
  /// `NodeStyle`s are searched in the following order:
  /// 1. this [style].
  /// 2. the node style of the closest [Theme] widget up the tree (see [ThemeData.extensions]).
  /// 3. [NodeStyle.fallback] which will have a fallback value for every property.
  final NodeStyle? style;

  @override
  Widget build(BuildContext context) {
    final NodeStyle? themeStyle = Theme.of(context).extension<NodeStyle>();
    final NodeStyle fallbackStyle = NodeStyle.fallback();
    final NodeStyle effectiveStyle = fallbackStyle.merge(themeStyle).merge(style);

    final Color effectiveBackgroundColor = effectiveStyle.backgroundColor!;
    final BorderSide effectiveBorderSide = effectiveStyle.borderSide!;
    final Radius effectiveBorderRadius = effectiveStyle.borderRadius!;

    return Container(
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        border: Border.fromBorderSide(effectiveBorderSide),
        borderRadius: BorderRadius.all(effectiveBorderRadius),
      ),
    );
  }
}
