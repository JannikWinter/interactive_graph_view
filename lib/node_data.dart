import "dart:ui" show Offset;

abstract interface class NodeData<NodeIdType> {
  NodeIdType get id;
  Offset get position;
}
