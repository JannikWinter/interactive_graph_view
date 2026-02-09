import "package:flutter/rendering.dart";

class GraphViewportNodeParentData extends ParentData {
  Offset position = Offset.zero;
  Offset dragOffset = Offset.zero;

  Offset get positionWithDragOffset => position + dragOffset;
}

class GraphViewportEdgeParentData extends ParentData {
  Offset startNodeCenter = Offset.zero;
  Radius startNodeBorderRadius = Radius.zero;
  Size startNodeSize = Size.zero;

  Offset endNodeCenter = Offset.zero;
  Radius endNodeBorderRadius = Radius.zero;
  Size endNodeSize = Size.zero;

  Offset get centerToCenter => endNodeCenter - startNodeCenter;
  Offset get centerToCenterBackwards => startNodeCenter - endNodeCenter;
}
