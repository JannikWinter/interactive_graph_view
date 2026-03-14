import "dart:ui" show Offset;

/// The tap details used when a tap occured on a [GraphViewport].
class GraphViewportTapDownDetails {
  /// Constructs new tap down details.
  const GraphViewportTapDownDetails({
    required this.globalPosition,
    required this.localPosition,
    required this.graphPosition,
  });

  /// The global position at which the pointer contacted the screen.
  ///
  /// See also:
  /// * [localPosition], which is the [globalPosition] transformed to the coordinate space of the viewport **without**
  ///   panning and scaling applied.
  /// * [graphPosition], which is the [globalPosition] transformed to the coordinate space of the viewport-content,
  ///   **with** panning and scaling applied.
  final Offset globalPosition;

  /// The position in the coordinate space of the viewport at which the pointer contacted the screen.
  ///
  /// This **does not** take panning and scaling of the viewport into account.
  ///
  /// See also:
  /// * [globalPosition], which is the global position at which the pointer contacted the screen.
  /// * [graphPosition], which is the [globalPosition] transformed to the coordinate space of the viewport-content,
  ///   **with** panning and scaling applied.
  final Offset localPosition;

  /// The position in the coordinate space of the viewport-content at which the pointer contacted the screen.
  ///
  /// This **does** take panning and scaling of the viewport into account.
  ///
  /// See also:
  /// * [globalPosition], which is the global position at which the pointer contacted the screen.
  /// * [localPosition], which is the [globalPosition] transformed to the coordinate space of the viewport **without**
  ///   panning and scaling applied.
  final Offset graphPosition;
}
