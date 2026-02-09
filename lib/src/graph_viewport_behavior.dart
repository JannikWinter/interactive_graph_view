enum GraphViewportMoveBehavior {
  screenEdge,
  screenCenter;
}

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
