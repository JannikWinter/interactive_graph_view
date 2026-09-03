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

  late final GraphViewportController<String, String, ExampleNode> _graphViewportController;
  late final GraphViewportTransform _graphViewportTransform;

  @override
  void initState() {
    super.initState();

    _graphViewportController = GraphViewportController(
      initialNodes: _nodes,
      initialEdges: _edges.values.map(
        (edge) => EdgeData(edgeId: edge.id, startNodeId: edge.startNodeId, endNodeId: edge.endNodeId),
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
      body: GraphViewport<String, String, ExampleNode>(
        controller: _graphViewportController,
        transform: _graphViewportTransform,
        nodeBuilder: (context, nodeId) {
          return NodeWidget.basic(
            text: nodeId,
            isDragEnabled: false,
          );
        },
        edgeBuilder: (context, edgeId) {
          return EdgeWidget();
        },
      ),
    );
  }
}

class ExampleNode extends DynamicGraphViewportNodeModel {
  ExampleNode({required this.id, required Offset position}) : _position = position;

  final String id;

  Offset _position;

  @override
  Offset get position => _position;

  set position(Offset position) {
    if (_position == position) return;
    _position = position;
    notifyNeedsRebuild();
  }
}

class ExampleEdge {
  ExampleEdge({required this.id, required this.startNodeId, required this.endNodeId});

  final String id;

  String startNodeId;
  String endNodeId;
}
