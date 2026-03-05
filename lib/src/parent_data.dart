import "package:flutter/rendering.dart";

class GraphViewportNodeParentData extends ParentData {
  Offset dragOffset = Offset.zero;
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
