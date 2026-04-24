A performant rendering library for displaying and manipulating custom-defined graph structures through a simple and intuitive API, that gives you maximum control over the graph's look and feel.  
It was designed from the ground up to be fully integrated with flutter's architecture.

![Preview Image](images/preview.png "Preview")

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

Add this package to your `pubspec.yaml` file:

```bash
$ flutter pub add interactive_graph_view
```

## Usage

### 1. Import the package

```dart
import "package:interactive_graph_view/interactive_graph_view.dart";
```

### 2. Create and save a `GraphViewportController` in your `StatefulWidget` and give it your graph structure's IDs

```dart
class YourWidget extends StatefulWidget {
  const YourWidget({super.key});

  @override
  State<YourWidget> createState() => _YourWidgetState();
}

class _YourWidgetState extends State<YourWidget> {
  final Map<NodeId, ExampleNode> _nodes = {
    "node-1": ExampleNode(position: (0, -75), text: "Hello"),
    "node-2": ExampleNode(position: (0, 75), text: "World"),
  };
  final Map<EdgeId, ExampleEdge> _edges = {
    "edge-1": ExampleEdge(startNodeId: "node-1", endNodeId: "node-2", text: "wonderful"),
  }

  late final GraphViewportController<String, String> _graphViewportController;

  @override
  void initState() {
    super.initState();

    _graphViewportController = GraphViewportController(
      initialNodeIds: _nodes.keys,
      initialEdgeIds: _edges.keys,
    );
  }

  // ...
}
```

### 3. Build the `GraphView` or `GraphViewport` in your widget's build() method

```dart
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
          text: node.text,
          isDragEnabled: true,
        );
      },
      edgeBuilder: (context, edgeId) {
        final ExampleEdge edge = _edges[edgeId]!;
        return EdgeWidget(
          startNodeId: edge.startNodeId,
          endNodeId: edge.endNodeId,
          text: edge.text,
        );
      },
    ),
  );
}
```

## Contributing

You are welcome to contribute to this package!

If you've got a feature request or run into a bug, please do not hesitate to open an issue in the GitHub repository. 😊

## License

This package is under the [MPL 2.0 License](https://www.mozilla.org/en-US/MPL/2.0/).