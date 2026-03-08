import "dart:ui";

/// The drag details used when a DragDown gesture was registered on a node.
class NodeDragDownDetails {
  const NodeDragDownDetails({
    required this.parentSpacePosition,
    required this.graphSpacePosition,
  });

  /// {@macro node_drag_details.parent_space_position}
  final Offset parentSpacePosition;

  /// {@macro node_drag_details.graph_space_position}
  final Offset graphSpacePosition;
}

/// The drag details used when a DragStart gesture was registered on a node.
class NodeDragStartDetails {
  const NodeDragStartDetails({
    required this.parentSpacePosition,
    required this.graphSpacePosition,
  });

  /// {@macro node_drag_details.parent_space_position}
  final Offset parentSpacePosition;

  /// {@macro node_drag_details.graph_space_position}
  final Offset graphSpacePosition;
}

/// The drag details used when a DragUpdate gesture was registered on a node.
class NodeDragUpdateDetails {
  const NodeDragUpdateDetails({
    required this.parentSpacePosition,
    required this.graphSpacePosition,
    required this.parentSpaceDelta,
    required this.graphSpaceDelta,
  });

  /// {@template node_drag_details.parent_space_position}
  /// The position in parent space where this drag happened.
  /// {@endtemplate}
  ///
  /// {@template node_drag_details.parent_space}
  /// "Parent space" means that the Offset is in relation to the parent widget of the [GraphViewport].
  /// {@endtemplate}
  final Offset parentSpacePosition;

  /// {@template node_drag_details.graph_space_position}
  /// The position in graph space where this drag happened.
  /// {@endtemplate}
  ///
  /// {@template node_drag_details.graph_space}
  /// "Graph space" means that the Offset is in relation to the [GraphViewport]'s internal space with panning and
  /// scaling applied.
  /// {@endtemplate}
  final Offset graphSpacePosition;

  /// The distance for this specific DragUpdate gesture that the input was moved - in parent space.
  ///
  /// {@macro node_drag_details.parent_space}
  final Offset parentSpaceDelta;

  /// The distance for this specific DragUpdate gesture that the input was moved - in parent space.
  ///
  /// {@macro node_drag_details.graph_space}
  final Offset graphSpaceDelta;

  bool get hasMoved => graphSpaceDelta != Offset.zero;
  bool get hasNotMoved => graphSpaceDelta == Offset.zero;
}

/// The drag details used when a DraggEnd gesture was registered on a node.
class NodeDragEndDetails {
  const NodeDragEndDetails();
}
