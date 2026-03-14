import "dart:math";

import "package:flutter/material.dart";

import "package:interactive_graph_view/interactive_graph_view.dart";

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
    );
  }
}

class GraphViewExampleHomePage extends StatefulWidget {
  const GraphViewExampleHomePage({super.key});

  @override
  State<GraphViewExampleHomePage> createState() => _GraphViewExampleHomePageState();
}

class _GraphViewExampleHomePageState extends State<GraphViewExampleHomePage> {
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

  void _toggleNodeSelection(String nodeId) {
    if (_selectedNodeIds.contains(nodeId)) {
      _selectedNodeIds.remove(nodeId);
    } else {
      _selectedNodeIds.add(nodeId);
    }
  }

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
      body: GraphView<String, String>(
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
          return NodeWidget.basic(
            position: _nodes[nodeId]!.position,
            text: nodeId,
            style: isSelected
                ? NodeStyle(
                    borderSide: BorderSide(color: Colors.red, width: 2.0),
                  )
                : null,

            // Only enable dragging if the node is selected.
            isDragEnabled: isSelected,

            onTap: () {
              // Toggle the selection state.
              _toggleNodeSelection(nodeId);

              // Rebuild this node with the new selection state applied.
              _graphViewportController.rebuildNode(nodeId);

              // Tell the viewport, which nodes should move when dragging a drag-enabled node.
              _graphViewportController.movingNodeIds = _selectedNodeIds;
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
          return EdgeWidget(
            startNodeId: _edges[edgeId]!.startNodeId,
            endNodeId: _edges[edgeId]!.endNodeId,
            text: null,
          );
        },
      ),
    );
  }

  void _clearSelection() {
    for (final String selectedNodeId in _selectedNodeIds) {
      _graphViewportController.rebuildNode(selectedNodeId);
    }
    _selectedNodeIds.clear();
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

final Random _random = Random();
final String idCharSet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
String _newRandomId({int length = 8}) {
  String result = "";
  for (int i = 0; i < length; i++) {
    result += idCharSet[_random.nextInt(idCharSet.length)];
  }
  return result;
}

class ExampleNode {
  ExampleNode({String? id, required this.position}) : id = id ?? _newRandomId();

  final String id;

  Offset position;
}

class ExampleEdge {
  ExampleEdge({String? id, required this.startNodeId, required this.endNodeId}) : id = id ?? _newRandomId();

  final String id;

  String startNodeId;
  String endNodeId;
}
