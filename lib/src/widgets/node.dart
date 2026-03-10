import "package:flutter/gestures.dart";
import "package:flutter/material.dart" show Theme, ThemeData;
import "package:flutter/widgets.dart";

import "../elements/node.dart";
import "../interaction/drag_details.dart";
import "../rendering/node.dart";
import "../style/node_style.dart";
import "node_overlay.dart";

/// The `SlotType` [NodeWidget] (a [SlottedMultiChildRenderObjectWidget]) uses for configuring its children.
enum NodeWidgetSlot { content, background, overlay }

/// Callback for handling a DragDown gesture that was registered on a node.
typedef GestureNodeDragDownCallback = void Function(NodeDragDownDetails details);

/// Callback for handling a DragStart gesture that was registered on a node.
typedef GestureNodeDragStartCallback = void Function(NodeDragStartDetails details);

/// Callback for handling a DragUpdate gesture that was registered on a node.
typedef GestureNodeDragUpdateCallback = void Function(NodeDragUpdateDetails details);

/// Callback for handling a DragEnd gesture that was registered on a node.
typedef GestureNodeDragEndCallback = void Function(NodeDragEndDetails details);

/// Callback for handling a DragCancel gesture that was registered on a node.
typedef GestureNodeDragCancelCallback = void Function();

/// A widget for configuring, interacting with and styling a node in a graph.
///
/// To display this node, it should be constructed as a child of a [GraphViewport] through [GraphViewport.nodeBuilder].
///
/// To build a node, its ID should first be added to a [GraphViewport]'s [GraphViewport.viewportController].
class NodeWidget extends SlottedMultiChildRenderObjectWidget<NodeWidgetSlot, RenderBox> {
  /// The default value for [borderRadius] when it is not supplied to the constructor.
  static const Radius kDefaultBorderRadius = Radius.zero;

  /// The default value for [clipBehavior] when it is not supplied to the constructor.
  static const Clip kDefaultClipBehavior = Clip.none;

  /// Constructs a [NodeWidget] while giving you full customizability for the [background] and [content] widgets.
  ///
  /// If you want to construct a simple node, which only contains text and accepts a [NodeStyle] (and also respects
  /// a [NodeStyle] supplied through the closest [Theme] up the widget tree), you probably want to use
  /// [NodeWidget.basic].
  ///
  /// Note that this constructor fully ignores the [NodeStyle] supplied by the closest [Theme] up the widget tree as the
  /// [content] and [background] widgets are defined by you.
  /// You can still apply the [Theme] yourself by using `Theme.of(context).extension<NodeStyle>();`.
  ///
  /// Also note that [borderRadius] is only automatically applied when [clipBehavior] is not [Clip.none].
  /// Apart from that, [borderRadius] is only applied to the edges connected to this node.
  const NodeWidget.custom({
    super.key,
    required this.position,
    required this.maxWidth,
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

  /// Constructs a [NodeWidget] at a given [position] with given [text], [style], [overlay], [maxWidth] and
  /// [borderRadius].
  ///
  /// If you want more control over the background and content of the node, you should use [NodeWidget.custom],
  /// where you define the widgets for [content] and [background] yourself.
  ///
  /// To style this widget, we will search for a non-null value for each [NodeStyle]-property. The applied `NodeStyle`s
  /// are searched in the following order:
  /// 1. the given [style].
  /// 2. the node style of the closest [Theme] widget up the tree (see [ThemeData.extensions]).
  /// 3. [NodeStyle.fallback] which will have a fallback value for every property.
  factory NodeWidget.basic({
    Key? key,
    required Offset position,
    required String text,
    required double maxWidth,
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
      maxWidth: maxWidth,
      content: BasicNodeContent(text: text, style: style),
      background: BasicNodeBackground(
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
  /// The overlay is put into its own layer where it is not affected by [clipBehavior].
  /// It can be beyond the node's bounds.
  final NodeOverlay? overlay;

  /// The maximum width this node will take up.
  ///
  /// If the [content] or [background] are wider than [maxWidth], they are clipped depending on the value of
  /// [clipBehavior].
  ///
  /// Note that [overlay] can be outside those bounds and ignores [maxWidth].
  final double maxWidth;

  /// The radius of this node's border.
  ///
  /// This is used for correctly displaying the ends of edges (arrows).
  ///
  /// If [NodeWidget.basic] was used to construct this widget, [borderRadius] is also applied to the [background].
  ///
  /// If [NodeWidget.custom] was used instead, you need to define the borderRadius to the children yourselft.
  ///
  /// If [clipBehavior] was set to a value other than [Clip.none], [borderRadius] is applied to the clip region.
  final Radius borderRadius;

  /// The clipping behavior.
  ///
  /// When this is set to a value other than [Clip.none], [background] and [content] will be clipped according to
  /// [maxWidth] and [borderRadius].
  final Clip clipBehavior;

  // Tap callbacks

  /// This callback will be called when a Tap gesture was registered on this node.
  final GestureTapCallback? onTap;

  /// This callback will be called when a DoubleTap gesture was registered on this node.
  final GestureDoubleTapCallback? onDoubleTap;

  /// This callback will be called when a LongPress gesture was registered on this node.
  final GestureLongPressCallback? onLongPress;

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
  final GestureNodeDragDownCallback? onDragDown;

  /// This callback will be called when a DragStart gesture was registered on this node and [isDragEnabled] is `true`.
  final GestureNodeDragStartCallback? onDragStart;

  /// This callback will be called when a DragUpdate gesture was registered on this node and [isDragEnabled] is `true`.
  final GestureNodeDragUpdateCallback? onDragUpdate;

  /// This callback will be called when a DragEnd gesture was registered on this node and [isDragEnabled] is `true`.
  final GestureNodeDragEndCallback? onDragEnd;

  /// This callback will be called when a DragCancel gesture was registered on this node and [isDragEnabled] is `true`.
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
      maxWidth: maxWidth,
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
      ..maxWidth = maxWidth
      ..borderRadius = borderRadius
      ..clipBehavior = clipBehavior
      ..overlayConfig = overlay;
  }

  @override
  Iterable<NodeWidgetSlot> get slots => NodeWidgetSlot.values;
}

/// The widget that is used by [NodeWidget.basic] to construct the [NodeWidget.content] of a basic node.
///
/// This only uses [text] and [style].
///
/// To style this widget, we will search for a non-null value for each [NodeStyle]-property. The applied `NodeStyle`s
/// are searched in the following order:
/// 1. the given [style].
/// 2. the node style of the closest [Theme] widget up the tree (see [ThemeData.extensions]).
/// 3. [NodeStyle.fallback] which will have a fallback value for every property.
class BasicNodeContent extends StatelessWidget {
  const BasicNodeContent({super.key, required this.text, this.style});

  /// The node's text.
  final String text;

  /// The node's own style.
  ///
  /// To style this widget, we will search for a non-null value for each [NodeStyle]-property. The applied `NodeStyle`s
  /// are searched in the following order:
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
/// This only uses [borderRadius] and [style].
///
/// To style this widget, we will search for a non-null value for each [NodeStyle]-property. The applied `NodeStyle`s
/// are searched in the following order:
/// 1. the given [style].
/// 2. the node style of the closest [Theme] widget up the tree (see [ThemeData.extensions]).
/// 3. [NodeStyle.fallback] which will have a fallback value for every property.
class BasicNodeBackground extends StatelessWidget {
  const BasicNodeBackground({super.key, required this.borderRadius, this.style});

  /// The radius of the background's border.
  final Radius borderRadius;

  /// The node's own style.
  ///
  /// To style this widget, we will search for a non-null value for each [NodeStyle]-property. The applied `NodeStyle`s
  /// are searched in the following order:
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

    return Container(
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        border: Border.fromBorderSide(effectiveBorderSide),
        borderRadius: BorderRadius.all(borderRadius),
      ),
    );
  }
}
