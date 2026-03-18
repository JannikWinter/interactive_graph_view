import "package:flutter/gestures.dart";
import "package:flutter/material.dart" show Theme;
import "package:flutter/widgets.dart";

import "../elements/graph_viewport.dart";
import "../graph_viewport_controller.dart";
import "../graph_viewport_transform.dart";
import "../interaction/gesture_callbacks.dart";
import "../rendering/graph_viewport.dart";
import "../style/graph_style.dart";
import "edge.dart";
import "node.dart";

/// The widget builder function for nodes.
///
/// Returns a [NodeWidget] for a supplied node ID.
typedef NodeBuilder<NodeIdType> = NodeWidget Function(BuildContext context, NodeIdType nodeId);

/// The widget builder function for edges.
///
/// Returns an [EdgeWidget] for a supplied edge ID.
typedef EdgeBuilder<EdgeIdType> = EdgeWidget Function(BuildContext context, EdgeIdType edgeId);

/// A widget for interacting with and styling a graph.
///
/// Compared to [GraphView] (which uses this widget internally), this widget gives you more flexibility, as
/// panning and scaling is not handled for you.
/// If you do not need to do that flexibility, [GraphView] is probably the widget you want to use instead.
///
/// The graph's nodes and edges are added and removed through the [viewportController]
/// and built and styled as [NodeWidget]s and [EdgeWidget]s in the [nodeBuilder] and [edgeBuilder] respectively.
///
/// Nodes and edges are only identified by their IDs. The respective ID type is supplied through
/// the generic types [NodeIdType] and [EdgeIdType].
class GraphViewport<NodeIdType, EdgeIdType> extends RenderObjectWidget {
  /// The default value for [cacheExtent] when it is not supplied to the constructor.
  static const double kDefaultCacheExtent = 50.0;

  /// The default value for [boundaryInsets] when it is not supplied to the constructor.
  static const EdgeInsets kDefaultBoundaryInsets = EdgeInsets.zero;

  /// The default value for [edgeHitboxThickness] when it is not supplied to the constructor.
  static const double kDefaultEdgeHitboxThickness = 40.0;
  static const bool kDefaultRebuildAllChildrenOnWidgetUpdate = true;

  /// Constructs a [GraphViewport].
  const GraphViewport({
    super.key,
    required this.viewportController,
    required this.nodeBuilder,
    required this.edgeBuilder,
    required this.transform,
    this.style,
    this.cacheExtent = kDefaultCacheExtent,
    this.boundaryInsets = kDefaultBoundaryInsets,
    this.edgeHitboxThickness = kDefaultEdgeHitboxThickness,
    this.rebuildAllChildrenOnWidgetUpdate = kDefaultRebuildAllChildrenOnWidgetUpdate,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd,
    this.onTapDown,
    this.onTap,
    this.onDoubleTap,
    this.onPointerSignal,
  }) : assert(cacheExtent >= 0.0),
       assert(edgeHitboxThickness >= 1.0);

  /// {@template graph_viewport.viewport_controller}
  /// The viewport controller through which the graph's elements are controlled programmatically.
  /// {@endtemplate}
  final GraphViewportController<NodeIdType, EdgeIdType> viewportController;

  /// {@template graph_viewport.node_builder}
  /// The widget builder function for nodes.
  ///
  /// Returns a [NodeWidget] for any supplied node ID.
  ///
  /// This will be called only when necessary, e.g. when a node becomes visible.
  /// The supplied edge ID always stems from the node IDs known to [GraphViewportController].
  ///
  /// Upon first construction of this widget, this builder will be called once for each node that was supplied to
  /// the [GraphViewportController] to construct a quad tree that is then used to only build the
  /// visible edges lazily.
  /// If [rebuildAllChildrenOnWidgetUpdate] is set to `true`, all nodes are also rebuild when the widget configuration
  /// changes.
  /// {@endtemplate}
  final NodeBuilder<NodeIdType> nodeBuilder;

  /// {@template graph_viewport.edge_builder}
  /// The widget builder function for edges.
  ///
  /// Returns an [EdgeWidget] for any supplied edge ID.
  ///
  /// This will be called only when necessary, e.g. when an edge becomes visible.
  /// The supplied edge ID always stems from the edge IDs known to [GraphViewportController].
  ///
  /// Upon first construction of this widget, this builder will be called once for each edge that was supplied to
  /// the [GraphViewportController] to construct a quad tree that is then used to only build the
  /// visible edges lazily.
  /// If [rebuildAllChildrenOnWidgetUpdate] is set to `true`, all edges are also rebuild when the widget configuration
  /// changes.
  /// {@endtemplate}
  final EdgeBuilder<EdgeIdType> edgeBuilder;

  /// The viewport transform through which the viewport's visible area is controlled programmatically.
  final GraphViewportTransform transform;

  /// {@template graph_viewport.style}
  /// This viewport's own style.
  ///
  /// To apply the style for this widget, we will search for a non-null value for each [GraphStyle]-property. The
  /// applied `GraphStyle`s are searched in the following order:
  /// 1. this [style].
  /// 2. the graph style of the closest [Theme] widget up the tree (see [ThemeData.extensions]).
  /// 3. [GraphStyle.fallback] which will have a fallback value for every property.
  /// {@endtemplate}
  final GraphStyle? style;

  /// {@template graph_viewport.cache_extent}
  /// The extent in each direction outside the visible viewport area, in which graph elements are to be displayed.
  /// {@endtemplate}
  ///
  /// Defaults to [kDefaultCacheExtent].
  final double cacheExtent;

  /// {@template graph_viewport.boundary_insets}
  /// The minimum inset on each side of the [GraphViewport] that must remain covered by the content rect.
  ///
  /// Each inset value specifies the minimum number of pixels of the content that must remain visible on that
  /// side when the outermost child is scrolled to the edge. At [EdgeInsets.zero], the content may scroll until it is
  /// entirely off-screen but still flush with the viewport boundary. Greater values pull the content back toward
  /// the center.
  /// {@endtemplate}
  ///
  /// Defaults to [kDefaultBoundaryInsets]
  final EdgeInsets boundaryInsets;

  /// {@template graph_viewport.edge_hitbox_thickness}
  /// The thickness of the gesture hitbox for all edges displayed by this GraphView.
  /// {@endtemplate}
  ///
  /// Defaults to [kDefaultEdgeHitboxThickness].
  final double edgeHitboxThickness;

  /// {@template graph_viewport.rebuild_all_children_on_widget_update}
  /// Whether all children should be rebuilt when this widget's configuration changes (see [Element.update]).
  ///
  /// This should be set to `true` when you wish to see the changes, e.g. in your [nodeBuilder] and [edgeBuilder],
  /// on hot reload.
  ///
  /// Otherwise, for performance reasons, this should probably be set to false and rebuilds of nodes and edges
  /// should be initiated through [GraphViewportController.rebuildNode] and [GraphViewportController.rebuildEdge]
  /// respectively.
  /// {@endtemplate}
  ///
  /// Defaults to [kDefaultRebuildAllChildrenOnWidgetUpdate].
  final bool rebuildAllChildrenOnWidgetUpdate;

  /// {@template graph_viewport.on_tap_down}
  /// This callback will be called when a TapDown gesture was registered on the viewport,
  /// which was not registered on any child.
  /// {@endtemplate}
  final GestureGraphViewportTapDownCallback? onTapDown;

  /// {@template graph_viewport.on_tap}
  /// This callback will be called when a Tap gesture was registered on the viewport,
  /// which was not registered on any child.
  /// {@endtemplate}
  final GestureGraphViewportTapCallback? onTap;

  /// {@template graph_viewport.on_double_tap}
  /// This callback will be called when a DoubleTap gesture was registered on the viewport,
  /// which was not registered on any child.
  /// {@endtemplate}
  final GestureGraphViewportDoubleTapCallback? onDoubleTap;

  /// {@template graph_viewport.on_scale_start}
  /// This callback will be called when a ScaleStart gesture was registered on the viewport,
  /// which was not registered on any child.
  /// {@endtemplate}
  final GestureGraphViewportScaleStartCallback? onScaleStart;

  /// {@template graph_viewport.on_scale_update}
  /// This callback will be called when a ScaleUpdate gesture was registered on the viewport,
  /// which was not registered on any child.
  /// {@endtemplate}
  final GestureGraphViewportScaleUpdateCallback? onScaleUpdate;

  /// {@template graph_viewport.on_scale_end}
  /// This callback will be called when a ScaleEnd gesture was registered on the viewport,
  /// which was not registered on any child.
  /// {@endtemplate}
  final GestureGraphViewportScaleEndCallback? onScaleEnd;

  /// {@template graph_viewport.on_pointer_signal}
  /// This callback will be called when a pointer signal event, e.g. a scroll event, was registered on the viewport.
  /// {@endtemplate}
  final void Function(PointerSignalEvent event)? onPointerSignal;

  @override
  RenderObjectElement createElement() {
    return GraphViewportElement<NodeIdType, EdgeIdType>(this);
  }

  @override
  RenderGraphViewport<NodeIdType, EdgeIdType> createRenderObject(BuildContext context) {
    final GraphStyle? themeStyle = Theme.of(context).extension<GraphStyle>();
    final GraphStyle fallbackStyle = GraphStyle.fallback();
    final GraphStyle effectiveStyle = fallbackStyle.merge(themeStyle).merge(style);

    return RenderGraphViewport<NodeIdType, EdgeIdType>(
      viewportController: viewportController,
      transform: transform,
      layoutHelper: context as GraphViewportElement<NodeIdType, EdgeIdType>,
      cacheExtent: cacheExtent,
      boundaryInsets: boundaryInsets,
      edgeHitboxThickness: edgeHitboxThickness,
      backgroundColor: effectiveStyle.backgroundColor!,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderGraphViewport<NodeIdType, EdgeIdType> renderObject,
  ) {
    final GraphStyle? themeStyle = Theme.of(context).extension<GraphStyle>();
    final GraphStyle fallbackStyle = GraphStyle.fallback();
    final GraphStyle effectiveStyle = fallbackStyle.merge(themeStyle).merge(style);

    renderObject
      ..viewportController = viewportController
      ..transform = transform
      ..cacheExtent = cacheExtent
      ..boundaryInsets = boundaryInsets
      ..edgeHitboxThickness = edgeHitboxThickness
      ..backgroundColor = effectiveStyle.backgroundColor!;
  }
}
