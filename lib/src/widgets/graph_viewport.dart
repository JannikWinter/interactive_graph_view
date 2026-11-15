import "package:flutter/gestures.dart";
import "package:flutter/widgets.dart";
import "package:material_ui/material_ui.dart" show Theme;

import "../elements/graph_viewport.dart";
import "../graph_viewport_controller.dart";
import "../graph_viewport_edge_model.dart";
import "../graph_viewport_node_model.dart";
import "../graph_viewport_transform.dart";
import "../interaction/gesture_callbacks.dart";
import "../rendering/graph_viewport.dart";
import "../style/graph_style.dart";
import "edge.dart";
import "node.dart";

/// The widget builder function for nodes.
///
/// Returns a [NodeWidget] for a supplied [nodeId] and node data ([node]).
typedef NodeBuilder<NodeIdType, NodeModelType extends GraphViewportNodeModel> =
    NodeWidget Function(BuildContext context, NodeIdType nodeId, NodeModelType node);

/// The widget builder function for edges.
///
/// Returns an [EdgeWidget] for a supplied [edgeId] and edge data ([edge]).
typedef EdgeBuilder<EdgeIdType, EdgeModelType extends GraphViewportEdgeModel> =
    EdgeWidget Function(BuildContext context, EdgeIdType edgeId, EdgeModelType edge);

/// The callback for when nodes were dragged and that drag ended.
typedef NodesMovedCallback<NodeIdType> = void Function(Set<NodeIdType> nodeIds, Offset offset);

/// A widget for interacting with and styling a graph.
///
/// The graph's nodes and edges are added and removed through the [controller]
/// and built and styled as [NodeWidget]s and [EdgeWidget]s in the [nodeBuilder] and [edgeBuilder] respectively.
///
/// Nodes and edges are only identified by their IDs. The respective ID type is supplied through
/// the generic types [NodeIdType] and [EdgeIdType]. The respective data type is supplied through the generic types
/// [NodeModelType] and [EdgeModelType], which have to be a subclass of
/// [GraphViewportNodeModel] and [GraphViewportEdgeModel] respectively.
class GraphViewport<
  NodeIdType,
  EdgeIdType,
  NodeModelType extends GraphViewportNodeModel,
  EdgeModelType extends GraphViewportEdgeModel<NodeIdType>
>
    extends RenderObjectWidget {
  /// The default value for [cacheExtent] when it is not supplied to the constructor.
  static const double kDefaultCacheExtent = 50.0;

  /// The default value for [boundaryInsets] when it is not supplied to the constructor.
  static const EdgeInsets kDefaultBoundaryInsets = EdgeInsets.zero;

  /// Constructs a [GraphViewport].
  const GraphViewport({
    super.key,
    required this.controller,
    required this.nodeBuilder,
    required this.edgeBuilder,
    required this.transform,
    this.style,
    this.cacheExtent = kDefaultCacheExtent,
    this.boundaryInsets = kDefaultBoundaryInsets,
    this.debugPaintQuadTree = false,
    this.movingNodeIds = const {},
    this.onNodesMoved,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd,
    this.onTapDown,
    this.onTap,
    this.onDoubleTap,
    this.onPointerSignal,
  }) : assert(cacheExtent >= 0.0);

  /// The viewport controller through which the graph's elements are controlled programmatically.
  final GraphViewportController<NodeIdType, EdgeIdType, NodeModelType, EdgeModelType> controller;

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
  final NodeBuilder<NodeIdType, NodeModelType> nodeBuilder;

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
  final EdgeBuilder<EdgeIdType, EdgeModelType> edgeBuilder;

  /// The viewport transform through which the viewport's visible area is controlled programmatically.
  final GraphViewportTransform transform;

  /// This viewport's own style.
  ///
  /// To apply the style for this widget, we will search for a non-null value for each [GraphStyle]-property. The
  /// applied `GraphStyle`s are searched in the following order:
  /// 1. this [style].
  /// 2. the graph style of the closest [Theme] widget up the tree (see [ThemeData.extensions]).
  /// 3. [GraphStyle.fallback] which will have a fallback value for every property.
  final GraphStyle? style;

  /// The extent in each direction outside the visible viewport area, in which graph elements are to be displayed.
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

  /// Whether the quad tree, that is used to effectively store the children of the viewport, should be painted.
  ///
  /// Defaults to `false`.
  final bool debugPaintQuadTree;

  final Set<NodeIdType> movingNodeIds;

  final NodesMovedCallback<NodeIdType>? onNodesMoved;

  /// This callback will be called when a TapDown gesture was registered on the viewport,
  /// which was not registered on any child.
  final GestureGraphViewportTapDownCallback? onTapDown;

  /// This callback will be called when a Tap gesture was registered on the viewport,
  /// which was not registered on any child.
  final GestureGraphViewportTapCallback? onTap;

  /// This callback will be called when a DoubleTap gesture was registered on the viewport,
  /// which was not registered on any child.
  final GestureGraphViewportDoubleTapCallback? onDoubleTap;

  /// This callback will be called when a ScaleStart gesture was registered on the viewport,
  /// which was not registered on any child.
  final GestureGraphViewportScaleStartCallback? onScaleStart;

  /// This callback will be called when a ScaleUpdate gesture was registered on the viewport,
  /// which was not registered on any child.
  final GestureGraphViewportScaleUpdateCallback? onScaleUpdate;

  /// This callback will be called when a ScaleEnd gesture was registered on the viewport,
  /// which was not registered on any child.
  final GestureGraphViewportScaleEndCallback? onScaleEnd;

  /// This callback will be called when a pointer signal event, e.g. a scroll event, was registered on the viewport.
  final void Function(PointerSignalEvent event)? onPointerSignal;

  @override
  RenderObjectElement createElement() {
    return GraphViewportElement<NodeIdType, EdgeIdType, NodeModelType, EdgeModelType>(this);
  }

  @override
  RenderGraphViewport<NodeIdType, EdgeIdType, NodeModelType, EdgeModelType> createRenderObject(BuildContext context) {
    final GraphStyle effectiveStyle = GraphStyle.getEffectiveStyle(context, style: style);

    return RenderGraphViewport(
      controller: controller,
      transform: transform,
      layoutHelper: context as GraphViewportElement<NodeIdType, EdgeIdType, NodeModelType, EdgeModelType>,
      cacheExtent: cacheExtent,
      boundaryInsets: boundaryInsets,
      debugPaintQuadTree: debugPaintQuadTree,
      backgroundColor: effectiveStyle.backgroundColor!,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderGraphViewport<NodeIdType, EdgeIdType, NodeModelType, EdgeModelType> renderObject,
  ) {
    final GraphStyle effectiveStyle = GraphStyle.getEffectiveStyle(context, style: style);

    renderObject
      ..controller = controller
      ..transform = transform
      ..cacheExtent = cacheExtent
      ..boundaryInsets = boundaryInsets
      ..debugPaintQuadTree = debugPaintQuadTree
      ..backgroundColor = effectiveStyle.backgroundColor!;
  }
}
