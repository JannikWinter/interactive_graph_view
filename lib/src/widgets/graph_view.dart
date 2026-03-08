import "package:flutter/gestures.dart";
import "package:flutter/widgets.dart";

import "../graph_viewport_controller.dart";
import "../graph_viewport_transform.dart";
import "../interaction/interaction_config.dart";
import "../style/graph_style.dart";
import "graph_viewport.dart";

/// A widget for interacting with and styling a graph.
///
/// Compared to [GraphViewport] (which this widget uses internally), this widget exposes a simpler interface
/// where scaling of the viewport is already handled for you.
///
/// The graph's nodes and edges are added and removed through the [viewportController]
/// and built and styled as [NodeWidget]s and [EdgeWidget]s in the [nodeBuilder] and [edgeBuilder] respectively.
///
/// Nodes and edges are only identified by their IDs. The respective ID type is supplied through
/// the generic types [NodeIdType] and [EdgeIdType].
class GraphView<NodeIdType, EdgeIdType> extends StatefulWidget {
  /// The default value for [initialPosition] when it is not supplied to the constructor.
  static const Offset kDefaultInitialPosition = Offset.zero;

  /// The default value for [initialScale] when it is not supplied to the constructor.
  static const double kDefaultInitialScale = 1.0;

  /// The default value for [minScale] when it is not supplied to the constructor.
  static const double kDefaultMinScale = 0.025;

  /// The default value for [maxScale] when it is not supplied to the constructor.
  static const double kDefaultMaxScale = 5.0;

  /// The default value for [cacheExtent] when it is not supplied to the constructor.
  static const double kDefaultCacheExtent = GraphViewport.kDefaultCacheExtent;

  /// The default value for [edgeHitboxThickness] when it is not supplied to the constructor.
  static const double kDefaultEdgeHitboxThickness = GraphViewport.kDefaultEdgeHitboxThickness;
  static const bool kDefaultRebuildAllChildrenOnWidgetUpdate = GraphViewport.kDefaultRebuildAllChildrenOnWidgetUpdate;

  /// Constructs a [GraphView].
  const GraphView({
    super.key,
    required this.viewportController,
    this.initialPosition = kDefaultInitialPosition,
    this.initialScale = kDefaultInitialScale,
    this.minScale = kDefaultMinScale,
    this.maxScale = kDefaultMaxScale,
    this.style,
    this.cacheExtent = kDefaultCacheExtent,
    this.edgeHitboxThickness = kDefaultEdgeHitboxThickness,
    this.rebuildAllChildrenOnWidgetUpdate = kDefaultRebuildAllChildrenOnWidgetUpdate,
    this.interactionConfig = const InteractionConfig(),
    required this.nodeBuilder,
    required this.edgeBuilder,
    this.onTransformSettled,
    this.onTapDown,
    this.onTap,
    this.onDoubleTapDown,
    this.onDoubleTap,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd,
  }) : assert(minScale > 0),
       assert(maxScale >= minScale),
       assert(initialScale >= minScale && initialScale <= maxScale);

  /// {@macro graph_viewport.viewport_controller}
  final GraphViewportController<NodeIdType, EdgeIdType> viewportController;

  /// The initial position the [GraphViewportTransform] receives on construction.
  ///
  /// Defaults to [kDefaultInitialPosition].
  final Offset initialPosition;

  /// The initial scale the [GraphViewportTransform] receives on construction.
  ///
  /// Must be between [minScale] and [maxScale], inclusively.
  ///
  /// Defaults to [kDefaultInitialScale].
  final double initialScale;

  /// The minimum scale this GraphView will display.
  ///
  /// Changes to [GraphViewportTransform.scale] are clamped to be between [minScale] and [maxScale].
  ///
  /// Must be greater than `0.0` and less than or equal to [maxScale].
  ///
  /// Defaults to [kDefaultMinScale].
  final double minScale;

  /// The maximum scale this GraphView will display.
  ///
  /// Changes to [GraphViewportTransform.scale] are clamped to be between [minScale] and [maxScale].
  ///
  /// Must be greater than or equal to [minScale].
  ///
  /// Defaults to [kDefaultMaxScale].
  final double maxScale;

  /// {@macro graph_viewport.style}
  final GraphStyle? style;

  /// {@macro graph_viewport.cache_extent}
  ///
  /// Defaults to [kDefaultCacheExtent].
  final double cacheExtent;

  /// {@macro graph_viewport.edge_hitbox_thickness}
  ///
  /// Defaults to [kDefaultEdgeHitboxThickness].
  // TODO: move to interaction config.
  final double edgeHitboxThickness;

  /// {@macro graph_viewport.rebuild_all_children_on_widget_update}
  final bool rebuildAllChildrenOnWidgetUpdate;

  /// The configuration for gesture interactions with this GraphView.
  final InteractionConfig interactionConfig;

  /// {@macro graph_viewport.node_builder}
  final NodeBuilder<NodeIdType> nodeBuilder;

  /// {@macro graph_viewport.edge_builder}
  final EdgeBuilder<EdgeIdType> edgeBuilder;

  /// The callback function for when the viewport transform, that was initiated by the user, stops moving.
  final TransformSettleListener? onTransformSettled;

  /// {@macro graph_viewport.on_tap_down}
  final GestureTapDownCallback? onTapDown;

  /// {@macro graph_viewport.on_tap}
  final GestureTapCallback? onTap;

  /// {@macro graph_viewport.on_double_tap_down}
  final GestureTapDownCallback? onDoubleTapDown;

  /// {@macro graph_viewport.on_double_tap}
  final GestureDoubleTapCallback? onDoubleTap;

  /// {@macro graph_viewport.on_scale_start}
  final GestureScaleStartCallback? onScaleStart;

  /// {@macro graph_viewport.on_scale_update}
  final GestureScaleUpdateCallback? onScaleUpdate;

  /// {@macro graph_viewport.on_scale_end}
  final GestureScaleEndCallback? onScaleEnd;

  @override
  State<GraphView<NodeIdType, EdgeIdType>> createState() => GraphViewState<NodeIdType, EdgeIdType>();
}

/// The state of a [GraphView].
///
/// This can be used to get the [viewportTransform] used by the underlying [GraphViewport].
class GraphViewState<NodeIdType, EdgeIdType> extends State<GraphView<NodeIdType, EdgeIdType>>
    with TickerProviderStateMixin {
  late final GraphViewportTransform _viewportTransform;

  /// The viewport transform used by the underlying [GraphViewport].
  GraphViewportTransform get viewportTransform => _viewportTransform;

  @override
  void initState() {
    super.initState();

    _viewportTransform = GraphViewportTransform(
      minScale: widget.minScale,
      maxScale: widget.maxScale,
      initialPosition: widget.initialPosition,
      initialScale: widget.initialScale,
      vsync: this,
      interactionConfig: widget.interactionConfig,
    );
    _viewportTransform.addSettleListener(_onTransformSettled);
  }

  @override
  void didUpdateWidget(covariant GraphView<NodeIdType, EdgeIdType> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.minScale != widget.minScale) {
      _viewportTransform.minScale = widget.minScale;
    }
    if (oldWidget.maxScale != widget.maxScale) {
      _viewportTransform.maxScale = widget.maxScale;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GraphViewport<NodeIdType, EdgeIdType>(
      viewportController: widget.viewportController,
      transform: _viewportTransform,
      style: widget.style,
      cacheExtent: widget.cacheExtent,
      edgeHitboxThickness: widget.edgeHitboxThickness,
      rebuildAllChildrenOnWidgetUpdate: widget.rebuildAllChildrenOnWidgetUpdate,
      onTapDown: widget.onTapDown,
      onTap: widget.onTap,
      onDoubleTapDown: widget.onTapDown,
      onDoubleTap: widget.onDoubleTap,
      nodeBuilder: widget.nodeBuilder,
      edgeBuilder: widget.edgeBuilder,
      onScaleStart: (details) {
        _onScaleStart(details);
        widget.onScaleStart?.call(details);
      },
      onScaleUpdate: (details) {
        _onScaleUpdate(details);
        widget.onScaleUpdate?.call(details);
      },
      onScaleEnd: (details) {
        _onScaleEnd(details);
        widget.onScaleEnd?.call(details);
      },
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    _viewportTransform.onScaleStart(details);
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    _viewportTransform.onScaleUpdate(details);
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _viewportTransform.onScaleEnd(details);
  }

  void _onTransformSettled(Offset position, double scale) {
    widget.onTransformSettled?.call(position, scale);
  }
}
