import "package:flutter/material.dart";

import "package:graph_view/graph_view.dart";

void main() {
  runApp(const GraphViewExampleApp());
}

class GraphViewExampleApp extends StatelessWidget {
  const GraphViewExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Graph View Demo",
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
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
  final GraphViewportController<String, ExampleNode, String, ExampleEdge> _graphViewportController =
      GraphViewportController(
        initialNodes: {
          ExampleNode(id: "node1", position: Offset(-50, -50)),
          ExampleNode(id: "node2", position: Offset(50, 50)),
        },
        initialEdges: {
          ExampleEdge(id: "edge", startNodeId: "node1", endNodeId: "node2"),
        },
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Graph View Demo"),
      ),
      body: GraphView<String, ExampleNode, String, ExampleEdge>(
        viewportController: _graphViewportController,
        nodeBuilder: (context, nodeId) {
          return NodeWidget(
            borderRadius: Radius.circular(10),
            clipBehavior: Clip.antiAlias,
            content: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(nodeId),
            ),
            background: Container(color: Colors.blue),
            onDragDown: (details) => _graphViewportController.movingNodeIds = {nodeId},
          );
        },
        edgeBuilder: (context, edgeId) {
          return EdgeWidget(
            text: null,
            color: Colors.red,
            thickness: 2,
            lineStyle: LineStyle.solid,
            curveStyle: CurveStyle.straight,
          );
        },
      ),
    );
  }
}

class ExampleNode implements NodeData<String> {
  ExampleNode({required this.id, required this.position});

  @override
  final String id;

  @override
  Offset position;
}

class ExampleEdge implements EdgeData<String, String> {
  ExampleEdge({required this.id, required this.startNodeId, required this.endNodeId});

  @override
  final String id;

  @override
  String startNodeId;

  @override
  String endNodeId;
}
