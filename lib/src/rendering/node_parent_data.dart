import "package:flutter/rendering.dart";

class GraphViewportNodeParentData extends ParentData {
  Offset position = Offset.zero;
  Offset dragOffset = Offset.zero;

  Offset get positionWithDragOffset => position + dragOffset;
}
