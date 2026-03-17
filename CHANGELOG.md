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