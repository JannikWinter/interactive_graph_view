import "dart:ui";

import "gesture_details.dart";

/// The drag details used when a DragDown gesture was registered inside a [GraphViewport].
class GraphViewportDragDownDetails implements GraphViewportPositionedGestureDetails {
  /// Creates tap down details.
  const GraphViewportDragDownDetails({
    required this.globalPosition,
    required this.viewportPosition,
    required this.graphPosition,
  });

  /// {@macro gesture_details.global_position}
  @override
  final Offset globalPosition;

  /// {@macro gesture_details.viewport_position}
  @override
  final Offset viewportPosition;

  /// {@macro gesture_details.graph_position}
  @override
  final Offset graphPosition;
}

/// The drag details used when a DragStart gesture was registered inside a [GraphViewport].
class GraphViewportDragStartDetails implements GraphViewportPositionedGestureDetails {
  /// Creates drag start details.
  const GraphViewportDragStartDetails({
    required this.globalPosition,
    required this.viewportPosition,
    required this.graphPosition,
  });

  /// {@macro gesture_details.global_position}
  @override
  final Offset globalPosition;

  /// {@macro gesture_details.viewport_position}
  @override
  final Offset viewportPosition;

  /// {@macro gesture_details.graph_position}
  @override
  final Offset graphPosition;
}

/// The drag details used when a DragUpdate gesture was registered inside a [GraphViewport].
class GraphViewportDragUpdateDetails implements GraphViewportPositionedGestureDetails {
  /// Creates drag update details.
  const GraphViewportDragUpdateDetails({
    required this.globalPosition,
    required this.viewportPosition,
    required this.graphPosition,
    required this.viewportDelta,
    required this.graphDelta,
  });

  /// {@macro gesture_details.global_position}
  @override
  final Offset globalPosition;

  /// {@macro gesture_details.viewport_position}
  @override
  final Offset viewportPosition;

  /// {@macro gesture_details.graph_position}
  @override
  final Offset graphPosition;

  /// The amount the pointer has moved in the coordinate space of the viewport since the previous update.
  ///
  /// This **does not** take the viewport scaling into account.
  ///
  /// See also:
  /// * [graphDelta] which is the [viewportDelta] transformed to the coordinate space of the viewport-content, **with**
  ///   scaling applied.
  final Offset viewportDelta;

  /// The amount the pointer has moved in the coordinate space of the viewport-content since the previous update.
  ///
  /// This **does** take the viewport scaling into account.
  ///
  /// See also:
  /// * [viewportDelta] which is the delta in the coordinate space of the viewport, **without** scaling applied.
  final Offset graphDelta;
}

/// The drag details used when a DragEnd gesture was registered inside a [GraphViewport].
class GraphViewportDragEndDetails {
  /// Creates drag end details.
  const GraphViewportDragEndDetails();
}
