import "package:flutter/material.dart";

import "package:interactive_graph_view/interactive_graph_view.dart";

// This example shows you how you can implement selection of nodes and then being able
// to move them all at the same time.
// This will use the package's default style for viewport, nodes and edges.

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
  final Map<String, ExampleNode> _nodes = Map.fromIterable(
    {
      ExampleNode(id: "node1", position: Offset(-50, -50)),
      ExampleNode(id: "node2", position: Offset(50, -50)),
      ExampleNode(id: "node3", position: Offset(-50, 50)),
      ExampleNode(id: "node4", position: Offset(50, 50)),
    },
    key: (node) => node.id,
  );

  final Map<String, ExampleEdge> _edges = Map.fromIterable(
    {
      ExampleEdge(id: "edge1", startNodeId: "node1", endNodeId: "node4"),
      ExampleEdge(id: "edge2", startNodeId: "node2", endNodeId: "node3"),
    },
    key: (edge) => edge.id,
  );

  late final GraphViewportController<String, String> _graphViewportController;

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
      appBar: AppBar(
        title: Text("Graph View Demo"),
      ),
      body: GraphView<String, String>(
        viewportController: _graphViewportController,
        nodeBuilder: (context, nodeId) {
          final bool isSelected = _selectedNodeIds.contains(nodeId);
          return NodeWidget.basic(
            position: _nodes[nodeId]!.position,
            text: nodeId,
            style: isSelected
                ? NodeStyle(
                    borderSide: BorderSide(
                      color: Colors.red,
                      width: 2.0,
                    ),
                  )
                : null,

            // Only enable dragging on selected nodes.
            isDragEnabled: isSelected,
            onTap: () {
              // Toggle the selection state.
              _toggleNodeSelection(nodeId);

              // Rebuild this node with the new selection state applied.
              _graphViewportController.rebuildNode(nodeId);

              // Tell the viewport, which nodes should move when dragging a drag-enabled node.
              _graphViewportController.movingNodeIds = _selectedNodeIds;
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
}

class ExampleNode {
  ExampleNode({required this.id, required this.position});

  final String id;

  Offset position;
}

class ExampleEdge {
  ExampleEdge({required this.id, required this.startNodeId, required this.endNodeId});

  final String id;

  String startNodeId;
  String endNodeId;
}
