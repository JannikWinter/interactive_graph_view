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

class _GraphViewExampleHomePageState extends State<GraphViewExampleHomePage> with TickerProviderStateMixin {
  static const NodeStyle _selectedNodeStyle = NodeStyle(
    borderSide: BorderSide(color: Colors.red, width: 2.0),
  );
  static const EdgeStyle _selectedEdgeStyle = EdgeStyle(
    shadow: [LineShadow(color: Colors.red, blurRadius: 0, spreadRadius: 1.5)],
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
  late final GraphViewportTransform _graphViewportTransform;

  late Offset _tapDownPosition;

  final Set<String> _selectedNodeIds = {};
  final Set<String> _selectedEdgeIds = {};

  @override
  void initState() {
    super.initState();

    _graphViewportController = GraphViewportController(
      initialNodes: _nodes.values.map(
        (node) => NodeData(nodeId: node.id, position: node.position),
      ),
      initialEdges: _edges.values.map(
        (edge) => EdgeData(
          edgeId: edge.id,
          startNodeId: edge.startNodeId,
          endNodeId: edge.endNodeId,
        ),
      ),
    );
    _graphViewportTransform = GraphViewportTransform(vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Graph View Demo"),
      ),
      body: HorizontalOrVertical(
        primary: GraphViewport<String, String>(
          controller: _graphViewportController,
          transform: _graphViewportTransform,
          movingNodeIds: _selectedNodeIds,
          onNodesMoved: (nodeIds, offset) {
            for (String nodeId in nodeIds) {
              // Reflect the dragged node offset back to the graph structure.
              _nodes[nodeId]!.position += offset;

              // Rebuild the node at the new position.
              _graphViewportController.insertNode(NodeData(nodeId: nodeId, position: _nodes[nodeId]!.position));
            }
          },
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
                  textStyle: TextStyle(color: edge.textColor),
                ),
              ),
            );
          },
        ),
        secondary: PropertiesPanel(
          selectedNodes: _selectedNodeIds.map((nodeId) => _nodes[nodeId]!).toSet(),
          selectedEdges: _selectedEdgeIds.map((edgeId) => _edges[edgeId]!).toSet(),
          onDeleteNode: (nodeId) {
            _deleteNode(nodeId);
          },
          onDeleteEdge: (edgeId) {
            _deleteEdge(edgeId);
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
          onEdgeTextColorChanged: (edgeId, textColor) {
            _edges[edgeId]!.textColor = textColor;
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
    setState(() {
      if (_selectedNodeIds.contains(nodeId)) {
        _selectedNodeIds.remove(nodeId);
      } else {
        _selectedNodeIds.add(nodeId);
      }
    });
    _graphViewportController.rebuildNode(nodeId);
  }

  void _singleSelectNode(String nodeId) {
    setState(() {
      _clearSelection();
      _selectedNodeIds.add(nodeId);
    });
    _graphViewportController.rebuildNode(nodeId);
  }

  void _toggleEdgeSelection(String edgeId) {
    setState(() {
      if (_selectedEdgeIds.contains(edgeId)) {
        _selectedEdgeIds.remove(edgeId);
      } else {
        _selectedEdgeIds.add(edgeId);
      }
    });
    _graphViewportController.rebuildEdge(edgeId);
  }

  void _singleSelectEdge(String edgeId) {
    setState(() {
      _clearSelection();
      _selectedEdgeIds.add(edgeId);
    });
    _graphViewportController.rebuildEdge(edgeId);
  }

  void _clearSelection() {
    for (final String selectedNodeId in _selectedNodeIds) {
      _graphViewportController.rebuildNode(selectedNodeId);
    }
    for (final String selectedEdgeId in _selectedEdgeIds) {
      _graphViewportController.rebuildEdge(selectedEdgeId);
    }

    setState(() {
      _selectedNodeIds.clear();
      _selectedEdgeIds.clear();
    });
  }

  String _createNode(Offset position) {
    final ExampleNode newNode = ExampleNode(position: _tapDownPosition);
    _nodes[newNode.id] = newNode;
    _graphViewportController.insertNode(
      NodeData(nodeId: newNode.id, position: position),
    );

    return newNode.id;
  }

  String _createEdge(String startNodeId, String endNodeId) {
    final ExampleEdge newEdge = ExampleEdge(
      startNodeId: startNodeId,
      endNodeId: endNodeId,
    );
    _edges[newEdge.id] = newEdge;
    _graphViewportController.insertEdge(
      EdgeData(
        edgeId: newEdge.id,
        startNodeId: startNodeId,
        endNodeId: endNodeId,
      ),
    );

    return newEdge.id;
  }

  void _deleteNode(String nodeId) {
    final Set<String> connectedEdgeIds = _edges.values
        .where((edge) => edge.startNodeId == nodeId || edge.endNodeId == nodeId)
        .map((edge) => edge.id)
        .toSet();
    for (final String connectedEdgeId in connectedEdgeIds) {
      _deleteEdge(connectedEdgeId);
    }

    _nodes.remove(nodeId);
    _selectedNodeIds.remove(nodeId);
    _graphViewportController.removeNode(nodeId);

    setState(() {});
  }

  void _deleteEdge(String edgeId) {
    _edges.remove(edgeId);
    _selectedEdgeIds.remove(edgeId);
    _graphViewportController.removeEdge(edgeId);
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
    this.textColor,
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
  Color? textColor;
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
