import "dart:ui";

import "package:flutter/foundation.dart";

import "./graph_viewport_controller.dart";
import "./widgets/graph_viewport.dart";

/// The base model class for all nodes managed by a [GraphViewportController] in a [GraphViewport].
sealed class GraphViewportNodeModel {
  const GraphViewportNodeModel();

  /// The position of this edge inside the viewport.
  Offset get position;
}

/// The static variant of the base model class for all nodes managed by a [GraphViewportController] in a
/// [GraphViewport].
///
/// When using this class as the base class for your nodes, a rebuild of the [GraphViewport] is only triggered when
/// supplying a new instance through [GraphViewportController.setNode] or [GraphViewportController.setNodes] **and**
/// the new instance's [shouldRebuild] methods returns `true` when being passed the previous instance.
///
/// That means, that every field of your subclass that should trigger a rebuilt should be included in [shouldRebuild].
///
/// Your subclass should be immutable. If you want to dynamically rebuild your nodes and have a mutable subclass, use
/// [DynamicGraphViewportNodeModel].
@immutable
abstract class StaticGraphViewportNodeModel extends GraphViewportNodeModel {
  const StaticGraphViewportNodeModel();

  /// Whether compared to the [previous] instance of this node, the displayed node in the [GraphViewport]
  /// should be rebuilt.
  bool shouldRebuild(covariant StaticGraphViewportNodeModel previous);
}

/// The dynamic variant of the base model class for all nodes managed by a [GraphViewportController] in a
/// [GraphViewport].
///
/// When using this class as the base class for your nodes and you have registered an instance through
/// [GraphViewportController.setNode] or [GraphViewportController.setNodes], calling [notifyNeedsRebuild] will
/// automatically trigger a rebuild of the [GraphViewport].
///
/// If you want to use an immutable subclass, use [StaticGraphViewportNodeModel].
abstract class DynamicGraphViewportNodeModel extends GraphViewportNodeModel {
  /// The **internal** callback [GraphViewportController] uses for being notified about a rebuild request.
  ///
  /// Do not set this yourself.
  VoidCallback? onNeedsRebuild;

  /// Trigger a rebuild of this node in the [GraphViewport].
  @protected
  void notifyNeedsRebuild() => onNeedsRebuild?.call();
}
