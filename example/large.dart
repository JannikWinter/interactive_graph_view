import "dart:math";

import "package:flutter/material.dart";

import "package:interactive_graph_view/interactive_graph_view.dart";

import "large/horizontal_or_vertical.dart";
import "large/properties_panel.dart";

void main() {
  runApp(const GraphViewExampleApp());
}

class GraphViewExampleApp extends StatelessWidget {
  const GraphViewExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Graph View Demo",
      home: const GraphViewExampleHomePage(),
      theme: ThemeData(
        extensions: {
          GraphStyle(backgroundColor: Colors.blue.shade900),
          NodeStyle(
            backgroundColor: Colors.blue.shade100,
            textStyle: TextStyle(color: Colors.blue.shade900),
            borderRadius: Radius.circular(5),
          ),
          EdgeStyle(
            arrowStyle: ArrowStyle(length: 8, width: 12),
            lineStyle: SolidLineStyle(thickness: 2),
          ),
        },
      ),
    );
  }
}

class GraphViewExampleHomePage extends StatefulWidget {
  const GraphViewExampleHomePage({super.key});

  @override
  State<GraphViewExampleHomePage> createState() => _GraphViewExampleHomePageState();
}

class _GraphViewExampleHomePageState extends State<GraphViewExampleHomePage> {
  static const NodeStyle _selectedNodeStyle = NodeStyle(
    borderSide: BorderSide(
      color: Colors.red,
      width: 2.0,
    ),
  );
  static const EdgeStyle _selectedEdgeStyle = EdgeStyle(
    shadow: [
      LineShadow(
        color: Colors.red,
        blurRadius: 0,
        spreadRadius: 1.5,
      ),
    ],
  );

  final Map<String, ExampleNode> _nodes = Map.fromIterable({
    ExampleNode(position: Offset(-50, -50)),
    ExampleNode(position: Offset(50, -50)),
    ExampleNode(position: Offset(-50, 50)),
    ExampleNode(position: Offset(50, 50)),
  }, key: (node) => node.id);

  late final Map<String, ExampleEdge> _edges = Map.fromIterable({
    ExampleEdge(
      startNodeId: _nodes.keys.elementAt(0),
      endNodeId: _nodes.keys.elementAt(1),
    ),
    ExampleEdge(
      startNodeId: _nodes.keys.elementAt(2),
      endNodeId: _nodes.keys.elementAt(3),
    ),
  }, key: (edge) => edge.id);

  late final GraphViewportController<String, String> _graphViewportController;

  late Offset _tapDownPosition;

  final Set<String> _selectedNodeIds = {};
  final Set<String> _selectedEdgeIds = {};

  @override
  void initState() {
    super.initState();

    _graphViewportController = GraphViewportController(
      initialNodeIds: _nodes.keys,
      initialEdgeIds: _edges.keys,

      onNodesMoved: (nodeIds, offset) {
        for (String nodeId in nodeIds) {
          // Reflect the dragged node offset back to the graph structure.
          _nodes[nodeId]!.position += offset;

          // Rebuild the node at the new position.
          _graphViewportController.rebuildNode(nodeId);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Graph View Demo")),
      body: HorizontalOrVertical(
        primary: GraphView<String, String>(
          // If this is set to true, every hot-reload and every rebuild of the viewport, for example by hot-reloading
          // or calling setState() on a parent, will rebuild *all* children (nodes and edges). This is very useful for
          // during development, but should generally be set to false.
          // When set to false, only calls to GraphViewportController.rebuildNode() or .rebuildEdge() will trigger
          // child rebuilds.
          rebuildAllChildrenOnWidgetUpdate: true,

          viewportController: _graphViewportController,
          onTapDown: (details) {
            _tapDownPosition = details.graphPosition;
          },
          onTap: () {
            _clearSelection();
          },
          onDoubleTap: () {
            // Create a new node when double tapping on an empty spot.
            final String newNodeId = _createNode(_tapDownPosition);

            // Create a new edge from each currently selected node to
            // the newly created node.
            for (final String selectedNodeId in _selectedNodeIds) {
              _createEdge(selectedNodeId, newNodeId);
            }

            // Clear the selection.
            _clearSelection();
          },
          nodeBuilder: (context, nodeId) {
            final bool isSelected = _selectedNodeIds.contains(nodeId);
            final ExampleNode node = _nodes[nodeId]!;

            return NodeWidget.basic(
              position: node.position,
              text: node.text,
              style: (isSelected ? _selectedNodeStyle : NodeStyle()).merge(
                NodeStyle(
                  backgroundColor: node.backgroundColor,
                  borderRadius: node.borderRadius,
                  textStyle: TextStyle(color: node.textColor),
                ),
              ),

              // Only enable dragging if the node is selected.
              isDragEnabled: isSelected,

              onTap: () {
                // Select this node, deselect everything else.
                _singleSelectNode(nodeId);
              },
              onLongPress: () {
                // Toggle the selection state.
                _toggleNodeSelection(nodeId);
              },
              onDoubleTap: () {
                // Create an edge from each currently selected node to this node.

                // Do not create edges if the node is source and target.
                if (_selectedNodeIds.contains(nodeId)) return;
                // Do not create edges if no node is selected.
                if (_selectedNodeIds.isEmpty) return;

                // Create the edges.
                for (final String selectedNodeId in _selectedNodeIds) {
                  _createEdge(selectedNodeId, nodeId);
                }

                // Clear selection.
                _clearSelection();
              },
            );
          },
          edgeBuilder: (context, edgeId) {
            final bool isSelected = _selectedEdgeIds.contains(edgeId);
            final ExampleEdge edge = _edges[edgeId]!;

            return EdgeWidget(
              startNodeId: edge.startNodeId,
              endNodeId: edge.endNodeId,
              text: edge.showText ? edge.text : null,
              onTap: () {
                // Select this node, deselect everything else.
                _singleSelectEdge(edgeId);
              },
              onLongPress: () {
                // Toggle the selection state.
                _toggleEdgeSelection(edgeId);
              },
              style: (isSelected ? _selectedEdgeStyle : EdgeStyle()).merge(
                EdgeStyle(
                  arrowStyle: edge.overrideArrowStyle
                      ? ArrowStyle(
                          width: edge.arrowWidth,
                          length: edge.arrowLength,
                        )
                      : null,
                  lineStyle: edge.lineStyle,
                  lineColor: edge.lineColor,
                  textBackgroundColor: edge.textBackgroundColor,
                ),
              ),
            );
          },
        ),
        secondary: PropertiesPanel(
          selectedNodes: _selectedNodeIds.map((nodeId) => _nodes[nodeId]!).toSet(),
          selectedEdges: _selectedEdgeIds.map((edgeId) => _edges[edgeId]!).toSet(),
          onDeleteNode: (nodeId) {
            _nodes.remove(nodeId);
            _selectedNodeIds.remove(nodeId);
            _graphViewportController.removeNode(nodeId);
          },
          onDeleteEdge: (edgeId) {
            _edges.remove(edgeId);
            _selectedEdgeIds.remove(edgeId);
            _graphViewportController.removeEdge(edgeId);
          },
          onNodeTextChanged: (nodeId, text) {
            _nodes[nodeId]!.text = text;
            _graphViewportController.rebuildNode(nodeId);
          },
          onNodeBackgroundColorChanged: (nodeId, backgroundColor) {
            _nodes[nodeId]!.backgroundColor = backgroundColor;
            _graphViewportController.rebuildNode(nodeId);
          },
          onNodeTextColorChanged: (nodeId, textColor) {
            _nodes[nodeId]!.textColor = textColor;
            _graphViewportController.rebuildNode(nodeId);
          },
          onNodeBorderRadiusChanged: (nodeId, borderRadius) {
            _nodes[nodeId]!.borderRadius = borderRadius;
            _graphViewportController.rebuildNode(nodeId);
          },
          onEdgeShowTextChanged: (edgeId, showText) {
            _edges[edgeId]!.showText = showText;
            _graphViewportController.rebuildEdge(edgeId);
          },
          onEdgeTextChanged: (edgeId, text) {
            _edges[edgeId]!.text = text;
            _graphViewportController.rebuildEdge(edgeId);
          },
          onEdgeTextBackgroundColorChanged: (edgeId, textBackgroundColor) {
            _edges[edgeId]!.textBackgroundColor = textBackgroundColor;
            _graphViewportController.rebuildEdge(edgeId);
          },
          onEdgeLineColorChanged: (edgeId, lineColor) {
            _edges[edgeId]!.lineColor = lineColor;
            _graphViewportController.rebuildEdge(edgeId);
          },
          onEdgeLineStyleChanged: (edgeId, lineStyle) {
            _edges[edgeId]!.lineStyle = lineStyle;
            _graphViewportController.rebuildEdge(edgeId);
          },
          onEdgeOverrideArrowStyleChanged: (edgeId, overrideArrowStyle) {
            _edges[edgeId]!.overrideArrowStyle = overrideArrowStyle;
            _graphViewportController.rebuildEdge(edgeId);
          },
          onEdgeArrowChanged: (edgeId, arrowWidth, arrowLength) {
            _edges[edgeId]!
              ..arrowWidth = arrowWidth
              ..arrowLength = arrowLength;
            _graphViewportController.rebuildEdge(edgeId);
          },
        ),
      ),
    );
  }

  void _toggleNodeSelection(String nodeId) {
    if (_selectedNodeIds.contains(nodeId)) {
      _selectedNodeIds.remove(nodeId);
    } else {
      _selectedNodeIds.add(nodeId);
    }

    // Trigger rebuild to update the properties panel
    setState(() {});

    // Tell the viewport, which nodes should move when dragging a drag-enabled node.
    _graphViewportController.movingNodeIds = _selectedNodeIds;
  }

  void _singleSelectNode(String nodeId) {
    _clearSelection();
    _selectedNodeIds.add(nodeId);

    // Tell the viewport, which nodes should move when dragging a drag-enabled node.
    _graphViewportController.movingNodeIds = _selectedNodeIds;
  }

  void _toggleEdgeSelection(String edgeId) {
    if (_selectedEdgeIds.contains(edgeId)) {
      _selectedEdgeIds.remove(edgeId);
    } else {
      _selectedEdgeIds.add(edgeId);
    }

    // Trigger rebuild to update the properties panel
    setState(() {});
  }

  void _singleSelectEdge(String edgeId) {
    _clearSelection();
    _selectedEdgeIds.add(edgeId);
  }

  void _clearSelection() {
    for (final String selectedNodeId in _selectedNodeIds) {
      _graphViewportController.rebuildNode(selectedNodeId);
    }
    for (final String selectedEdgeId in _selectedEdgeIds) {
      _graphViewportController.rebuildEdge(selectedEdgeId);
    }
    _selectedNodeIds.clear();
    _selectedEdgeIds.clear();

    // Trigger rebuild to update the properties panel
    setState(() {});

    // Tell the viewport, which nodes should move when dragging a drag-enabled node.
    _graphViewportController.movingNodeIds = _selectedNodeIds;
  }

  String _createNode(Offset position) {
    final ExampleNode newNode = ExampleNode(position: _tapDownPosition);
    _nodes[newNode.id] = newNode;
    _graphViewportController.insertNode(newNode.id);

    return newNode.id;
  }

  String _createEdge(String startNodeId, String endNodeId) {
    final ExampleEdge newEdge = ExampleEdge(
      startNodeId: startNodeId,
      endNodeId: endNodeId,
    );
    _edges[newEdge.id] = newEdge;
    _graphViewportController.insertEdge(newEdge.id);

    return newEdge.id;
  }
}

class ExampleNode {
  ExampleNode({
    String? id,
    required this.position,
    String? text,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
  }) : id = id ?? _newRandomId() {
    this.text = text ?? this.id;
  }

  final String id;

  Offset position;

  late String text;
  Color? backgroundColor;
  Color? textColor;
  Radius? borderRadius;
}

class ExampleEdge {
  ExampleEdge({
    String? id,
    required this.startNodeId,
    required this.endNodeId,
    this.showText = false,
    this.text = "",
    this.textBackgroundColor,
    this.lineColor,
    this.lineStyle,
    this.overrideArrowStyle = false,
    this.arrowWidth = 10,
    this.arrowLength = 10,
  }) : id = id ?? _newRandomId();

  final String id;

  String startNodeId;
  String endNodeId;

  bool showText;
  String text;
  Color? textBackgroundColor;
  Color? lineColor;
  LineStyle? lineStyle;
  bool overrideArrowStyle;
  double arrowWidth;
  double arrowLength;
}

// =============================
// ========== HELPERS ==========
// =============================

final Random _random = Random();
final String idCharSet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
String _newRandomId({int length = 8}) {
  String result = "";
  for (int i = 0; i < length; i++) {
    result += idCharSet[_random.nextInt(idCharSet.length)];
  }
  return result;
}
