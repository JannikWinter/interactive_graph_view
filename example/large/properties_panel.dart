import "package:flutter/material.dart";

import "package:interactive_graph_view/interactive_graph_view.dart";

import "../large.dart";
import "edge_properties_panel.dart";
import "node_properties_panel.dart";

class PropertiesPanel extends StatelessWidget {
  const PropertiesPanel({
    super.key,
    required this.selectedNodes,
    required this.selectedEdges,
    required this.onDeleteNode,
    required this.onDeleteEdge,
    required this.onNodeTextChanged,
    required this.onNodeBackgroundColorChanged,
    required this.onNodeTextColorChanged,
    required this.onNodeBorderRadiusChanged,
    required this.onEdgeShowTextChanged,
    required this.onEdgeTextChanged,
    required this.onEdgeTextBackgroundColorChanged,
    required this.onEdgeTextColorChanged,
    required this.onEdgeLineColorChanged,
    required this.onEdgeLineStyleChanged,
    required this.onEdgeOverrideArrowStyleChanged,
    required this.onEdgeArrowChanged,
  });

  final Set<ExampleNode> selectedNodes;
  final Set<ExampleEdge> selectedEdges;

  final void Function(String nodeId) onDeleteNode;
  final void Function(String edgeId) onDeleteEdge;

  final void Function(String nodeId, String text) onNodeTextChanged;
  final void Function(String nodeId, Color? backgroundColor) onNodeBackgroundColorChanged;
  final void Function(String nodeId, Color? textColor) onNodeTextColorChanged;
  final void Function(String nodeId, Radius? borderRadius) onNodeBorderRadiusChanged;

  final void Function(String edgeId, bool showText) onEdgeShowTextChanged;
  final void Function(String edgeId, String text) onEdgeTextChanged;
  final void Function(String edgeId, Color? textBackgroundColor) onEdgeTextBackgroundColorChanged;
  final void Function(String edgeId, Color? textColor) onEdgeTextColorChanged;
  final void Function(String edgeId, Color? lineColor) onEdgeLineColorChanged;
  final void Function(String edgeId, LineStyle? lineStyle) onEdgeLineStyleChanged;
  final void Function(String edgeId, bool overrideArrowStyle) onEdgeOverrideArrowStyleChanged;
  final void Function(String edgeId, double arrowWidth, double arrowLength) onEdgeArrowChanged;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        inputDecorationTheme: InputDecorationThemeData(
          border: OutlineInputBorder(),
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Builder(
            builder: (context) {
              if (selectedNodes.length == 1 && selectedEdges.isEmpty) {
                final ExampleNode node = selectedNodes.single;

                return NodePropertiesPanel(
                  node: node,
                  onDeleteNode: () => onDeleteNode(node.id),
                  onTextChanged: (String text) => onNodeTextChanged(node.id, text),
                  onBackgroundColorChanged: (Color? backgroundColor) =>
                      onNodeBackgroundColorChanged(node.id, backgroundColor),
                  onTextColorChanged: (Color? textColor) => onNodeTextColorChanged(node.id, textColor),
                  onBorderRadiusChanged: (Radius? borderRadius) => onNodeBorderRadiusChanged(node.id, borderRadius),
                );
              } else if (selectedEdges.length == 1 && selectedNodes.isEmpty) {
                final ExampleEdge edge = selectedEdges.single;

                return EdgePropertiesPanel(
                  edge: edge,
                  onDeleteEdge: () => onDeleteEdge(edge.id),
                  onShowTextChanged: (bool showText) => onEdgeShowTextChanged(edge.id, showText),
                  onTextChanged: (String text) => onEdgeTextChanged(edge.id, text),
                  onTextBackgroundColorChanged: (Color? textBackgroundColor) =>
                      onEdgeTextBackgroundColorChanged(edge.id, textBackgroundColor),
                  onTextColorChanged: (Color? textColor) => onEdgeTextColorChanged(edge.id, textColor),
                  onLineColorChanged: (Color? lineColor) => onEdgeLineColorChanged(edge.id, lineColor),
                  onLineStyleChanged: (LineStyle? lineStyle) => onEdgeLineStyleChanged(edge.id, lineStyle),
                  onOverrideArrowStyleChanged: (bool overrideArrowStyle) =>
                      onEdgeOverrideArrowStyleChanged(edge.id, overrideArrowStyle),
                  onArrowChanged: (double arrowWidth, double arrowLength) =>
                      onEdgeArrowChanged(edge.id, arrowWidth, arrowLength),
                );
              } else {
                return Center(
                  child: Text(
                    "Please select a single node or edge to change its properties",
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
