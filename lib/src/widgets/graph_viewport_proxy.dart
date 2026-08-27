import "package:flutter/widgets.dart";
import "package:material_ui/material_ui.dart" show Colors;

import "../rendering/graph_viewport_proxy.dart";
import "graph_viewport_child_widget.dart";

class GraphViewportProxy extends SingleChildRenderObjectWidget {
  /// Constructs a [GraphViewport].
  const GraphViewportProxy({
    super.key,
    required GraphViewportChildWidget super.child,
    this.backgroundColor = Colors.transparent,
  });

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
