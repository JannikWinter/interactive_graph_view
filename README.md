`interactive_graph_view` is a performant rendering library for displaying and manipulating custom-defined graph structures through a simple and intuitive API, that gives you maximum control over the graph's look and feel.  
It was designed from the ground up to be fully integrated with flutter's architecture.


## Features

- Custom graph viewport, node and edge widgets
- Children arre built lazily (only when necessary)
- Built-in panning, scaling and scrolling of the viewport
- Built-in dragging of one or multiple nodes
- Custom styling
- Flutter `Theme` integration
- Intuitive API
- Graph-structure-agnnostic: You can define your own types and classes for the graph-structure - the package only knows of the IDs 

## Getting started

1. Add this package to your `pubspec.yaml` file:
```bash
$ flutter pub add interactive_graph_view
```

2. Import it:
```dart
import "package:interactive_graph_view/interactive_graph_view.dart";
```

## Usage

This is a simple example for displaying 2 nodes and a connecting edge. You can also drag each node around.
More complex examples using more features can be found in the `examples/` folder.

```dart
import "package:flutter/material.dart";
import "package:interactive_graph_view/interactive_graph_view.dart";

// [ExampleNode] and [ExampleEdge] are custom defined types - you have all the freedom
// to define your own graph structure.
// The viewport never knows of these classes. It is just important, that nodes and edges
// can be identified by an ID and you tell the viewport about those.
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

  // With the [GraphViewportController] you can modify the graph - e.g. add or remove a node.
  // The generic type parameters (<String, String>) define the type of the node IDs and edge IDs,
  // which are both using [String].
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
      
      // [GraphView] constructs the viewport and already gives you built-in panning, scaling,
      // scrolling and dragging of nodes.
      // Just like in the [GraphViewportController], the generic type parameters (<String, String>)
      // define the type of the node IDs and edge IDs, which are both using [String].
      body: GraphView<String, String>(
        viewportController: _graphViewportController,
        nodeBuilder: (context, nodeId) {
          return NodeWidget.basic(
            position: _nodes[nodeId]!.position,
            text: nodeId,
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

If you've got a feature request or run into a bug, please do not hesitate to open an issue in the GitHub repository. 😊

## License

This package is under the [MPL 2.0 License](https://www.mozilla.org/en-US/MPL/2.0/).