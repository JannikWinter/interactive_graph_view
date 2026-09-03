import "dart:ui";

import "package:flutter/foundation.dart";

sealed class GraphViewportNodeModel {
  Offset get position;
}

@immutable
abstract class StaticGraphViewportNodeModel extends GraphViewportNodeModel {
  bool shouldRebuild(covariant StaticGraphViewportNodeModel previous);
}

abstract class DynamicGraphViewportNodeModel extends GraphViewportNodeModel {
  VoidCallback? onNeedsRebuild;

  @protected
  void notifyNeedsRebuild() => onNeedsRebuild?.call();
}
