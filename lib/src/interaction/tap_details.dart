import "dart:ui" show Offset;

import "gesture_details.dart";

/// The tap details used when a tap occured inside a [GraphViewport].
class GraphViewportTapDownDetails implements GraphViewportPositionedGestureDetails {
  /// Creates tap down details.
  const GraphViewportTapDownDetails({
    required this.globalPosition,
    required this.viewportPosition,
    required this.graphPosition,
  });

  /// {@macro gesture_details.global_position}
  @override
  final Offset globalPosition;

  /// {@macro gesture_details.local_position}
  @override
  final Offset viewportPosition;

  /// {@macro gesture_details.graph_position}
  @override
  final Offset graphPosition;
}
