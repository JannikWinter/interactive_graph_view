import "dart:ui";

import "package:flutter/foundation.dart";

@immutable
class NodeData<NodeIdType> {
  final NodeIdType nodeId;
  final Offset position;

  const NodeData({
    required this.nodeId,
    required this.position,
  });

  @override
  bool operator ==(covariant NodeData<NodeIdType> other) {
    return other.nodeId == nodeId && other.position == position;
  }

  @override
  int get hashCode => Object.hash(nodeId, position);
}
