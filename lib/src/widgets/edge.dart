import "package:flutter/material.dart" show Theme;
import "package:flutter/widgets.dart";

import "../elements/edge.dart";
import "../rendering/edge.dart";
import "../style/edge_style.dart";

/// A widget for configuring, interacting with and styling an edge in a graph.
///
/// To display this edge, it should be constructed as a child of a [GraphViewport] through [GraphViewport.edgeBuilder].
///
/// To build an edge, its ID should first be added to a [GraphViewport]'s [GraphViewport.viewportController].
class EdgeWidget<NodeIdType> extends LeafRenderObjectWidget {
  /// Constructs an [EdgeWidget].
  const EdgeWidget({
    super.key,
    required this.startNodeId,
    required this.endNodeId,
    required this.text,
    this.style,
    this.onTap,
  });

  /// The ID of the node where this edge originates from.
  ///
  /// This ID must be known by the [GraphViewport]'s [GraphViewport.viewportController].
  final NodeIdType startNodeId;

  /// The ID of the node where this edge ends at.
  ///
  /// This ID must be known by the [GraphViewport]'s [GraphViewport.viewportController].
  final NodeIdType endNodeId;

  /// The text that is shown at the center of this edge.
  ///
  /// Supply `null` if no text should be displayed.
  ///
  /// The text can be styled with [EdgeStyle.textStyle].
  final String? text;

  /// The style this edge uses.
  ///
  /// If no style is supplied, it looks for any style up the widget tree that was supplied through a [Theme].
  /// If no style is found, [EdgeStyle.fallback] is used to construct a default fallback style.
  final EdgeStyle? style;

  /// This callback will be called when a Tap gesture was registered on this edge.
  ///
  /// Note that you can configure the gesture hitbox for all edges of a viewport through
  /// [GraphViewport.edgeHitboxThickness].
  final VoidCallback? onTap;

  @override
  GraphEdgeRenderObject createRenderObject(BuildContext context) {
    final EdgeStyle effectiveStyle = style ?? Theme.of(context).extension<EdgeStyle>() ?? EdgeStyle.fallback();

    return GraphEdgeRenderObject(
      startNodeId: startNodeId,
      endNodeId: endNodeId,
      text: text,
      style: effectiveStyle,
    );
  }

  @override
  EdgeElement createElement() {
    return EdgeElement(this);
  }

  @override
  void updateRenderObject(BuildContext context, GraphEdgeRenderObject renderObject) {
    final EdgeStyle effectiveStyle = style ?? Theme.of(context).extension<EdgeStyle>() ?? EdgeStyle.fallback();

    renderObject
      ..startNodeId = startNodeId
      ..endNodeId = endNodeId
      ..text = text
      ..style = effectiveStyle;
  }
}
