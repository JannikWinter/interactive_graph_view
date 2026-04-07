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
      theme: ThemeData(
        extensions: {
          GraphStyle(backgroundColor: Colors.blue.shade900),
          NodeStyle(
            backgroundColor: Colors.blue.shade100,
            textStyle: TextStyle(color: Colors.blue.shade900),
            borderRadius: Radius.circular(5),
          ),
          EdgeStyle(
            arrowStyle: ArrowStyle(length: 8, width: 12),
            lineStyle: SolidLineStyle(thickness: 2),
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
  final Set<String> _selectedEdgeIds = {};

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
                // Select this node, deselect everything else.
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
            final bool isSelected = _selectedEdgeIds.contains(edgeId);
            final ExampleEdge edge = _edges[edgeId]!;

            return EdgeWidget(
              startNodeId: edge.startNodeId,
              endNodeId: edge.endNodeId,
              text: edge.showText ? edge.text : null,
              onTap: () {
                // Select this node, deselect everything else.
                _singleSelectEdge(edgeId);
              },
              onLongPress: () {
                // Toggle the selection state.
                _toggleEdgeSelection(edgeId);
              },
              style:
                  (isSelected
                          ? EdgeStyle(
                              shadow: [
                                LineShadow(
                                  color: Colors.red,
                                  blurRadius: 0,
                                  spreadRadius: 1.5,
                                ),
                              ],
                            )
                          : EdgeStyle())
                      .merge(edge.style),
            );
          },
        ),
        secondary: PropertiesPanel(
          selectedNodeIds: _selectedNodeIds,
          selectedEdgeIds: _selectedEdgeIds,
          nodes: _nodes,
          edges: _edges,
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

  void _toggleEdgeSelection(String edgeId) {
    if (_selectedEdgeIds.contains(edgeId)) {
      _selectedEdgeIds.remove(edgeId);
    } else {
      _selectedEdgeIds.add(edgeId);
    }

    // Trigger rebuild to update the properties panel
    setState(() {});
  }

  void _singleSelectEdge(String edgeId) {
    _clearSelection();
    _selectedEdgeIds.add(edgeId);
  }

  void _clearSelection() {
    for (final String selectedNodeId in _selectedNodeIds) {
      _graphViewportController.rebuildNode(selectedNodeId);
    }
    for (final String selectedEdgeId in _selectedEdgeIds) {
      _graphViewportController.rebuildEdge(selectedEdgeId);
    }
    _selectedNodeIds.clear();
    _selectedEdgeIds.clear();

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
  ExampleEdge({
    String? id,
    required this.startNodeId,
    required this.endNodeId,
    this.showText = false,
    this.text = "",
    EdgeStyle? style,
  }) : id = id ?? _newRandomId(),
       style = style ?? const EdgeStyle();

  final String id;

  String startNodeId;
  String endNodeId;

  bool showText;
  String text;

  EdgeStyle style;
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
    required Set<String> selectedEdgeIds,
    required Map<String, ExampleNode> nodes,
    required Map<String, ExampleEdge> edges,
    required GraphViewportController<String, String> graphViewportController,
  }) : _selectedNodeIds = selectedNodeIds,
       _selectedEdgeIds = selectedEdgeIds,
       _nodes = nodes,
       _edges = edges,
       _graphViewportController = graphViewportController;

  final Set<String> _selectedNodeIds;
  final Set<String> _selectedEdgeIds;
  final Map<String, ExampleNode> _nodes;
  final Map<String, ExampleEdge> _edges;
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
              if (_selectedNodeIds.length == 1 && _selectedEdgeIds.isEmpty) {
                final String nodeId = _selectedNodeIds.single;
                final ExampleNode node = _nodes[nodeId]!;

                return Column(
                  key: ValueKey("node-properties-$nodeId"),
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
                      decoration: InputDecoration(labelText: "Background Color"),
                      items: [
                        DropdownMenuItem(child: Text("None (use fallback)")),
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
                        DropdownMenuItem(child: Text("None (use fallback)")),
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
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
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
              } else if (_selectedEdgeIds.length == 1 && _selectedNodeIds.isEmpty) {
                final String edgeId = _selectedEdgeIds.single;
                final ExampleEdge edge = _edges[edgeId]!;

                return Column(
                  key: ValueKey("edge-properties-$edgeId"),
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text("Edge $edgeId"),
                    const SizedBox(height: 16),
                    StatefulBuilder(
                      builder: (context, setState) {
                        void onTapShowText() {
                          setState(() {
                            edge.showText = !edge.showText;
                          });
                          _graphViewportController.rebuildEdge(edgeId);
                        }

                        return Column(
                          children: [
                            GestureDetector(
                              onTap: onTapShowText,
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: edge.showText,
                                    onChanged: (value) => onTapShowText(),
                                  ),
                                  Expanded(child: Text("Show Text")),
                                ],
                              ),
                            ),
                            TextFormField(
                              enabled: edge.showText,
                              decoration: InputDecoration(labelText: "Text"),
                              initialValue: edge.text,
                              onChanged: (value) {
                                edge.text = value;
                                _graphViewportController.rebuildEdge(edgeId);
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<Color>(
                              decoration: InputDecoration(labelText: "Text Background Color"),
                              items: [
                                DropdownMenuItem(child: Text("None (use fallback)")),
                                DropdownMenuItem(
                                  value: Colors.transparent,
                                  child: Text("Transparent"),
                                ),
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
                              initialValue: edge.style.textBackgroundColor,
                              onChanged: edge.showText
                                  ? (value) {
                                      edge.style = edge.style.copyWith(
                                        textBackgroundColor: Nullable(value),
                                      );
                                      _graphViewportController.rebuildEdge(edgeId);
                                    }
                                  : null,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Color>(
                      decoration: InputDecoration(labelText: "Line Color"),
                      items: [
                        DropdownMenuItem(child: Text("None (use fallback)")),
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
                      initialValue: edge.style.lineColor,
                      onChanged: (value) {
                        edge.style = edge.style.copyWith(
                          lineColor: Nullable(value),
                        );
                        _graphViewportController.rebuildEdge(edgeId);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<LineStyle>(
                      decoration: InputDecoration(labelText: "Line Style"),
                      items: [
                        DropdownMenuItem(child: Text("None (use fallback)")),
                        DropdownMenuItem(
                          value: SolidLineStyle(thickness: 3),
                          child: Text("Solid"),
                        ),
                        DropdownMenuItem(
                          value: DashedLineStyle(thickness: 3, dashSize: 8, gapSize: 4),
                          child: Text("Dashed"),
                        ),
                        DropdownMenuItem(
                          value: DottedLineStyle(thickness: 3),
                          child: Text("Dotted"),
                        ),
                      ],
                      initialValue: edge.style.lineStyle,
                      onChanged: (value) {
                        edge.style = edge.style.copyWith(
                          lineStyle: Nullable(value),
                        );
                        _graphViewportController.rebuildEdge(edgeId);
                      },
                    ),
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        double arrowWidth = edge.style.arrowStyle?.width ?? 10;
                        double arrowLength = edge.style.arrowStyle?.length ?? 10;

                        return StatefulBuilder(
                          builder: (context, setState) {
                            void onTapOverrideArrowStyle() {
                              setState(() {
                                if (edge.style.arrowStyle == null) {
                                  edge.style = edge.style.copyWith(
                                    arrowStyle: Nullable(ArrowStyle(width: arrowWidth, length: arrowLength)),
                                  );
                                } else {
                                  edge.style = edge.style.copyWith(arrowStyle: Nullable(null));
                                }
                              });
                              _graphViewportController.rebuildEdge(edgeId);
                            }

                            return Column(
                              children: [
                                GestureDetector(
                                  onTap: onTapOverrideArrowStyle,
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: edge.style.arrowStyle != null,
                                        onChanged: (value) => onTapOverrideArrowStyle(),
                                      ),
                                      Expanded(child: Text("Override arrow style")),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        enabled: edge.style.arrowStyle != null,
                                        decoration: InputDecoration(label: Text("Arrow width")),
                                        initialValue: arrowWidth.toInt().toString(),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          LengthLimitingTextInputFormatter(2),
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            arrowWidth = double.tryParse(value) ?? 0;
                                            edge.style = edge.style.copyWith(
                                              arrowStyle: Nullable(edge.style.arrowStyle!.copyWith(width: arrowWidth)),
                                            );
                                            _graphViewportController.rebuildEdge(edgeId);
                                          });
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: TextFormField(
                                        enabled: edge.style.arrowStyle != null,
                                        decoration: InputDecoration(label: Text("Arrow length")),
                                        initialValue: arrowLength.toInt().toString(),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          LengthLimitingTextInputFormatter(2),
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            arrowLength = double.tryParse(value) ?? 0;
                                            edge.style = edge.style.copyWith(
                                              arrowStyle: Nullable(
                                                edge.style.arrowStyle!.copyWith(length: arrowLength),
                                              ),
                                            );
                                            _graphViewportController.rebuildEdge(edgeId);
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                );
              } else {
                return Center(
                  child: Text(
                    "Please select a single node or edge to change its properties",
                  ),
                );
              }
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
