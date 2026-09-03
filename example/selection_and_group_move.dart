import "package:flutter/material.dart";

import "package:interactive_graph_view/interactive_graph_view.dart";

// This example shows you how you can implement selection of nodes and then being able
// to move them all at the same time.
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
      ExampleNode(id: "node2", position: Offset(50, -50)),
      ExampleNode(id: "node3", position: Offset(-50, 50)),
      ExampleNode(id: "node4", position: Offset(50, 50)),
    },
    key: (node) => node.id,
  );

  final Map<String, ExampleEdge> _edges = Map.fromIterable(
    {
      ExampleEdge(id: "edge1", startNodeId: "node1", endNodeId: "node4"),
      ExampleEdge(id: "edge2", startNodeId: "node2", endNodeId: "node3"),
    },
    key: (edge) => edge.id,
  );

  late final GraphViewportController<String, String, ExampleNode, ExampleEdge> _graphViewportController;
  late final GraphViewportTransform _graphViewportTransform;

  final Set<String> _selectedNodeIds = {};

  void _toggleNodeSelection(String nodeId) {
    setState(() {
      if (_selectedNodeIds.contains(nodeId)) {
        _selectedNodeIds.remove(nodeId);
        _nodes[nodeId]!.isSelected = false;
      } else {
        _selectedNodeIds.add(nodeId);
        _nodes[nodeId]!.isSelected = true;
      }
    });
  }

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
        movingNodeIds: _selectedNodeIds,
        onNodesMoved: (nodeIds, offset) {
          for (String nodeId in nodeIds) {
            // Reflect the dragged node offset back to the graph structure and trigger a rebuild.
            _nodes[nodeId]!.position += offset;
          }
        },
        nodeBuilder: (context, nodeId, node) {
          return NodeWidget.basic(
            text: nodeId,
            style: node.isSelected
                ? NodeStyle(
                    borderSide: BorderSide(
                      color: Colors.red,
                      width: 2.0,
                    ),
                  )
                : null,

            // Only enable dragging on selected nodes.
            isDragEnabled: node.isSelected,
            onTap: () {
              // Toggle the selection state.
              _toggleNodeSelection(nodeId);
            },
          );
        },
        edgeBuilder: (context, edgeId, edge) {
          return EdgeWidget();
        },
      ),
    );
  }
}

class ExampleNode extends DynamicGraphViewportNodeModel {
  ExampleNode({required this.id, required Offset position, bool isSelected = false})
    : _position = position,
      _isSelected = isSelected;

  final String id;

  @override
  Offset get position => _position;
  Offset _position;
  set position(Offset value) {
    if (_position == value) return;
    _position = value;
    notifyNeedsRebuild();
  }

  bool get isSelected => _isSelected;
  bool _isSelected;
  set isSelected(bool value) {
    if (_isSelected == value) return;
    _isSelected = value;
    notifyNeedsRebuild();
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
