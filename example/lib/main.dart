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
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
        extensions: {
          GraphStyle(
            backgroundColor: Colors.blue,
          ),
          EdgeStyle(
            lineColor: Colors.red,
            textStyle: TextStyle(color: Colors.white, backgroundColor: Colors.blue.withValues(alpha: 0.8)),
            lineStyle: SolidLineStyle(thickness: 2),
            curveStyle: StraightCurveStyle(),
            arrowStyle: ArrowStyle(length: 20, width: 20),
          ),
          NodeStyle(
            backgroundColor: Colors.purple,
            textStyle: TextStyle(color: Colors.amber),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            borderSide: BorderSide(color: Colors.green),
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
      ExampleNode(id: "node3", position: Offset(500, 300)),
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
        actions: [
          IconButton(
            onPressed: () async => print(
              await _graphViewportController.showEdgesOnScreen(
                {"edge"},
                margin: EdgeInsets.only(bottom: 500),
                curve: Curves.ease,
                duration: Duration(seconds: 3),
              ),
            ),
            icon: const Icon(
              Icons.location_searching,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: GraphView<String, String>(
        viewportController: _graphViewportController,
        nodeBuilder: (context, nodeId) {
          return NodeWidget.basic(
            position: _nodes[nodeId]!.position,
            maxWidth: 400,
            borderRadius: Radius.circular(10),
            clipBehavior: Clip.antiAlias,
            text: nodeId,
            onDragDown: (details) => _graphViewportController.movingNodeIds = {nodeId},
            isDragEnabled: true,
            onDragStart: (details) => print("Drag node $nodeId"),
            overlay: NodeOverlay(
              alignmentInNode: Alignment.bottomRight,
              child: GestureDetector(
                onPanStart: (details) => print("Drag node overlay $nodeId"),
                child: Container(
                  padding: EdgeInsets.all(1),
                  color: Colors.black.withValues(alpha: 0.6),
                  child: Text(
                    "Overlay",
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ),
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
