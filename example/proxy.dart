import "package:material_ui/material_ui.dart";

import "package:interactive_graph_view/interactive_graph_view.dart";

// This example demonstrates the usage of `GraphViewportProxy` for displaying `NodeWidget`s and `EdgeWidget`s
// outside of a `GraphViewport`.

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
              child: NodeWidget.basic(
                text: "Example",
                isDragEnabled: false,
              ),
            ),
          ),
          Expanded(
            child: GraphViewportProxy(
              backgroundColor: Colors.blue,
              child: EdgeWidget(),
            ),
          ),
        ],
      ),
    );
  }
}
