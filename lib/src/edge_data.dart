import "package:flutter/foundation.dart";

@immutable
class EdgeData<NodeIdType, EdgeIdType> {
  final EdgeIdType edgeId;
  final NodeIdType startNodeId;
  final NodeIdType endNodeId;

  const EdgeData({required this.edgeId, required this.startNodeId, required this.endNodeId});

  @override
  bool operator ==(covariant EdgeData<NodeIdType, EdgeIdType> other) {
    return other.edgeId == edgeId && other.startNodeId == startNodeId && other.endNodeId == endNodeId;
  }

  @override
  int get hashCode => Object.hash(edgeId, startNodeId, endNodeId);
}
