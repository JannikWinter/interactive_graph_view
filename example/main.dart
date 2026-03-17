import "dart:math";

import "package:flutter/material.dart";
import "package:flutter/services.dart";

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
      home: const GraphViewExampleHomePage(),
      theme: ThemeData(extensions: {}),
    );
  }
}

class GraphViewExampleHomePage extends StatefulWidget {
  const GraphViewExampleHomePage({super.key});

  @override
  State<GraphViewExampleHomePage> createState() => _GraphViewExampleHomePageState();
}

class _GraphViewExampleHomePageState extends State<GraphViewExampleHomePage> {
  final Map<String, ExampleNode> _nodes = Map.fromIterable({
    ExampleNode(position: Offset(-50, -50)),
    ExampleNode(position: Offset(50, -50)),
    ExampleNode(position: Offset(-50, 50)),
    ExampleNode(position: Offset(50, 50)),
  }, key: (node) => node.id);

  late final Map<String, ExampleEdge> _edges = Map.fromIterable({
    ExampleEdge(
      startNodeId: _nodes.keys.elementAt(0),
      endNodeId: _nodes.keys.elementAt(1),
    ),
    ExampleEdge(
      startNodeId: _nodes.keys.elementAt(2),
      endNodeId: _nodes.keys.elementAt(3),
    ),
  }, key: (edge) => edge.id);

  late final GraphViewportController<String, String> _graphViewportController;

  late Offset _tapDownPosition;

  final Set<String> _selectedNodeIds = {};

  @override
  void initState() {
    super.initState();

    _graphViewportController = GraphViewportController(
      initialNodeIds: _nodes.keys,
      initialEdgeIds: _edges.keys,

      onNodesMoved: (nodeIds, offset) {
        for (String nodeId in nodeIds) {
          // Reflect the dragged node offset back to the graph structure.
          _nodes[nodeId]!.position += offset;

          // Rebuild the node at the new position.
          _graphViewportController.rebuildNode(nodeId);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Graph View Demo")),
      body: HorizontalOrVertical(
        primary: GraphView<String, String>(
          // If this is set to true, every hot-reload and every rebuild of the viewport, for example by hot-reloading
          // or calling setState() on a parent, will rebuild *all* children (nodes and edges). This is very useful for
          // during development, but should generally be set to false.
          // When set to false, only calls to GraphViewportController.rebuildNode() or .rebuildEdge() will trigger
          // child rebuilds.
          rebuildAllChildrenOnWidgetUpdate: true,

          viewportController: _graphViewportController,
          onTapDown: (details) {
            _tapDownPosition = details.graphPosition;
          },
          onTap: () {
            _clearSelection();
          },
          onDoubleTap: () {
            // Create a new node when double tapping on an empty spot.
            final String newNodeId = _createNode(_tapDownPosition);

            // Create a new edge from each currently selected node to
            // the newly created node.
            for (final String selectedNodeId in _selectedNodeIds) {
              _createEdge(selectedNodeId, newNodeId);
            }

            // Clear the selection.
            _clearSelection();
          },
          nodeBuilder: (context, nodeId) {
            final bool isSelected = _selectedNodeIds.contains(nodeId);
            final ExampleNode node = _nodes[nodeId]!;

            return NodeWidget.basic(
              position: node.position,
              text: node.text,
              style:
                  (isSelected
                          ? NodeStyle(
                              borderSide: BorderSide(
                                color: Colors.red,
                                width: 2.0,
                              ),
                            )
                          : NodeStyle())
                      .merge(node.style),

              // Only enable dragging if the node is selected.
              isDragEnabled: isSelected,

              onTap: () {
                // Select this node, unselect all others.
                _singleSelectNode(nodeId);
              },
              onLongPress: () {
                // Toggle the selection state.
                _toggleNodeSelection(nodeId);
              },
              onDoubleTap: () {
                // Create an edge from each currently selected node to this node.

                // Do not create edges if the node is source and target.
                if (_selectedNodeIds.contains(nodeId)) return;
                // Do not create edges if no node is selected.
                if (_selectedNodeIds.isEmpty) return;

                // Create the edges.
                for (final String selectedNodeId in _selectedNodeIds) {
                  _createEdge(selectedNodeId, nodeId);
                }

                // Clear selection.
                _clearSelection();
              },
            );
          },
          edgeBuilder: (context, edgeId) {
            final ExampleEdge edge = _edges[edgeId]!;

            return EdgeWidget(
              startNodeId: edge.startNodeId,
              endNodeId: edge.endNodeId,
              text: null,
            );
          },
        ),
        secondary: PropertiesPanel(
          selectedNodeIds: _selectedNodeIds,
          nodes: _nodes,
          graphViewportController: _graphViewportController,
        ),
      ),
    );
  }

  void _toggleNodeSelection(String nodeId) {
    if (_selectedNodeIds.contains(nodeId)) {
      _selectedNodeIds.remove(nodeId);
    } else {
      _selectedNodeIds.add(nodeId);
    }

    // Trigger rebuild to update the properties panel
    setState(() {});

    // Tell the viewport, which nodes should move when dragging a drag-enabled node.
    _graphViewportController.movingNodeIds = _selectedNodeIds;
  }

  void _singleSelectNode(String nodeId) {
    _clearSelection();
    _selectedNodeIds.add(nodeId);

    // Tell the viewport, which nodes should move when dragging a drag-enabled node.
    _graphViewportController.movingNodeIds = _selectedNodeIds;
  }

  void _clearSelection() {
    for (final String selectedNodeId in _selectedNodeIds) {
      _graphViewportController.rebuildNode(selectedNodeId);
    }
    _selectedNodeIds.clear();

    // Trigger rebuild to update the properties panel
    setState(() {});

    // Tell the viewport, which nodes should move when dragging a drag-enabled node.
    _graphViewportController.movingNodeIds = _selectedNodeIds;
  }

  String _createNode(Offset position) {
    final ExampleNode newNode = ExampleNode(position: _tapDownPosition);
    _nodes[newNode.id] = newNode;
    _graphViewportController.insertNode(newNode.id);

    return newNode.id;
  }

  String _createEdge(String startNodeId, String endNodeId) {
    final ExampleEdge newEdge = ExampleEdge(
      startNodeId: startNodeId,
      endNodeId: endNodeId,
    );
    _edges[newEdge.id] = newEdge;
    _graphViewportController.insertEdge(newEdge.id);

    return newEdge.id;
  }
}

class ExampleNode {
  ExampleNode({
    String? id,
    required this.position,
    String? text,
    NodeStyle? style,
  }) : id = id ?? _newRandomId(),
       style = style ?? const NodeStyle() {
    this.text = text ?? this.id;
  }

  final String id;

  Offset position;

  late String text;
  NodeStyle style;
}

class ExampleEdge {
  ExampleEdge({String? id, required this.startNodeId, required this.endNodeId}) : id = id ?? _newRandomId();

  final String id;

  String startNodeId;
  String endNodeId;
}

// =============================
// ========== HELPERS ==========
// =============================

final Random _random = Random();
final String idCharSet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
String _newRandomId({int length = 8}) {
  String result = "";
  for (int i = 0; i < length; i++) {
    result += idCharSet[_random.nextInt(idCharSet.length)];
  }
  return result;
}

class PropertiesPanel extends StatelessWidget {
  const PropertiesPanel({
    super.key,
    required Set<String> selectedNodeIds,
    required Map<String, ExampleNode> nodes,
    required GraphViewportController<String, String> graphViewportController,
  }) : _selectedNodeIds = selectedNodeIds,
       _nodes = nodes,
       _graphViewportController = graphViewportController;

  final Set<String> _selectedNodeIds;
  final Map<String, ExampleNode> _nodes;
  final GraphViewportController<String, String> _graphViewportController;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        inputDecorationTheme: InputDecorationThemeData(
          border: OutlineInputBorder(),
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Builder(
            builder: (context) {
              if (_selectedNodeIds.length != 1) {
                return Center(
                  child: Text(
                    "Please select a single node to change its properties",
                  ),
                );
              }

              final String nodeId = _selectedNodeIds.single;
              final ExampleNode node = _nodes[nodeId]!;

              return Column(
                key: ValueKey("property-panel-$nodeId"),
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text("Node $nodeId"),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(labelText: "Text"),
                    initialValue: node.text,
                    onChanged: (value) {
                      node.text = value;
                      _graphViewportController.rebuildNode(nodeId);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Color>(
                    decoration: InputDecoration(labelText: "BackgroundColor"),
                    items: [
                      DropdownMenuItem(child: Text("None")),
                      ...[Colors.black, Colors.white, ...Colors.primaries].map(
                        (color) => DropdownMenuItem(
                          value: color,
                          child: Container(
                            color: color,
                            child: Text(
                              "#${color.toARGB32().toRadixString(16)}",
                            ),
                          ),
                        ),
                      ),
                    ],
                    initialValue: node.style.backgroundColor,
                    onChanged: (value) {
                      node.style = node.style.copyWith(
                        backgroundColor: Nullable(value),
                      );
                      _graphViewportController.rebuildNode(nodeId);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Color>(
                    decoration: InputDecoration(labelText: "Text Color"),
                    items: [
                      DropdownMenuItem(child: Text("None")),
                      ...[Colors.black, Colors.white, ...Colors.primaries].map(
                        (color) => DropdownMenuItem(
                          value: color,
                          child: Container(
                            color: color,
                            child: Text(
                              "#${color.toARGB32().toRadixString(16)}",
                            ),
                          ),
                        ),
                      ),
                    ],
                    initialValue: node.style.textStyle.color,
                    onChanged: (value) {
                      node.style = node.style.copyWith(
                        textStyle: node.style.textStyle.copyWith(color: value),
                      );
                      _graphViewportController.rebuildNode(nodeId);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(labelText: "Border radius"),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    initialValue: (node.style.borderRadius != null)
                        ? node.style.borderRadius!.x.toInt().toString()
                        : "",
                    onChanged: (value) {
                      node.style = node.style.copyWith(
                        borderRadius: Nullable(
                          value.isEmpty ? null : Radius.circular(double.parse(value)),
                        ),
                      );
                      _graphViewportController.rebuildNode(nodeId);
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class HorizontalOrVertical extends StatelessWidget {
  const HorizontalOrVertical({
    super.key,
    required this.primary,
    required this.secondary,
  });

  final Widget primary;
  final Widget secondary;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);

    if (size.width >= size.height) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: primary),
          SizedBox(width: size.width / 5, child: secondary),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: primary),
          SizedBox(height: size.height / 3, child: secondary),
        ],
      );
    }
  }
}
