import "package:flutter/gestures.dart";
import "package:flutter/widgets.dart";

import "../edge_data.dart";
import "../graph_viewport_controller.dart";
import "../graph_viewport_transform.dart";
import "../node_data.dart";
import "graph_viewport.dart";

class GraphView<
  NodeIdType,
  NodeDataType extends NodeData<NodeIdType>,
  EdgeIdType,
  EdgeDataType extends EdgeData<EdgeIdType, NodeIdType>
>
    extends StatefulWidget {
  const GraphView({
    super.key,
    required this.viewportController,
    this.initialPosition = Offset.zero,
    this.initialScale = 1.0,
    this.minScale = 0.025,
    this.maxScale = 5,
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

  final GraphViewportController<NodeIdType, NodeDataType, EdgeIdType, EdgeDataType> viewportController;
  final Offset initialPosition;
  final double initialScale;
  final double minScale;
  final double maxScale;
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
  State<GraphView<NodeIdType, NodeDataType, EdgeIdType, EdgeDataType>> createState() =>
      GraphViewState<NodeIdType, NodeDataType, EdgeIdType, EdgeDataType>();
}

class GraphViewState<
  NodeIdType,
  NodeDataType extends NodeData<NodeIdType>,
  EdgeIdType,
  EdgeDataType extends EdgeData<EdgeIdType, NodeIdType>
>
    extends State<GraphView<NodeIdType, NodeDataType, EdgeIdType, EdgeDataType>>
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
    );
    _viewportTransform.addSettleListener(_onTransformSettled);
  }

  @override
  void didUpdateWidget(covariant GraphView<NodeIdType, NodeDataType, EdgeIdType, EdgeDataType> oldWidget) {
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
    return GraphViewport<NodeIdType, NodeDataType, EdgeIdType, EdgeDataType>(
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
