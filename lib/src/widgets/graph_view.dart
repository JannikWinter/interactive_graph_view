import "package:flutter/gestures.dart";
import "package:flutter/widgets.dart";

import "../graph_viewport_controller.dart";
import "../graph_viewport_transform.dart";
import "graph_viewport.dart";

class GraphView extends StatefulWidget {
  const GraphView({
    super.key,
    required this.viewportController,
    this.initialPosition = Offset.zero,
    this.initialScale = 1.0,
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
  });

  final GraphViewportController viewportController;
  final Offset initialPosition;
  final double initialScale;
  final NodeBuilder nodeBuilder;
  final EdgeBuilder edgeBuilder;
  final TransformSettleListener? onTransformSettled;
  final GestureTapDownCallback? onTapDown;
  final GestureTapCallback? onTap;
  final GestureTapDownCallback? onDoubleTapDown;
  final GestureDoubleTapCallback? onDoubleTap;
  final GestureScaleStartCallback? onScaleStart;
  final GestureScaleUpdateCallback? onScaleUpdate;
  final GestureScaleEndCallback? onScaleEnd;

  @override
  State<GraphView> createState() => GraphViewState();
}

class GraphViewState extends State<GraphView> with TickerProviderStateMixin {
  late final GraphViewportTransform _viewportTransform;

  GraphViewportTransform get viewportTransform => _viewportTransform;

  @override
  void initState() {
    super.initState();

    _viewportTransform = GraphViewportTransform(
      initialPosition: widget.initialPosition,
      initialScale: widget.initialScale,
      vsync: this,
    );
    _viewportTransform.addSettleListener(_onTransformSettled);
  }

  @override
  Widget build(BuildContext context) {
    return GraphViewport(
      viewportController: widget.viewportController,
      transform: _viewportTransform,
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
