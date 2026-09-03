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

class _GraphViewExampleHomePageState extends State<GraphViewExampleHomePage> with TickerProviderStateMixin {
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

  late final GraphViewportController<String, String, ExampleNode, ExampleEdge> _graphViewportController;
  late final GraphViewportTransform _graphViewportTransform;

  @override
  void initState() {
    super.initState();

    _graphViewportController = GraphViewportController(initialNodes: _nodes, initialEdges: _edges);
    _graphViewportTransform = GraphViewportTransform(vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Graph View Demo"),
      ),
      body: GraphViewport<String, String, ExampleNode, ExampleEdge>(
        controller: _graphViewportController,
        transform: _graphViewportTransform,
        nodeBuilder: (context, nodeId, node) {
          return NodeWidget.basic(
            text: nodeId,
            isDragEnabled: false,
          );
        },
        edgeBuilder: (context, edgeId, edge) {
          return EdgeWidget();
        },
      ),
    );
  }
}

class ExampleNode extends StaticGraphViewportNodeModel {
  const ExampleNode({required this.id, required this.position});

  final String id;

  @override
  final Offset position;

  @override
  bool shouldRebuild(ExampleNode previous) {
    return false;
  }
}

class ExampleEdge extends StaticGraphViewportEdgeModel<String> {
  const ExampleEdge({required this.id, required this.startNodeId, required this.endNodeId});

  final String id;

  @override
  final String startNodeId;

  @override
  final String endNodeId;

  @override
  bool shouldRebuild(ExampleEdge previous) {
    return false;
  }
}
