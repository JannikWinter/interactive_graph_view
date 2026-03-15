import "dart:ui" show Offset;

/// An abstract interface representing gesture details of a [GraphViewport] that include positional information.
abstract interface class GraphViewportPositionedGestureDetails {
  /// Creates details with positions.
  const GraphViewportPositionedGestureDetails({
    required this.globalPosition,
    required this.viewportPosition,
    required this.graphPosition,
  });

  /// {@template gesture_details.global_position}
  /// The global position at which the pointer contacted the screen.
  ///
  /// See also:
  /// * [viewportPosition], which is the [globalPosition] transformed to the coordinate space of the viewport
  ///   **without** panning and scaling applied.
  /// * [graphPosition], which is the [globalPosition] transformed to the coordinate space of the viewport-content,
  ///   **with** panning and scaling applied.
  /// {@endtemplate}
  final Offset globalPosition;

  /// {@template gesture_details.viewport_position}
  /// The position in the coordinate space of the viewport at which the pointer contacted the screen.
  ///
  /// This **does not** take panning and scaling of the viewport into account.
  ///
  /// See also:
  /// * [globalPosition], which is the global position at which the pointer contacted the screen.
  /// * [graphPosition], which is the [globalPosition] transformed to the coordinate space of the viewport-content,
  ///   **with** panning and scaling applied.
  /// {@endtemplate}
  final Offset viewportPosition;

  /// {@template gesture_details.graph_position}
  /// The position in the coordinate space of the viewport-content at which the pointer contacted the screen.
  ///
  /// This **does** take panning and scaling of the viewport into account.
  ///
  /// See also:
  /// * [globalPosition], which is the global position at which the pointer contacted the screen.
  /// * [viewportPosition], which is the [globalPosition] transformed to the coordinate space of the viewport
  ///   **without** panning and scaling applied.
  /// {@endtemplate}
  final Offset graphPosition;
}
