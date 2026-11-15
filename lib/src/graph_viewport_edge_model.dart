import "package:flutter/foundation.dart";

import "./graph_viewport_controller.dart";
import "./widgets/graph_viewport.dart";

/// The base model class for all edges managed by a [GraphViewportController] in a [GraphViewport].
sealed class GraphViewportEdgeModel<NodeIdType> {
  const GraphViewportEdgeModel();

  /// The ID of the node that this edge begins at.
  NodeIdType get startNodeId;

  /// The ID of the node that this edge ends at.
  NodeIdType get endNodeId;
}

/// The static variant of the base model class for all edges managed by a [GraphViewportController] in a
/// [GraphViewport].
///
/// When using this class as the base class for your edges, a rebuild of the [GraphViewport] is only triggered when
/// supplying a new instance through [GraphViewportController.setEdge] or [GraphViewportController.setEdges] **and**
/// the new instance's [shouldRebuild] methods returns `true` when being passed the previous instance.
///
/// That means, that every field of your subclass that should trigger a rebuilt should be included in [shouldRebuild].
///
/// Your subclass should be immutable. If you want to dynamically rebuild your edges and have a mutable subclass, use
/// [DynamicGraphViewportEdgeModel].
@immutable
abstract class StaticGraphViewportEdgeModel<NodeIdType> extends GraphViewportEdgeModel<NodeIdType> {
  const StaticGraphViewportEdgeModel();

  /// Whether compared to the [previous] instance of this edge, the displayed edge in the [GraphViewport]
  /// should be rebuilt.
  bool shouldRebuild(covariant StaticGraphViewportEdgeModel<NodeIdType> previous);
}

/// The dynamic variant of the base model class for all edges managed by a [GraphViewportController] in a
/// [GraphViewport].
///
/// When using this class as the base class for your edges and you have registered an instance through
/// [GraphViewportController.setEdge] or [GraphViewportController.setEdges], calling [notifyNeedsRebuild] will
/// automatically trigger a rebuild of the [GraphViewport].
///
/// If you want to use an immutable subclass, use [StaticGraphViewportEdgeModel].
abstract class DynamicGraphViewportEdgeModel<NodeIdType> extends GraphViewportEdgeModel<NodeIdType> {
  /// The **internal** callback [GraphViewportController] uses for being notified about a rebuild request.
  ///
  /// Do not set this yourself.
  VoidCallback? onNeedsRebuild;

  /// Trigger a rebuild of this edge in the [GraphViewport].
  @protected
  void notifyNeedsRebuild() => onNeedsRebuild?.call();
}
