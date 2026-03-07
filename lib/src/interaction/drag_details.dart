import "dart:ui";

class NodeDragDownDetails {
  const NodeDragDownDetails({
    required this.parentSpacePosition,
    required this.graphSpacePosition,
  });

  final Offset parentSpacePosition;
  final Offset graphSpacePosition;
}

class NodeDragStartDetails {
  const NodeDragStartDetails({
    required this.parentSpacePosition,
    required this.graphSpacePosition,
  });

  final Offset parentSpacePosition;
  final Offset graphSpacePosition;
}

class NodeDragUpdateDetails {
  const NodeDragUpdateDetails({
    required this.parentSpacePosition,
    required this.graphSpacePosition,
    required this.parentSpaceDelta,
    required this.graphSpaceDelta,
  });

  final Offset parentSpacePosition;
  final Offset graphSpacePosition;
  final Offset parentSpaceDelta;
  final Offset graphSpaceDelta;

  bool get hasMoved => graphSpaceDelta != Offset.zero;
  bool get hasNotMoved => graphSpaceDelta == Offset.zero;
}

class NodeDragEndDetails {
  const NodeDragEndDetails();
}
