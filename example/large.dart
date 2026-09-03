import "dart:math";

import "package:flutter/material.dart";

import "package:interactive_graph_view/interactive_graph_view.dart";

import "large/horizontal_or_vertical.dart";
import "large/properties_panel.dart";

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

class _GraphViewExampleHomePageState extends State<GraphViewExampleHomePage> with TickerProviderStateMixin {
  static const NodeStyle _selectedNodeStyle = NodeStyle(
    borderSide: BorderSide(color: Colors.red, width: 2.0),
  );
  static const EdgeStyle _selectedEdgeStyle = EdgeStyle(
    shadow: [LineShadow(color: Colors.red, blurRadius: 0, spreadRadius: 1.5)],
  );

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

  late final GraphViewportController<String, String, ExampleNode, ExampleEdge> _graphViewportController;
  late final GraphViewportTransform _graphViewportTransform;

  late Offset _tapDownPosition;

  final Set<String> _selectedNodeIds = {};
  final Set<String> _selectedEdgeIds = {};

  @override
  void initState() {
    super.initState();

    _graphViewportController = GraphViewportController(
      initialNodes: _nodes,
      initialEdges: _edges,
    );
    _graphViewportTransform = GraphViewportTransform(vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Graph View Demo"),
      ),
      body: HorizontalOrVertical(
        primary: GraphViewport<String, String, ExampleNode, ExampleEdge>(
          controller: _graphViewportController,
          transform: _graphViewportTransform,
          movingNodeIds: _selectedNodeIds,
          onNodesMoved: (nodeIds, offset) {
            for (String nodeId in nodeIds) {
              // Reflect the dragged node offset back to the graph structure.
              _nodes[nodeId]!.position += offset;
            }
          },
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
          nodeBuilder: (context, nodeId, node) {
            final bool isSelected = _selectedNodeIds.contains(nodeId);
            final ExampleNode node = _nodes[nodeId]!;

            return NodeWidget.basic(
              text: node.text,
              style: (isSelected ? _selectedNodeStyle : NodeStyle()).merge(
                NodeStyle(
                  backgroundColor: node.backgroundColor,
                  borderRadius: node.borderRadius,
                  textStyle: TextStyle(color: node.textColor),
                ),
              ),

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
          edgeBuilder: (context, edgeId, edge) {
            final bool isSelected = _selectedEdgeIds.contains(edgeId);
            final ExampleEdge edge = _edges[edgeId]!;

            return EdgeWidget(
              text: edge.showText ? edge.text : null,
              onTap: () {
                // Select this node, deselect everything else.
                _singleSelectEdge(edgeId);
              },
              onLongPress: () {
                // Toggle the selection state.
                _toggleEdgeSelection(edgeId);
              },
              style: (isSelected ? _selectedEdgeStyle : EdgeStyle()).merge(
                EdgeStyle(
                  arrowStyle: edge.overrideArrowStyle
                      ? ArrowStyle(
                          width: edge.arrowWidth,
                          length: edge.arrowLength,
                        )
                      : null,
                  lineStyle: edge.lineStyle,
                  lineColor: edge.lineColor,
                  textBackgroundColor: edge.textBackgroundColor,
                  textStyle: TextStyle(color: edge.textColor),
                ),
              ),
            );
          },
        ),
        secondary: PropertiesPanel(
          selectedNodes: _selectedNodeIds.map((nodeId) => _nodes[nodeId]!).toSet(),
          selectedEdges: _selectedEdgeIds.map((edgeId) => _edges[edgeId]!).toSet(),
          onDeleteNode: (nodeId) {
            _deleteNode(nodeId);
          },
          onDeleteEdge: (edgeId) {
            _deleteEdge(edgeId);
          },
          onNodeTextChanged: (nodeId, text) => _nodes[nodeId]!.text = text,
          onNodeBackgroundColorChanged: (nodeId, backgroundColor) => _nodes[nodeId]!.backgroundColor = backgroundColor,
          onNodeTextColorChanged: (nodeId, textColor) => _nodes[nodeId]!.textColor = textColor,
          onNodeBorderRadiusChanged: (nodeId, borderRadius) => _nodes[nodeId]!.borderRadius = borderRadius,
          onEdgeShowTextChanged: (edgeId, showText) => _edges[edgeId]!.showText = showText,
          onEdgeTextChanged: (edgeId, text) => _edges[edgeId]!.text = text,
          onEdgeTextBackgroundColorChanged: (edgeId, textBackgroundColor) =>
              _edges[edgeId]!.textBackgroundColor = textBackgroundColor,
          onEdgeTextColorChanged: (edgeId, textColor) => _edges[edgeId]!.textColor = textColor,
          onEdgeLineColorChanged: (edgeId, lineColor) => _edges[edgeId]!.lineColor = lineColor,
          onEdgeLineStyleChanged: (edgeId, lineStyle) => _edges[edgeId]!.lineStyle = lineStyle,
          onEdgeOverrideArrowStyleChanged: (edgeId, overrideArrowStyle) =>
              _edges[edgeId]!.overrideArrowStyle = overrideArrowStyle,
          onEdgeArrowChanged: (edgeId, arrowWidth, arrowLength) => _edges[edgeId]!
            ..arrowWidth = arrowWidth
            ..arrowLength = arrowLength,
        ),
      ),
    );
  }

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

  void _singleSelectNode(String nodeId) {
    setState(() {
      _clearSelection();
      _selectedNodeIds.add(nodeId);
      _nodes[nodeId]!.isSelected = true;
    });
  }

  void _toggleEdgeSelection(String edgeId) {
    setState(() {
      if (_selectedEdgeIds.contains(edgeId)) {
        _selectedEdgeIds.remove(edgeId);
        _edges[edgeId]!.isSelected = false;
      } else {
        _selectedEdgeIds.add(edgeId);
        _edges[edgeId]!.isSelected = true;
      }
    });
  }

  void _singleSelectEdge(String edgeId) {
    setState(() {
      _clearSelection();
      _selectedEdgeIds.add(edgeId);
      _edges[edgeId]!.isSelected = true;
    });
  }

  void _clearSelection() {
    for (final String selectedNodeId in _selectedNodeIds) {
      _nodes[selectedNodeId]!.isSelected = false;
    }
    for (final String selectedEdgeId in _selectedEdgeIds) {
      _edges[selectedEdgeId]!.isSelected = false;
    }

    setState(() {
      _selectedNodeIds.clear();
      _selectedEdgeIds.clear();
    });
  }

  String _createNode(Offset position) {
    final ExampleNode newNode = ExampleNode(position: _tapDownPosition);
    _nodes[newNode.id] = newNode;
    _graphViewportController.setNode(newNode.id, newNode);

    return newNode.id;
  }

  String _createEdge(String startNodeId, String endNodeId) {
    final ExampleEdge newEdge = ExampleEdge(
      startNodeId: startNodeId,
      endNodeId: endNodeId,
    );
    _edges[newEdge.id] = newEdge;
    _graphViewportController.setEdge(newEdge.id, newEdge);

    return newEdge.id;
  }

  void _deleteNode(String nodeId) {
    final Set<String> connectedEdgeIds = _edges.values
        .where((edge) => edge.startNodeId == nodeId || edge.endNodeId == nodeId)
        .map((edge) => edge.id)
        .toSet();
    for (final String connectedEdgeId in connectedEdgeIds) {
      _deleteEdge(connectedEdgeId);
    }

    _nodes.remove(nodeId);
    _graphViewportController.removeNode(nodeId);

    setState(() {
      _selectedNodeIds.remove(nodeId);
    });
  }

  void _deleteEdge(String edgeId) {
    _edges.remove(edgeId);
    _graphViewportController.removeEdge(edgeId);

    setState(() {
      _selectedEdgeIds.remove(edgeId);
    });
  }
}

class ExampleNode extends DynamicGraphViewportNodeModel {
  ExampleNode({
    String? id,
    required Offset position,
    String? text,
    Color? backgroundColor,
    Color? textColor,
    Radius? borderRadius,
    bool isSelected = false,
  }) : id = id ?? _newRandomId(),
       _position = position,
       _backgroundColor = backgroundColor,
       _textColor = textColor,
       _borderRadius = borderRadius,
       _isSelected = isSelected {
    _text = text ?? this.id;
  }

  final String id;

  @override
  Offset get position => _position;
  Offset _position;
  set position(Offset value) {
    if (_position == value) return;
    _position = value;
    notifyNeedsRebuild();
  }

  String get text => _text;
  late String _text;
  set text(String value) {
    if (_text == value) return;
    _text = value;
    notifyNeedsRebuild();
  }

  Color? get backgroundColor => _backgroundColor;
  Color? _backgroundColor;
  set backgroundColor(Color? value) {
    if (_backgroundColor == value) return;
    _backgroundColor = value;
    notifyNeedsRebuild();
  }

  Color? get textColor => _textColor;
  Color? _textColor;
  set textColor(Color? value) {
    if (_textColor == value) return;
    _textColor = value;
    notifyNeedsRebuild();
  }

  Radius? get borderRadius => _borderRadius;
  Radius? _borderRadius;
  set borderRadius(Radius? value) {
    if (_borderRadius == value) return;
    _borderRadius = value;
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

class ExampleEdge extends DynamicGraphViewportEdgeModel<String> {
  ExampleEdge({
    String? id,
    required this.startNodeId,
    required this.endNodeId,
    bool showText = false,
    String text = "",
    Color? textBackgroundColor,
    Color? textColor,
    Color? lineColor,
    LineStyle? lineStyle,
    bool overrideArrowStyle = false,
    double arrowWidth = 10,
    double arrowLength = 10,
    bool isSelected = false,
  }) : id = id ?? _newRandomId(),
       _showText = showText,
       _text = text,
       _textBackgroundColor = textBackgroundColor,
       _textColor = textColor,
       _lineColor = lineColor,
       _lineStyle = lineStyle,
       _overrideArrowStyle = overrideArrowStyle,
       _arrowWidth = arrowWidth,
       _arrowLength = arrowLength,
       _isSelected = isSelected;

  final String id;

  @override
  final String startNodeId;

  @override
  final String endNodeId;

  bool get showText => _showText;
  bool _showText;
  set showText(bool value) {
    if (_showText == value) return;
    _showText = value;
    notifyNeedsRebuild();
  }

  String get text => _text;
  String _text;
  set text(String value) {
    if (_text == value) return;
    _text = value;
    notifyNeedsRebuild();
  }

  Color? get textBackgroundColor => _textBackgroundColor;
  Color? _textBackgroundColor;
  set textBackgroundColor(Color? value) {
    if (_textBackgroundColor == value) return;
    _textBackgroundColor = value;
    notifyNeedsRebuild();
  }

  Color? get textColor => _textColor;
  Color? _textColor;
  set textColor(Color? value) {
    if (_textColor == value) return;
    _textColor = value;
    notifyNeedsRebuild();
  }

  Color? get lineColor => _lineColor;
  Color? _lineColor;
  set lineColor(Color? value) {
    if (_lineColor == value) return;
    _lineColor = value;
    notifyNeedsRebuild();
  }

  LineStyle? get lineStyle => _lineStyle;
  LineStyle? _lineStyle;
  set lineStyle(LineStyle? value) {
    if (_lineStyle == value) return;
    _lineStyle = value;
    notifyNeedsRebuild();
  }

  bool get overrideArrowStyle => _overrideArrowStyle;
  bool _overrideArrowStyle;
  set overrideArrowStyle(bool value) {
    if (_overrideArrowStyle == value) return;
    _overrideArrowStyle = value;
    notifyNeedsRebuild();
  }

  double get arrowWidth => _arrowWidth;
  double _arrowWidth;
  set arrowWidth(double value) {
    if (_arrowWidth == value) return;
    _arrowWidth = value;
    notifyNeedsRebuild();
  }

  double get arrowLength => _arrowLength;
  double _arrowLength;
  set arrowLength(double value) {
    if (_arrowLength == value) return;
    _arrowLength = value;
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
