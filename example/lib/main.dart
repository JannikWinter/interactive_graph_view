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
        extensions: {
          EdgeStyle(
            lineColor: Colors.red,
            textStyle: TextStyle(color: Colors.green),
            lineStyle: SolidLineStyle(thickness: 2),
            curveStyle: StraightCurveStyle(),
            arrowStyle: ArrowStyle(length: 20, width: 20),
          ),
        },
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
  final Map<String, ExampleNode> _nodes = Map.fromIterable(
    {
      ExampleNode(id: "node1", position: Offset(-50, -50)),
      ExampleNode(id: "node2", position: Offset(50, 50)),
    },
    key: (node) => node.id,
  );

  final Map<String, ExampleEdge> _edges = Map.fromIterable({
    ExampleEdge(id: "edge", startNodeId: "node1", endNodeId: "node2"),
  }, key: (edge) => edge.id);

  late final GraphViewportController<String, String> _graphViewportController;

  @override
  void initState() {
    super.initState();

    _graphViewportController = GraphViewportController(
      initialNodeIds: _nodes.keys,
      initialEdgeIds: _edges.keys,
      onNodesMoved: (nodeIds, offset) {
        for (final String nodeId in nodeIds) {
          _nodes[nodeId]!.position += offset;
          _graphViewportController.rebuildNode(nodeId);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Graph View Demo"),
      ),
      body: GraphView<String, String>(
        viewportController: _graphViewportController,
        nodeBuilder: (context, nodeId) {
          return NodeWidget(
            position: _nodes[nodeId]!.position,
            borderRadius: Radius.circular(10),
            clipBehavior: Clip.antiAlias,
            content: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(nodeId),
            ),
            background: Container(color: Colors.blue),
            onDragDown: (details) => _graphViewportController.movingNodeIds = {nodeId},
            isDragEnabled: true,
          );
        },
        edgeBuilder: (context, edgeId) {
          return EdgeWidget(
            startNodeId: _edges[edgeId]!.startNodeId,
            endNodeId: _edges[edgeId]!.endNodeId,
            text: edgeId,
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
