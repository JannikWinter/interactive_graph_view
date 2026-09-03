import "package:flutter/foundation.dart";

sealed class GraphViewportEdgeModel<NodeIdType> {
  const GraphViewportEdgeModel();

  NodeIdType get startNodeId;
  NodeIdType get endNodeId;
}

@immutable
abstract class StaticGraphViewportEdgeModel<NodeIdType> extends GraphViewportEdgeModel<NodeIdType> {
  const StaticGraphViewportEdgeModel();

  bool shouldRebuild(covariant StaticGraphViewportEdgeModel<NodeIdType> previous);
}

abstract class DynamicGraphViewportEdgeModel<NodeIdType> extends GraphViewportEdgeModel<NodeIdType> {
  VoidCallback? onNeedsRebuild;

  @protected
  void notifyNeedsRebuild() => onNeedsRebuild?.call();
}
