import "dart:ui" show Offset;

import "package:flutter/gestures.dart" show Velocity;

/// The scale start details used when a scale gesture inside a [GraphViewport] started.
class GraphViewportScaleStartDetails {
  /// Creates scale start details.
  const GraphViewportScaleStartDetails({
    required this.globalFocalPoint,
    required this.viewportFocalPoint,
    required this.graphFocalPoint,
    required this.pointerCount,
  });

  /// {@template graph_viewport_scale_details.global_focal_point}
  /// The initial focal point of the pointers in contact with the screen.
  ///
  /// Reported in the global coordinate space.
  ///
  /// See also:
  /// * [viewportFocalPoint], which is the same value reported in the coordinate space of the viewport, **without**
  ///   panning and scaling applied.
  /// * [graphFocalPoint], which is the same value reported in the coordinate space of the viewport-content, **with**
  ///   panning and scaling applied.
  /// {@endtemplate}
  final Offset globalFocalPoint;

  /// {@template graph_viewport_scale_details.viewport_focal_point}
  /// The initial focal point of the pointers in contact with the screen.
  ///
  /// Reported in the coordinate space of the viewport, **without** panning and scaling applied.
  ///
  /// See also:
  /// * [globalFocalPoint], which is the same value reported in the global coordinate space.
  /// * [graphFocalPoint], which is the same value reported in the coordinate space of the viewport-content, **with**
  ///   panning and scaling applied.
  /// {@endtemplate}
  final Offset viewportFocalPoint;

  /// {@template graph_viewport_scale_details.graph_focal_point}
  /// The initial focal point of the pointers in contact with the screen.
  ///
  /// Reported in the coordinate space of the viewport-content, **with** panning and scaling applied.
  ///
  /// See also:
  /// * [globalFocalPoint], which is the same value reported in the global coordinate space.
  /// * [viewportFocalPoint], which is the same value reported in the coordinate space of the viewport, **without**
  ///   panning and scaling applied.
  /// {@endtemplate}
  final Offset graphFocalPoint;

  /// {@template graph_viewport_scale_details.pointer_count}
  /// The number of pointers being tracked by the gesture recognizer.
  ///
  /// Typically this is the number of fingers being used to pan the widget using the gesture
  /// recognizer.
  /// {@endtemplate}
  final int pointerCount;
}

/// The scale update details used when a scale gesture inside a [GraphViewport] was updated.
class GraphViewportScaleUpdateDetails {
  /// Creates scale update details.
  const GraphViewportScaleUpdateDetails({
    required this.viewportFocalPointDelta,
    required this.graphFocalPointDelta,
    required this.globalFocalPoint,
    required this.viewportFocalPoint,
    required this.graphFocalPoint,
    required this.scale,
    required this.pointerCount,
  });

  /// The amount the gesture's focal point has moved in the coordinate space of the viewport since the previous update,
  /// **without** the currentviewport scale taken into account.
  ///
  /// See also:
  /// * [graphFocalPointDelta], which is the same value reported in the coordinate space of the viewport-content,
  ///   **with** the current viewport scale taken into account.
  final Offset viewportFocalPointDelta;

  /// The amount the gesture's focal point has moved in the coordinate space of the viewport-content since the previous
  /// update, **with** the viewport scale taken into account.
  ///
  /// See also:
  /// * [viewportFocalPointDelta], which is the same value reported in the coordinate space of the viewport,
  ///   **withouth** the viewport scale taken into account.
  final Offset graphFocalPointDelta;

  /// {@macro graph_viewport_scale_details.global_focal_point}
  final Offset globalFocalPoint;

  /// {@macro graph_viewport_scale_details.viewport_focal_point}
  final Offset viewportFocalPoint;

  /// {@macro graph_viewport_scale_details.graph_focal_point}
  final Offset graphFocalPoint;

  /// The scale implied by the average distance between the pointers in contact
  /// with the screen.
  final double scale;

  /// {@macro graph_viewport_scale_details.pointer_count}
  final int pointerCount;
}

/// The scale end details used when a scale gesture inside a [GraphViewport] ended.
class GraphViewportScaleEndDetails {
  /// Creates scale end details.
  const GraphViewportScaleEndDetails({
    required this.viewportVelocity,
    required this.graphVelocity,
    required this.scaleVelocity,
    required this.pointerCount,
  });

  /// The velocity of the last pointer to be lifted off of the screen.
  ///
  /// Reported in the coordinate space of the viewport, **without** the current viewport scale taken into account.
  ///
  /// See also:
  /// * [graphVelocity], which is the same value reported in the coordinate space of the viewport-content, **with**
  ///   the viewport scale taken into account.
  final Velocity viewportVelocity;

  /// The velocity of the last pointer to be lifted off of the screen.
  ///
  /// Reported in the coordinate space of the viewport-content, **with** the current viewport scale taken into account.
  ///
  /// See also:
  /// * [viewportVelocity], which is the same value reported in the coordinate space of the viewport, **without**
  ///   the viewport scale taken into account.
  final Velocity graphVelocity;

  /// The final velocity of the scale factor reported by the gesture.
  final double scaleVelocity;

  /// {@macro graph_viewport_scale_details.pointer_count}
  final int pointerCount;
}
