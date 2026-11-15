import "package:flutter/widgets.dart";
import "package:material_ui/material_ui.dart" show Colors;

import "../rendering/graph_viewport_proxy.dart";
import "graph_viewport_child_widget.dart";

/// A widget for displaying a [GraphViewportChildWidget] (e.g. a [NodeWidget] or an [EdgeWidget]) outside of a
/// [GraphViewport] directly inside your apps render tree.
class GraphViewportProxy extends SingleChildRenderObjectWidget {
  /// Constructs a [GraphViewportProxy] with a given [child] and [backgroundColor].
  const GraphViewportProxy({
    super.key,
    required GraphViewportChildWidget super.child,
    this.backgroundColor = Colors.transparent,
  });

  /// The color of the background.
  final Color backgroundColor;

  @override
  RenderGraphViewportProxy createRenderObject(BuildContext context) {
    return RenderGraphViewportProxy(
      backgroundColor: backgroundColor,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderGraphViewportProxy renderObject,
  ) {
    renderObject.backgroundColor = backgroundColor;
  }
}
