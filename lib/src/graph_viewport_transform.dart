import "dart:async";
import "dart:math" as math;
import "dart:ui";

import "package:flutter/scheduler.dart";
import "package:flutter/widgets.dart";

import "interaction/drag_details.dart";
import "interaction/graph_viewport_behavior.dart";
import "interaction/graph_visibility.dart";
import "interaction/interaction_config.dart";
import "util/extensions.dart" show NotEmptyRect;

/// A callback for when the move of the viewport transform, that was initiated by the user, stops moving.
typedef TransformSettleListener = void Function(Offset position, double scale);

/// The transform used by a [GraphViewport].
///
/// The [position] and [scale] together with the size of the viewport determine, which part of the viewport is visible.
///
/// You can use this class to programmatically change the visible part of the viewport.
class GraphViewportTransform extends ChangeNotifier {
  static (GraphViewportMoveBehavior?, GraphViewportZoomBehavior?) kDefaultShowInViewportBehavior(
    GraphVisibility visibility,
    double scale,
    Size paddedSize,
    Size viewportSize,
    Size targetSize,
  ) {
    final GraphViewportMoveBehavior moveBehavior = switch (visibility) {
      GraphVisibility.fitting => GraphViewportMoveBehavior.screenCenter,
      GraphVisibility.fullyVisibleAndInPadding => GraphViewportMoveBehavior.screenCenter,
      GraphVisibility.fullyVisibleButNotFullyInPadding => GraphViewportMoveBehavior.screenCenter,
      GraphVisibility.partiallyVisible => GraphViewportMoveBehavior.screenEdge,
      GraphVisibility.notVisible => GraphViewportMoveBehavior.screenEdge,
    };

    final GraphViewportZoomBehavior? zoomBehavior;
    if (targetSize.width > paddedSize.width || targetSize.height > paddedSize.height) {
      zoomBehavior = GraphViewportZoomToFitBehavior();
    } else {
      zoomBehavior = null;
    }

    return (moveBehavior, zoomBehavior);
  }

  /// Constructs a transform at a given [initialPosition] and [initialScale].
  ///
  /// [minScale] must be larger than `0.0` and smaller or equal to [maxScale].
  /// [initialScale] must be between [minScale] and [maxScale], inclusively.
  GraphViewportTransform({
    required Offset initialPosition,
    required double initialScale,
    required double minScale,
    required double maxScale,
    required TickerProvider vsync,
    required this.interactionConfig,
  }) : assert(minScale > 0),
       assert(maxScale >= minScale),
       assert(initialScale >= minScale && initialScale <= maxScale),
       _position = initialPosition,
       _scale = initialScale,
       _minScale = minScale,
       _maxScale = maxScale,
       _vsync = vsync;

  /// The position at the center of the viewport.
  Offset get position => _position;
  Offset _position;
  set position(Offset value) {
    final Offset valueClamped = _clampPosition(value);

    if (_position == valueClamped) {
      return;
    }

    _position = valueClamped;
    notifyListeners();
  }

  Offset _clampPosition(Offset value) {
    return Offset(
      clampDouble(
        value.dx,
        contentRect.left - viewportSize.width / (2 * scale),
        contentRect.right + viewportSize.width / (2 * scale),
      ),
      clampDouble(
        value.dy,
        contentRect.top - viewportSize.height / (2 * scale),
        contentRect.bottom + viewportSize.height / (2 * scale),
      ),
    );
  }

  /// The scale at which the viewport is displayed.
  ///
  /// This is always clamped to be between [minScale] and [maxScale].
  double get scale => _scale;
  double _scale;
  set scale(double value) {
    final double valueClamped = _clampScale(value);

    if (_scale == valueClamped) {
      return;
    }

    _scale = valueClamped;
    notifyListeners();
  }

  double _clampScale(double value) {
    return clampDouble(value, minScale, maxScale);
  }

  /// The configuration for the user interactions.
  InteractionConfig interactionConfig;

  /// The minimum scale that this viewport can display.
  ///
  /// Must be smaller or equal to [maxScale].
  ///
  /// [scale] will always be clamped between this and [maxScale].
  double get minScale => _minScale;
  double _minScale;
  set minScale(double value) {
    if (_minScale == value) return;

    assert(value <= maxScale);

    _minScale = value;

    if (scale < _minScale) {
      scale = _minScale;
    }
  }

  /// The maximum scale that this viewport can display.
  ///
  /// Must be greater or equal to [minScale].
  ///
  /// [scale] will always be clamped between this and [minScale].
  double get maxScale => _maxScale;
  double _maxScale;
  set maxScale(double value) {
    if (_maxScale == value) return;

    assert(value >= minScale);

    _maxScale = value;

    if (scale > _maxScale) {
      scale = _maxScale;
    }
  }

  /// The size of the [GraphViewport].
  Size get viewportSize => _viewportSize!;
  Size? _viewportSize;

  /// Whether the [GraphViewport] has a size.
  bool get hasViewportSize => _viewportSize != null;

  /// The rect that spans all children of the [GraphViewport].
  Rect get contentRect => _contentRect!;
  Rect? _contentRect;

  /// Whether the [GraphViewport] has a [contentRect].
  bool get hasContentRect => _contentRect != null;

  late double _scaleAtScaleStart;
  AnimationController? _ballisticController;
  final TickerProvider _vsync;

  late Offset _nodeDragParentSpacePositionAtStart;
  late final Ticker _edgeMoveTicker = Ticker(_edgeMoveTick);
  AnimationController? _cameraMoveAnimationController;
  late Offset _edgeMoveDirection;

  /// The rect of the visible part of the content, in graph space.
  ///
  /// {@macro graph_viewport_transform.graph_space}
  Rect get visibleRect => Rect.fromCenter(
    center: position,
    width: viewportSize.width / scale,
    height: viewportSize.height / scale,
  );

  /// The transformation matrix that is internally used to transform the [GraphViewport]'s children to graph space.
  ///
  /// {@macro graph_viewport_transform.graph_space}
  Matrix4 get childTransformMatrix => Matrix4.identity()
    ..translateByDouble(viewportSize.width / 2, viewportSize.height / 2, 0, 1)
    ..scaleByDouble(scale, scale, scale, 1)
    ..translateByDouble(-position.dx, -position.dy, 0, 1);

  /// Applies the [GraphViewport]'s dimension to this transform.
  ///
  /// This gets called internally during layout.
  /// You should usually not call this method yourself.
  void applyViewportDimensions(Size size) {
    _viewportSize = size;
  }

  /// Applies the dimensions of the [GraphViewport]'s content (all children and edges) to this transform.
  ///
  /// This gets called internally during layout.
  /// You should usually not call this method yourself.
  void applyContentDimensions(Rect rect) {
    _contentRect = rect;
  }

  Future<void> showInViewport({
    required Rect targetRect_GS,
    EdgeInsets padding = EdgeInsets.zero,
    EdgeInsets margin = EdgeInsets.zero,
    GraphViewportBehaviorResolver? behavior,
    Duration? duration,
    Curve? curve,
  }) async {
    _ballisticController?.stop();

    final Offset targetPosition_GS = targetRect_GS.center;
    final Size targetSize_GS = targetRect_GS.size;

    final Rect viewportRect_SS = Rect.fromLTWH(0, 0, viewportSize.width, viewportSize.height);
    final Rect visibleViewportRect_SS = margin.deflateRect(viewportRect_SS);
    final Rect paddedViewportRect_SS = padding.deflateRect(visibleViewportRect_SS);

    final Rect visibleViewportRect_GS = toGraphSpaceRect(visibleViewportRect_SS);
    final Rect paddedViewportRect_GS = toGraphSpaceRect(paddedViewportRect_SS);

    final Rect visiblePartOfTargetRect_GS = visibleViewportRect_GS.intersect(targetRect_GS);
    final Rect paddedVisiblePartOfTargetRect_GS = paddedViewportRect_GS.intersect(targetRect_GS);

    const epsilon = 0.2;

    final GraphVisibility actualVisibility;
    if (scale == maxScale &&
        targetRect_GS.left >= paddedViewportRect_GS.left - epsilon &&
        targetRect_GS.right <= paddedViewportRect_GS.right + epsilon &&
        targetRect_GS.top >= paddedViewportRect_GS.top - epsilon &&
        targetRect_GS.bottom <= paddedViewportRect_GS.bottom + epsilon) {
      // Target is as big as it can be, but still smaller than the padded viewport. So it is as fitting as it could be
      actualVisibility = GraphVisibility.fitting;
    } else if ((targetRect_GS.left >= paddedViewportRect_GS.left - epsilon &&
            targetRect_GS.right <= paddedViewportRect_GS.right + epsilon &&
            (targetRect_GS.top - paddedViewportRect_GS.top).abs() < epsilon &&
            (targetRect_GS.bottom - paddedViewportRect_GS.bottom).abs() < epsilon) ||
        (targetRect_GS.top >= paddedViewportRect_GS.top - epsilon &&
            targetRect_GS.bottom <= paddedViewportRect_GS.bottom + epsilon &&
            (targetRect_GS.left - paddedViewportRect_GS.left).abs() < epsilon &&
            (targetRect_GS.right - paddedViewportRect_GS.right).abs() < epsilon)) {
      actualVisibility = GraphVisibility.fitting;
    } else if (paddedVisiblePartOfTargetRect_GS == targetRect_GS) {
      actualVisibility = GraphVisibility.fullyVisibleAndInPadding;
    } else if (visiblePartOfTargetRect_GS == targetRect_GS) {
      actualVisibility = GraphVisibility.fullyVisibleButNotFullyInPadding;
    } else if (visiblePartOfTargetRect_GS.isNotEmpty) {
      actualVisibility = GraphVisibility.partiallyVisible;
    } else {
      actualVisibility = GraphVisibility.notVisible;
    }

    final GraphViewportBehaviorResolver behaviorResolver = behavior ?? kDefaultShowInViewportBehavior;
    final (GraphViewportMoveBehavior? moveBehavior, GraphViewportZoomBehavior? zoomBehavior) = behaviorResolver(
      actualVisibility,
      scale,
      paddedViewportRect_GS.size,
      visibleViewportRect_GS.size,
      targetSize_GS,
    );

    double newScale = _scale;
    switch (zoomBehavior) {
      case GraphViewportZoomToFitBehavior():
        newScale =
            _scale /
            math.max(
              targetSize_GS.width / paddedViewportRect_GS.width,
              targetSize_GS.height / paddedViewportRect_GS.height,
            );
      case GraphViewportZoomToScaleBehavior(scale: final double targetScale):
        newScale = targetScale;

      case null:
        newScale = _scale;
    }
    newScale = _clampScale(newScale);

    final Size newPaddedViewportSize_GS = toGraphSpaceSize(
      paddedViewportRect_SS.size,
      scale: newScale,
    );

    // adjust newPosition to be in center of padded viewport instead of viewport center
    final Offset adjustment_SS = viewportRect_SS.center - paddedViewportRect_SS.center;
    final Offset adjustment_GS = toGraphSpaceOffset(adjustment_SS, scale: newScale);

    Offset newPosition;
    switch (moveBehavior) {
      case GraphViewportMoveBehavior.screenCenter:
        newPosition = targetPosition_GS + adjustment_GS;

      case GraphViewportMoveBehavior.screenEdge:
        final Size clampSize_GS = Size(
          newPaddedViewportSize_GS.width - targetRect_GS.width,
          newPaddedViewportSize_GS.height - targetRect_GS.height,
        );
        final Rect clampRect_GS = Rect.fromCenter(
          center: targetPosition_GS,
          width: clampSize_GS.width,
          height: clampSize_GS.height,
        );

        final double newX;
        if (clampRect_GS.width > 0.0) {
          newX = clampDouble(_position.dx - adjustment_GS.dx, clampRect_GS.left, clampRect_GS.right) + adjustment_GS.dx;
        } else {
          newX = targetPosition_GS.dx + adjustment_GS.dx;
        }
        final double newY;
        if (clampRect_GS.height > 0.0) {
          newY = clampDouble(_position.dy - adjustment_GS.dy, clampRect_GS.top, clampRect_GS.bottom) + adjustment_GS.dy;
        } else {
          newY = targetPosition_GS.dy + adjustment_GS.dy;
        }

        newPosition = Offset(newX, newY);

      case null:
        // keep position, don't move
        newPosition = _position;
    }

    if (duration == null) {
      position = newPosition;
      scale = newScale;
    } else {
      await animateTo(
        targetPosition: newPosition,
        targetScale: newScale,
        duration: duration,
        curve: curve ?? Curves.linear,
      );
    }
  }

  Future<void> animateTo({
    required Offset targetPosition,
    double? targetScale,
    required Duration duration,
    Curve curve = Curves.linear,
  }) {
    _cameraMoveAnimationController?.stop();

    final controller = AnimationController(
      duration: duration,
      vsync: _vsync,
    );

    final Offset startPosition = _position;
    final double startScale = _scale;

    final Tween<double> scaleTween = Tween(begin: startScale, end: targetScale);

    void tick() {
      scale = scaleTween.evaluate(controller);

      // Compute the interpolated camera position so that the target smoothly moves
      // from startPosition to targetPosition while compensating for the current scale.
      // The (startScale / scale) factor keeps the target visually stable during zoom,
      // and (1 - controller.value) gradually reduces the offset until the camera
      // aligns exactly with targetPosition at the end of the animation.
      position = targetPosition - (targetPosition - startPosition) * (startScale / scale) * (1 - controller.value);
    }

    controller.addListener(tick);
    final TickerFuture tickerFuture =
        controller.animateTo(
          1.0,
          duration: duration,
          curve: curve,
        )..whenCompleteOrCancel(
          () {
            controller.dispose();
            _cameraMoveAnimationController = null;

            _maybeNotifySettleListeners();
          },
        );

    _cameraMoveAnimationController = controller;

    return tickerFuture;
  }

  /// Converts a `Rect` from screen space to graph space.
  ///
  /// {@template graph_viewport_transform.convert_scale}
  /// By default this uses the current scale of this transform. If you supply [scale], this will be used instead.
  /// {@endtemplate}
  ///
  /// {@template graph_viewport_transform.graph_space}
  /// "Graph space" means that the dimensions are in relation to the viewport's internal space (where the nodes and edges
  /// live), with panning and scaling applied.
  /// {@endtemplate}
  ///
  /// {@template graph_viewport_transform.parent_space}
  /// "Parent space" means that the dimensions are in relation to the viewport's parent's space.
  /// {@endtemplate}
  Rect toGraphSpaceRect(Rect screenSpaceRect, {double? scale}) {
    final Offset graphSpacePosition = toGraphSpacePosition(screenSpaceRect.center, scale: scale);
    final Size graphSpaceSize = toGraphSpaceSize(screenSpaceRect.size, scale: scale);
    return Rect.fromCenter(center: graphSpacePosition, width: graphSpaceSize.width, height: graphSpaceSize.height);
  }

  /// Converts a `Size` from screen space to graph space.
  ///
  /// {@macro graph_viewport_transform.convert_scale}
  ///
  /// {@macro graph_viewport_transform.graph_space}
  ///
  /// {@macro graph_viewport_transform.parent_space}
  Size toGraphSpaceSize(Size size, {double? scale}) {
    return size / (scale ?? this.scale);
  }

  /// Converts a **position** `Offset` from screen space to graph space.
  ///
  /// In contrast to [toGraphSpaceOffset] this will also take the current [GraphViewportTransform.position] into
  /// account.
  ///
  /// By default this uses the current position and scale of this transform.
  /// If you supply [position] and/or [scale], they will be used instead.
  ///
  /// {@macro graph_viewport_transform.graph_space}
  ///
  /// {@macro graph_viewport_transform.parent_space}
  Offset toGraphSpacePosition(Offset screenSpacePosition, {Offset? position, double? scale}) {
    return (screenSpacePosition - viewportSize.center(Offset.zero)) / (scale ?? this.scale) +
        (position ?? this.position);
  }

  /// Converts an `Offset` from screen space to graph space.
  ///
  /// In contrast to [toGraphSpacePosition], which does also take an `Offset` argument, this will **not** take the
  /// current [GraphViewportTransform.position] into account.
  ///
  /// {@macro graph_viewport_transform.convert_scale}
  ///
  /// {@macro graph_viewport_transform.graph_space}
  ///
  /// {@macro graph_viewport_transform.parent_space}
  Offset toGraphSpaceOffset(Offset screenSpaceOffset, {double? scale}) {
    return screenSpaceOffset / (scale ?? this.scale);
  }

  /// Converts a **position** `Offset` from graph space to screen space.
  ///
  /// Not that this will also take the current [GraphViewportTransform.position] into account.
  ///
  /// By default this uses the current position and scale of this transform.
  /// If you supply [position] and/or [scale], they will be used instead.
  ///
  /// {@macro graph_viewport_transform.graph_space}
  ///
  /// {@macro graph_viewport_transform.parent_space}
  Offset toScreenSpacePosition(Offset graphSpacePosition, {Offset? position, double? scale}) {
    return ((graphSpacePosition - (position ?? this.position)) * (scale ?? this.scale)) +
        viewportSize.center(Offset.zero);
  }

  bool _isBeingScaled = false;

  /// Handles the ScaleStart gesture to update [position] and [scale].
  void onScaleStart(ScaleStartDetails details) {
    _ballisticController?.stop();
    _cameraMoveAnimationController?.stop();

    _scaleAtScaleStart = scale;

    _isBeingScaled = true;
  }

  /// Handles the ScaleUpdate gesture to update [position] and [scale].
  void onScaleUpdate(ScaleUpdateDetails details) {
    final Offset graphSpaceFocalPointBefore = toGraphSpacePosition(details.localFocalPoint);

    scale = _scaleAtScaleStart * details.scale;

    final Offset graphSpaceFocalPointAfter = toGraphSpacePosition(details.localFocalPoint);
    final Offset delta = graphSpaceFocalPointAfter - graphSpaceFocalPointBefore;

    position -= (delta + details.focalPointDelta / scale);
  }

  /// Handles the ScaleEnd gesture to update [position] and [scale].
  void onScaleEnd(ScaleEndDetails details) {
    if (details.velocity.pixelsPerSecond.distance > interactionConfig.minFlingVelocity) {
      _ballisticController?.stop();

      final _GraphBallisticSimulation simulation = _GraphBallisticSimulation(
        velocity: details.velocity.pixelsPerSecond.distance,
      );
      final AnimationController ballisticController = AnimationController.unbounded(vsync: _vsync);
      _ballisticController = ballisticController;

      final Offset direction = details.velocity.pixelsPerSecond / details.velocity.pixelsPerSecond.distance;
      Offset startPosition = _position;
      void tick() {
        position = startPosition - (direction * ballisticController.value / scale);
      }

      ballisticController
        ..addListener(tick)
        ..animateWith(simulation).whenCompleteOrCancel(
          () {
            ballisticController.dispose();
            assert(_ballisticController == ballisticController);
            _ballisticController = null;
            _maybeNotifySettleListeners();
          },
        );
    }

    _isBeingScaled = false;
    _maybeNotifySettleListeners();
  }

  /// Handles the DragDown gesture of a node to update [position] and [scale].
  void onNodeDragDown(NodeDragDownDetails details) {
    _ballisticController?.stop();
    _cameraMoveAnimationController?.stop();

    _nodeDragParentSpacePositionAtStart = details.parentSpacePosition;
  }

  /// Handles the DragStart gesture of a node to update [position] and [scale].
  void onNodeDragStart(NodeDragStartDetails details) {}

  /// Handles the DragUpdate gesture of a node to update [position] and [scale].
  void onNodeDragUpdate(NodeDragUpdateDetails details) {
    if (!_edgeMoveTicker.isActive &&
        (details.parentSpacePosition - _nodeDragParentSpacePositionAtStart).distance <
            interactionConfig.cameraEdgeMoveConfig.minDragDelta) {
      // The Ticker wasn't started yet but we also haven't exceeded the minDelta, so do nothing
      return;
    }

    double? horizontalCameraMovement;
    if (details.parentSpacePosition.dx < interactionConfig.cameraEdgeMoveConfig.rimDistanceThreshold) {
      horizontalCameraMovement = -1;
    } else if (details.parentSpacePosition.dx >
        viewportSize.width - interactionConfig.cameraEdgeMoveConfig.rimDistanceThreshold) {
      horizontalCameraMovement = 1;
    }

    double? verticalCameraMovement;
    if (details.parentSpacePosition.dy < interactionConfig.cameraEdgeMoveConfig.rimDistanceThreshold) {
      verticalCameraMovement = -1;
    } else if (details.parentSpacePosition.dy >
        viewportSize.height - interactionConfig.cameraEdgeMoveConfig.rimDistanceThreshold) {
      verticalCameraMovement = 1;
    }

    if (horizontalCameraMovement != null || verticalCameraMovement != null) {
      final Offset cameraMovement = Offset(horizontalCameraMovement ?? 0, verticalCameraMovement ?? 0);

      _edgeMoveDirection = cameraMovement / scale;

      if (!_edgeMoveTicker.isActive) {
        _edgeMoveTicker.start();
      }
    } else {
      // we are not near the edge, so stop the ticker and do nothing more
      _edgeMoveTicker.stop();
    }
  }

  /// Handles the DragEnd gesture of a node to update [position] and [scale].
  void onNodeDragEnd(NodeDragEndDetails details) {
    _edgeMoveTicker.stop();

    _maybeNotifySettleListeners();
  }

  /// Handles the DragCancecl gesture of a node to update [position] and [scale].
  void onNodeDragCancel() {
    _edgeMoveTicker.stop();

    _maybeNotifySettleListeners();
  }

  Offset? _lastSettledPosition;
  double? _lastSettledScale;

  final Set<TransformSettleListener> _settleListeners = {};

  void _maybeNotifySettleListeners() {
    if (_isBeingScaled ||
        (_ballisticController != null && _ballisticController!.isAnimating) ||
        (_cameraMoveAnimationController != null && _cameraMoveAnimationController!.isAnimating) ||
        _edgeMoveTicker.isActive) {
      // the camera is currently moving, so don't do anything
      return;
    }

    final Offset currentPosition = _position;
    final double currentScale = _scale;

    if (_lastSettledPosition == currentPosition && _lastSettledScale == currentScale) {
      // the camera didn't move since last settled callback
      return;
    }

    for (final TransformSettleListener listener in _settleListeners) {
      listener(currentPosition, currentScale);
    }
  }

  /// Adds a transform settle listener to this transform, which will be called when a gesture- or animation-initiated
  /// transform movement ended.
  void addSettleListener(TransformSettleListener listener) => _settleListeners.add(listener);

  /// Removes a transform settle listener from this transform, which was earlier add with [addSettleListener].
  void removeSettleListener(TransformSettleListener listener) => _settleListeners.remove(listener);

  void _edgeMoveTick(Duration elapsed) {
    final double buildUpFraction =
        elapsed.inMilliseconds / interactionConfig.cameraEdgeMoveConfig.buildUpDuration.inMilliseconds;
    final double buildUpMultipilier = interactionConfig.cameraEdgeMoveConfig.buildUpCurve.transform(
      math.min(buildUpFraction, 1.0),
    );
    position += _edgeMoveDirection * interactionConfig.cameraEdgeMoveConfig.speed * buildUpMultipilier;
  }
}

class _GraphBallisticSimulation extends Simulation {
  /// Creates a scroll physics simulation that aligns with Android scrolling.
  _GraphBallisticSimulation({
    required this.velocity,
    this.friction = 0.015, // ignore: unused_element_parameter
    super.tolerance, // ignore: unused_element_parameter
  }) {
    _duration = _flingDuration();
    _distance = _flingDistance();
  }

  /// The velocity at which the particle is traveling at the beginning of the
  /// simulation, in logical pixels per second.
  final double velocity;

  /// The amount of friction the particle experiences as it travels.
  ///
  /// The more friction the particle experiences, the sooner it stops and the
  /// less far it travels.
  ///
  /// The default value causes the particle to travel the same total distance
  /// as in the Android scroll physics.
  // See mFlingFriction.
  final double friction;

  /// The total time the simulation will run, in seconds.
  late double _duration;

  /// The total, signed, distance the simulation will travel, in logical pixels.
  late double _distance;

  // See DECELERATION_RATE.
  static final double _kDecelerationRate = math.log(0.78) / math.log(0.9);

  // See INFLEXION.
  static const double _kInflexion = 0.35;

  // See mPhysicalCoeff.  This has a value of 0.84 times Earth gravity,
  // expressed in units of logical pixels per second^2.
  static const double _physicalCoeff =
      9.80665 // g, in meters per second^2
      *
      39.37 // 1 meter / 1 inch
      *
      160.0 // 1 inch / 1 logical pixel
      *
      0.84; // "look and feel tuning"

  // See getSplineFlingDuration().
  double _flingDuration() {
    // See getSplineDeceleration().  That function's value is
    // math.log(velocity.abs() / referenceVelocity).
    final double referenceVelocity = friction * _physicalCoeff / _kInflexion;

    // This is the value getSplineFlingDuration() would return, but in seconds.
    final double androidDuration =
        math.pow(velocity.abs() / referenceVelocity, 1 / (_kDecelerationRate - 1.0)) as double;

    // We finish a bit sooner than Android, in order to travel the
    // same total distance.
    return _kDecelerationRate * _kInflexion * androidDuration;
  }

  // See getSplineFlingDistance().  This returns the same value but with the
  // sign of [velocity], and in logical pixels.
  double _flingDistance() {
    final double distance = velocity * _duration / _kDecelerationRate;
    assert(() {
      // This is the more complicated calculation that getSplineFlingDistance()
      // actually performs, which boils down to the much simpler formula above.
      final double referenceVelocity = friction * _physicalCoeff / _kInflexion;
      final double logVelocity = math.log(velocity.abs() / referenceVelocity);
      final double distanceAgain =
          friction * _physicalCoeff * math.exp(logVelocity * _kDecelerationRate / (_kDecelerationRate - 1.0));
      return (distance.abs() - distanceAgain).abs() < tolerance.distance;
    }());
    return distance;
  }

  @override
  double x(double time) {
    final double t = clampDouble(time / _duration, 0.0, 1.0);
    return _distance * (1.0 - math.pow(1.0 - t, _kDecelerationRate));
  }

  @override
  double dx(double time) {
    final double t = clampDouble(time / _duration, 0.0, 1.0);
    return velocity * math.pow(1.0 - t, _kDecelerationRate - 1.0);
  }

  @override
  bool isDone(double time) {
    return time >= _duration;
  }
}
