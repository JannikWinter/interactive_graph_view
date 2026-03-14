import "package:flutter/material.dart";

import "package:interactive_graph_view/interactive_graph_view.dart";

// This example demonstrates the usage of styles: Both, in combination with [ThemeData] and as inline styles.

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
          // Here you can set the default style for your whole app.
          // Each field that you don't fill here, will use a default value provided by the package.
          GraphStyle(
            backgroundColor: Colors.blue.shade900,
          ),
          NodeStyle(
            backgroundColor: Colors.blue,
            borderRadius: Radius.circular(8.0),
            textStyle: TextStyle(color: Colors.white),
            borderSide: BorderSide(
              color: Colors.blue.shade300,
              width: 1.5,
            ),
          ),
          EdgeStyle(
            arrowStyle: ArrowStyle(length: 10, width: 15),
            lineStyle: SolidLineStyle(thickness: 2),
            textBackgroundColor: Colors.blue.shade900,
            textStyle: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.blue.shade100,
            ),
            lineColor: Colors.blue.shade100,
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
  final Map<String, ExampleNode> _nodes = Map.fromIterable(
    {
      ExampleNode(
        id: "node1",
        position: Offset(-80, -80),
        inlineStyle: NodeStyle(borderRadius: Radius.zero),
      ),
      ExampleNode(
        id: "node2",
        position: Offset(80, -80),
        inlineStyle: NodeStyle(maxWidth: 25),
      ),
      ExampleNode(
        id: "node3",
        position: Offset(-80, 0),
        inlineStyle: NodeStyle(padding: EdgeInsets.all(2)),
      ),
      ExampleNode(
        id: "node4",
        position: Offset(80, 0),
        inlineStyle: NodeStyle(backgroundColor: Colors.green),
      ),
      ExampleNode(
        id: "node5",
        position: Offset(-80, 80),
        inlineStyle: NodeStyle(borderSide: BorderSide(color: Colors.black, width: 3.0)),
      ),
      ExampleNode(id: "node6", position: Offset(80, 80)),
    },
    key: (node) => node.id,
  );

  final Map<String, ExampleEdge> _edges = Map.fromIterable(
    {
      ExampleEdge(id: "edge1", startNodeId: "node1", endNodeId: "node2", showText: true),
      ExampleEdge(
        id: "edge2",
        startNodeId: "node3",
        endNodeId: "node4",
        inlineStyle: EdgeStyle(
          lineStyle: DashedLineStyle(thickness: 2, dashSize: 10, gapSize: 5),
        ),
      ),
      ExampleEdge(
        id: "edge3",
        startNodeId: "node5",
        endNodeId: "node6",
        inlineStyle: EdgeStyle(
          shadow: [LineShadow(color: Colors.red, blurRadius: 10, spreadRadius: 5)],
        ),
      ),
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
          final ExampleNode node = _nodes[nodeId]!;
          return NodeWidget.basic(
            position: node.position,
            text: nodeId,
            isDragEnabled: false,

            // Here you can provide the inline style for this node.
            // Each NodeStyle property that is empty in this given style uses either the value provided in [ThemeData]
            // or a fallback style if that is also empty.
            style: node.inlineStyle,
          );
        },
        edgeBuilder: (context, edgeId) {
          final ExampleEdge edge = _edges[edgeId]!;
          return EdgeWidget(
            startNodeId: edge.startNodeId,
            endNodeId: edge.endNodeId,
            text: edge.showText ? edgeId : null,

            // Here you can provide the inline style for this edge.
            // Each EdgeStyle property that is empty in this given style uses either the value provided in [ThemeData]
            // or a fallback style if that is also empty.
            style: edge.inlineStyle,
          );
        },
      ),
    );
  }
}

class ExampleNode {
  ExampleNode({
    required this.id,
    required this.position,
    this.inlineStyle,
  });

  final String id;
  Offset position;
  NodeStyle? inlineStyle;
}

class ExampleEdge {
  ExampleEdge({
    required this.id,
    required this.startNodeId,
    required this.endNodeId,
    this.inlineStyle,
    this.showText = false,
  });

  final String id;
  String startNodeId;
  String endNodeId;
  EdgeStyle? inlineStyle;
  bool showText;
}
