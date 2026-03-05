import "package:flutter/gestures.dart";
import "package:flutter/widgets.dart";

import "../graph_viewport_controller.dart";
import "../graph_viewport_transform.dart";
import "../interaction_config.dart";
import "graph_viewport.dart";

class GraphView<NodeIdType, EdgeIdType> extends StatefulWidget {
  static const Offset kDefaultInitialPosition = Offset.zero;
  static const double kDefaultInitialScale = 1.0;
  static const double kDefaultMinScale = 0.025;
  static const double kDefaultMaxScale = 5.0;
  static const double kDefaultCacheExtent = GraphViewport.kDefaultCacheExtent;

  const GraphView({
    super.key,
    required this.viewportController,
    this.initialPosition = kDefaultInitialPosition,
    this.initialScale = kDefaultInitialScale,
    this.minScale = kDefaultMinScale,
    this.maxScale = kDefaultMaxScale,
    this.cacheExtent = kDefaultCacheExtent,
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

  final GraphViewportController<NodeIdType, EdgeIdType> viewportController;
  final Offset initialPosition;
  final double initialScale;
  final double minScale;
  final double maxScale;
  final double cacheExtent;
  final InteractionConfig interactionConfig;
  final NodeBuilder<NodeIdType> nodeBuilder;
  final EdgeBuilder<EdgeIdType> edgeBuilder;
  final TransformSettleListener? onTransformSettled;
  final GestureTapDownCallback? onTapDown;
  final GestureTapCallback? onTap;
  final GestureTapDownCallback? onDoubleTapDown;
  final GestureDoubleTapCallback? onDoubleTap;
  final GestureScaleStartCallback? onScaleStart;
  final GestureScaleUpdateCallback? onScaleUpdate;
  final GestureScaleEndCallback? onScaleEnd;

  @override
  State<GraphView<NodeIdType, EdgeIdType>> createState() => GraphViewState<NodeIdType, EdgeIdType>();
}

class GraphViewState<NodeIdType, EdgeIdType> extends State<GraphView<NodeIdType, EdgeIdType>>
    with TickerProviderStateMixin {
  late final GraphViewportTransform _viewportTransform;

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
      cacheExtent: widget.cacheExtent,
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
