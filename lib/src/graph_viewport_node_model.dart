import "dart:ui";

import "package:flutter/foundation.dart";

sealed class GraphViewportNodeModel {
  const GraphViewportNodeModel();

  Offset get position;
}

@immutable
abstract class StaticGraphViewportNodeModel extends GraphViewportNodeModel {
  const StaticGraphViewportNodeModel();

  bool shouldRebuild(covariant StaticGraphViewportNodeModel previous);
}

abstract class DynamicGraphViewportNodeModel extends GraphViewportNodeModel {
  VoidCallback? onNeedsRebuild;

  @protected
  void notifyNeedsRebuild() => onNeedsRebuild?.call();
}
