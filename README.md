<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

With this package you can display and interact with graphs while being able to apply your own custom styles to each element.

## Features

- each child is only built when necessary
- viewport panning and scaling
- node dragging
- custom styling per element
- fully integrated with flutter's architecture

## Getting started

Add this package to your pubspec.yaml file.

## Usage

This is a simple example for displaying 2 nodes and a connecting edge. You can also drag each node around.
More complex examples using more features can be found in the `example/` folder.

```dart
import "package:flutter/material.dart";
import "package:graph_view/graph_view.dart";

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
        title: Text("Graph View Demo"),
      ),
      body: GraphView<String, String>(
        viewportController: _graphViewportController,
        nodeBuilder: (context, nodeId) {
          return NodeWidget.basic(
            position: _nodes[nodeId]!.position,
            text: nodeId,
            maxWidth: 400,
            isDragEnabled: true,
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
```

## Additional information

You are welcome to contribute to this package!
If you run into bugs or need a feature that is not yet implemented, just open an issue on GitHub.

## License

This package is under the [MPL 2.0 License](https://www.mozilla.org/en-US/MPL/2.0/).