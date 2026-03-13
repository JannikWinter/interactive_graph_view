import "package:flutter/material.dart";

import "package:interactive_graph_view/interactive_graph_view.dart";

// This is a minimal example that will only show two nodes and an edge connecting them.
// You can pan and scale the viewport, but you can not move the nodes themselves.
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
      ExampleNode(id: "node2", position: Offset(50, 50)),
    },
    key: (node) => node.id,
  );

  final Map<String, ExampleEdge> _edges = Map.fromIterable(
    {
      ExampleEdge(id: "edge", startNodeId: "node1", endNodeId: "node2"),
    },
    key: (edge) => edge.id,
  );

  late final GraphViewportController<String, String> _graphViewportController;

  @override
  void initState() {
    super.initState();

    _graphViewportController = GraphViewportController(
      initialNodeIds: _nodes.keys,
      initialEdgeIds: _edges.keys,
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
          return NodeWidget.basic(
            position: _nodes[nodeId]!.position,
            text: nodeId,
            isDragEnabled: false,
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
