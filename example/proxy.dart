import "package:flutter/material.dart";

import "package:interactive_graph_view/interactive_graph_view.dart";

// TODO: Explain here, what this proxy example includes

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

class GraphViewExampleHomePage extends StatelessWidget {
  const GraphViewExampleHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Graph View Demo"),
      ),
      body: Column(
        children: [
          Expanded(
            child: GraphViewportProxy(
              child: NodeWidget.basic(text: "Hallo", isDragEnabled: false),
            ),
          ),
          Expanded(child: GraphViewportProxy(child: EdgeWidget())),
        ],
      ),
    );
  }
}
