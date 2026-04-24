## 0.3.0

### New and changed

* **(BREAKING)** Replaces `maxWidth` with `contentConstraints` in `NodeStyle`.
* Adds `boundaryInsets` to `GraphView` and `GraphViewport` to keep the outermost children on screen.
* Makes the `text` parameter in `EdgeWidget` optional.
* Adds `debugPaintQuadTree` as a parameter to `GraphView` and `GraphViewport` to be able to show a debug view of the
  quad tree (the underlying data structure).
* Reworks hit testing.
* Adds `onLongPress` to `EdgeWidget`.
* Changes the fallback edge text background color to transparent.
* Updates the large example to make edge properties customizable.
* Adds a button to delete nodes and edges to the large example.

### Fixes

* Fixes multiple issues of the quad tree (the underlying data structure).
* Fixes that children were not rendered when they were larger than the viewport.
* Fixes that scaling did not work when both pointers hit the same node.
* Fixes the hairline gap that was sometimes visible between the end of an edge and its arrow.
* Fixes the thickness of edge-line shadows.
* Fixes that `GraphViewportController.removeNode()` and `GraphViewportController.removeEdge()` did nothing.

## 0.2.0

### New and changed

* **(BREAKING)** Adds custom gesture callbacks for `GraphView`, `GraphViewport`, `NodeWidget` and `EdgeWidget` and replaces the old ones.
* Reworks gesture handling and coordinate space conversions.
* Adds new big example which uses most of the features (see [`example/main.dart`](example/main.dart)).

### Fixes

* `GraphViewport` and its children now get correctly clipped.
* `GraphViewport` now correctly instantly builds newly added children.
* Fixes a crash that happened when the viewport was moved in the widget tree.
* Fixes a layout problem with edges.

## 0.1.0 - initial release

* Introduces the following widgets:
  * `GraphViewport`
  * `GraphView`
  * `NodeWidget`
  * `EdgeWidget`
* Introduces styling with:
  * `GraphStyle`
  * `NodeStyle`
  * `EdgeStyle`
* Built-in viewport panning, scaling and scrolling
* Built-in node and node group dragging