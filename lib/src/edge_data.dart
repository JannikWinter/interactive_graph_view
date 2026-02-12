abstract interface class EdgeData<EdgeIdType, NodeIdType> {
  EdgeIdType get id;
  NodeIdType get startNodeId;
  NodeIdType get endNodeId;
}
