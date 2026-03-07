import "package:flutter/painting.dart";

import "graph_visibility.dart";

enum GraphViewportMoveBehavior { screenEdge, screenCenter }

sealed class GraphViewportZoomBehavior {
  const GraphViewportZoomBehavior();
}

final class GraphViewportZoomToFitBehavior extends GraphViewportZoomBehavior {
  const GraphViewportZoomToFitBehavior();
}

final class GraphViewportZoomToScaleBehavior extends GraphViewportZoomBehavior {
  const GraphViewportZoomToScaleBehavior({required this.scale});

  final double scale;
}

typedef GraphViewportBehaviorResolver =
    (GraphViewportMoveBehavior?, GraphViewportZoomBehavior?) Function(
      GraphVisibility visibility,
      double scale,
      Size paddedSize,
      Size viewportSize,
      Size targetSize,
    );
