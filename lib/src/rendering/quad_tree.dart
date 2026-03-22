import "dart:math";

import "package:flutter/material.dart" show Colors;
import "package:flutter/rendering.dart";

import "../util/extensions.dart";

/// A range of indices in a single dimension.
///
/// Both [start] and [end] are inclusive.
///
/// [start] will always be smaller than or equal to [end].
typedef _IndexRange = ({int start, int end});

/// A range of indices in two dimensions.
///
/// See also:
/// * [_IndexRange]
typedef _IndexRange2D = ({_IndexRange horizontal, _IndexRange vertical});

/// A single index for any quad tree inside [QuadTree].
typedef _Index = (int, int);

class QuadTree<NodeIdType, EdgeIdType> {
  /// Creates a `QuadTree` from the size of the innermost (smallest subdivided) quad trees.
  ///
  /// The [rootQuadTreeDimension] is calculated from: [innermostDimension] * (2 ^ ([subdivisionSteps]))
  QuadTree.fromInnermostQTSize({
    required this.innermostDimension,
    required this.subdivisionSteps,
  }) : assert(innermostDimension >= 10),
       assert(subdivisionSteps >= 0),
       assert(innermostDimension * pow(2, subdivisionSteps) >= 1000),
       rootQuadTreeDimension = innermostDimension * pow(2, subdivisionSteps);

  /// Creates a `QuadTree` from the size of the root quad trees.
  ///
  /// The [innermostDimension] is calculated from: [rootQuadTreeDimension] / (2 ^ ([subdivisionSteps]))
  QuadTree.fromRootQTSize({
    required this.rootQuadTreeDimension,
    required this.subdivisionSteps,
  }) : assert(rootQuadTreeDimension >= 1000),
       assert(subdivisionSteps >= 0),
       innermostDimension = rootQuadTreeDimension / pow(2, subdivisionSteps);

  /// The size in pixels for each dimension of each root quad tree inside this [QuadTree].
  final double rootQuadTreeDimension;

  /// The size of the smallest possible size after subdivision.
  final double innermostDimension;

  /// The maximum number of times a root quad tree can be subdivided.
  final int subdivisionSteps;

  /// The mapping of all active root quad trees by their index.
  ///
  /// The root quad tree with index `(0, 0)` will have its center at `(0, 0)` and span a square from
  /// -[rootQuadTreeDimension] / 2 to +[rootQuadTreeDimension] / 2 in each dimension.
  final Map<_Index, _QT<NodeIdType, EdgeIdType>> _rootQuadTrees = {};

  /// The mapping of all managed node IDs to their containing root quad trees.
  ///
  /// See also:
  /// * [_rootQuadTrees], which contains all the active root quad trees.
  /// * [_allChildNodes], which contains the bounding rects of all the managed nodes.
  /// * [_edgeIdToIndex], which is the mapping of all managed edge IDs to theiri containing root quad trees.
  final Map<NodeIdType, Set<_Index>> _nodeIdToIndex = {};

  /// The mapping of all managed edge IDs to their containing root quad trees.
  ///
  /// See also:
  /// * [_rootQuadTrees], which contains all the active root quad trees.
  /// * [_allChildEdges], which contains the defining paths of all the managed edges.
  /// * [_nodeIdToIndex], which is the mapping of all managed node IDs to theiri containing root quad trees.
  final Map<EdgeIdType, Set<_Index>> _edgeIdToIndex = {};

  /// The rect spanning over all nodes and edges managed by this `QuadTree`.
  ///
  /// See also:
  /// * [_allChildNodes], which contains the bounding rects of all the managed nodes.
  /// * [_allChildEdges], which contains the defining paths of all the managed edges.
  Rect? _contentRect;

  /// The collection of all child nodes managed by this `QuadTree`.
  ///
  /// Maps a node's ID to its bounding [Rect].
  ///
  /// See also:
  /// * [_allChildEdges], which contains the defining paths of all the managed edges.
  final Map<NodeIdType, Rect> _allChildNodes = {};

  /// The collection of all child edges managed by this `QuadTree`.
  ///
  /// Maps an edge's ID to its defining [Path].
  ///
  /// See also:
  /// * [_allChildEdges], which contains the defining paths of all the managed edges.
  final Map<EdgeIdType, Path> _allChildEdges = {};

  /// Paints this `QuadTree`'s debug view into the given painting [context] at the given [offset].
  void debugPaint(PaintingContext context, Offset offset) {
    for (final qt in _rootQuadTrees.values) {
      qt.debugPaint(context, offset);
    }
  }

  /// Compute the range of quad tree indices, that a given [rect] spans.
  ///
  /// Note that in the result, both [_IndexRange.start] and [_IndexRange.end] are inclusive for both dimensions.
  _IndexRange2D _computeIndexRange(Rect rect) {
    return (
      horizontal: (
        start: (rect.left / rootQuadTreeDimension).round(),
        end: (rect.right / rootQuadTreeDimension).round(),
      ),
      vertical: (
        start: (rect.top / rootQuadTreeDimension).round(),
        end: (rect.bottom / rootQuadTreeDimension).round(),
      ),
    );
  }

  /// Get the root quad tree at the given [index].
  ///
  /// If no root quad tree exists at the given [index] and [create] is set to `true`, create and return a new one at
  /// that index.
  /// Otherwise, return `null`.
  _QT<NodeIdType, EdgeIdType>? _getQTForIndex(_Index index, {required bool create}) {
    if (!_rootQuadTrees.containsKey(index) && create) {
      _rootQuadTrees[index] = _QT(
        Rect.fromCenter(
          center: Offset(index.$1.toDouble(), index.$2.toDouble()) * rootQuadTreeDimension,
          width: rootQuadTreeDimension,
          height: rootQuadTreeDimension,
        ),
        innermostDimension,
      );
    }

    return _rootQuadTrees[index];
  }

  /// Add or replace the node identified by [nodeId] with the given [rect].
  ///
  /// Returns immediately, if the given rect is the same as the rect of the managed node.
  /// Otherwise, the node is removed from all quad trees and re-added to the correct ones for the new [rect].
  void putNode(NodeIdType nodeId, Rect rect) {
    if (_allChildNodes[nodeId] == rect) return;
    assert(rect.isNotEmpty);

    _removeNodeImpl(nodeId, recalculateContentRect: false);

    _allChildNodes[nodeId] = rect;

    _contentRect = _contentRect?.expandToInclude(rect) ?? rect;

    if (!_nodeIdToIndex.containsKey(nodeId)) {
      _nodeIdToIndex[nodeId] = {};
    }

    final range = _computeIndexRange(rect);
    for (int x = range.horizontal.start; x <= range.horizontal.end; x++) {
      for (int y = range.vertical.start; y <= range.vertical.end; y++) {
        final index = (x, y);

        final _QT qt = _getQTForIndex(index, create: true)!;

        qt.putNode(nodeId, rect);

        _nodeIdToIndex[nodeId]!.add(index);
      }
    }
  }

  /// Add or replace the edge identified by [edgeId] with the given [path].
  ///
  /// Returns immediately, if the given path is the same as the path of the managed edge.
  /// Otherwise, the edge is removed from all quad trees and re-added to the correct ones for the new [path].
  void putEdge(EdgeIdType edgeId, Path path) {
    if (_allChildEdges[edgeId] == path) return;

    _removeEdgeImpl(edgeId, recalculateContentRect: false);

    _allChildEdges[edgeId] = path;

    _contentRect = _contentRect?.expandToInclude(path.getBounds()) ?? path.getBounds();

    if (!_edgeIdToIndex.containsKey(edgeId)) {
      _edgeIdToIndex[edgeId] = {};
    }

    final range = _computeIndexRange(path.getBounds());
    for (int x = range.horizontal.start; x <= range.horizontal.end; x++) {
      for (int y = range.vertical.start; y <= range.vertical.end; y++) {
        final index = (x, y);

        final _QT qt = _getQTForIndex(index, create: true)!;

        qt.putEdge(edgeId, path);

        _edgeIdToIndex[edgeId]!.add(index);
      }
    }
  }

  /// Remove all nodes with the given [nodeIds] from this `QuadTree`.
  void removeAllNodes(Iterable<NodeIdType> nodeIds) {
    for (final NodeIdType nodeId in nodeIds) {
      _removeNodeImpl(nodeId, recalculateContentRect: false);
    }
    _recalculateContentRect();
  }

  /// Remove all edges with the given [edgeIds] from this `QuadTree`.
  void removeAllEdges(Iterable<EdgeIdType> edgeIds) {
    for (final EdgeIdType edgeId in edgeIds) {
      _removeEdgeImpl(edgeId, recalculateContentRect: false);
    }
    _recalculateContentRect();
  }

  /// Remove the node with the given [nodeId] from this `QuadTree`.
  void removeNode(NodeIdType nodeId) {
    _removeNodeImpl(nodeId, recalculateContentRect: true);
  }

  /// Remove the node with the given [nodeId] from all quad trees.
  ///
  /// If [recalculateContentRect] is set to `true`, the content rect is recalculated after the node was removed.
  ///
  /// If there are neither nodes nor edges left in any of the containing quad trees, it is also removed.
  void _removeNodeImpl(NodeIdType nodeId, {required bool recalculateContentRect}) {
    if (!_allChildNodes.containsKey(nodeId)) return;

    for (final _Index index in _nodeIdToIndex[nodeId]!) {
      final qt = _getQTForIndex(index, create: false)!;
      qt.removeNode(nodeId);

      if (qt.isEmpty) {
        _rootQuadTrees.remove(index);
      }
    }

    _allChildNodes.remove(nodeId);
    _nodeIdToIndex.remove(nodeId);

    if (recalculateContentRect) {
      _recalculateContentRect();
    }
  }

  /// Remove the edge with the given [edgeId] from this `QuadTree`.
  void removeEdge(EdgeIdType edgeId) {
    _removeEdgeImpl(edgeId, recalculateContentRect: true);
  }

  /// Remove the edge with the given [edgeId] from all quad trees.
  ///
  /// If [recalculateContentRect] is set to `true`, the content rect is recalculated after the edge was removed.
  ///
  /// If there are neither nodes nor edges left in any of the containing quad trees, it is also removed.
  void _removeEdgeImpl(EdgeIdType edgeId, {required bool recalculateContentRect}) {
    if (!_allChildEdges.containsKey(edgeId)) return;

    for (final _Index index in _edgeIdToIndex[edgeId]!) {
      final qt = _getQTForIndex(index, create: false)!;
      qt.removeEdge(edgeId);

      if (qt.isEmpty) {
        _rootQuadTrees.remove(index);
      }
    }

    _allChildEdges.remove(edgeId);
    _edgeIdToIndex.remove(edgeId);

    if (recalculateContentRect) {
      _recalculateContentRect();
    }
  }

  /// Remove all nodes and edges, delete all root quad trees and clear the [contentRect].
  void clear() {
    _rootQuadTrees.clear();
    _nodeIdToIndex.clear();
    _edgeIdToIndex.clear();
    _allChildNodes.clear();
    _allChildEdges.clear();
    _contentRect = null;
  }

  /// Get all node IDs that are contained in the given [rect].
  ///
  /// The elements are not ordered.
  Iterable<NodeIdType> getNodeIdsInRect(Rect rect) {
    final range = _computeIndexRange(rect);

    return {
      for (int x = range.horizontal.start; x <= range.horizontal.end; x++)
        for (int y = range.vertical.start; y <= range.vertical.end; y++)
          ...(_getQTForIndex((x, y), create: false)?.getNodeIdsInRect(rect) ?? []),
    };
  }

  /// Get all edge IDs that are contained in the given [rect].
  ///
  /// The elements are not ordered.
  Iterable<EdgeIdType> getEdgeIdsInRect(Rect rect) {
    final range = _computeIndexRange(rect);

    return {
      for (int x = range.horizontal.start; x <= range.horizontal.end; x++)
        for (int y = range.vertical.start; y <= range.vertical.end; y++)
          ...(_getQTForIndex((x, y), create: false)?.getEdgeIdsInRect(rect) ?? []),
    };
  }

  /// Recalculate the [contentRect] that spans over all children.
  void _recalculateContentRect() {
    if (isEmpty) {
      _contentRect = null;
      return;
    }

    // Get the outermost root quadtrees
    List<_Index> leftmostQuadTrees = [];
    List<_Index> topmostQuadTrees = [];
    List<_Index> rightmostQuadTrees = [];
    List<_Index> bottommostQuadTrees = [];
    for (final _Index index in _rootQuadTrees.keys) {
      if (leftmostQuadTrees.isEmpty || index.$1 < leftmostQuadTrees.first.$1) {
        leftmostQuadTrees = [index];
      } else if (index.$1 == leftmostQuadTrees.first.$1) {
        leftmostQuadTrees.add(index);
      }
      if (topmostQuadTrees.isEmpty || index.$2 < topmostQuadTrees.first.$2) {
        topmostQuadTrees = [index];
      } else if (index.$2 == topmostQuadTrees.first.$2) {
        topmostQuadTrees.add(index);
      }
      if (rightmostQuadTrees.isEmpty || index.$1 > rightmostQuadTrees.first.$1) {
        rightmostQuadTrees = [index];
      } else if (index.$1 == rightmostQuadTrees.first.$1) {
        rightmostQuadTrees.add(index);
      }
      if (bottommostQuadTrees.isEmpty || index.$2 > bottommostQuadTrees.first.$2) {
        bottommostQuadTrees = [index];
      } else if (index.$2 == bottommostQuadTrees.first.$2) {
        bottommostQuadTrees.add(index);
      }
    }

    // Get the content edges of these quadtrees
    final double leftmostX = leftmostQuadTrees.map((qt) => _rootQuadTrees[qt]!.leftContentEdge).reduce(min);
    final double topmostY = topmostQuadTrees.map((qt) => _rootQuadTrees[qt]!.topContentEdge).reduce(min);
    final double rightmostX = rightmostQuadTrees.map((qt) => _rootQuadTrees[qt]!.rightContentEdge).reduce(max);
    final double bottommostY = bottommostQuadTrees.map((qt) => _rootQuadTrees[qt]!.bottomContentEdge).reduce(max);

    // Create a rect that spans all of these edges and return it
    _contentRect = Rect.fromLTRB(leftmostX, topmostY, rightmostX, bottommostY);
  }

  /// The rect that spans over all nodes and edges managed by this `QuadTree`.
  Rect get contentRect => _contentRect ?? Rect.zero;

  /// Wheter this `QuadTree` has neither nodes nor edges.
  bool get isEmpty => _allChildNodes.isEmpty && _allChildEdges.isEmpty;

  /// Wheter this `QuadTree` has at least one node or edge.
  bool get isNotEmpty => _allChildNodes.isNotEmpty || _allChildEdges.isNotEmpty;
}

/// The implementation of a quad tree node, which is used internally by [QuadTree].
class _QT<NodeIdType, EdgeIdType> {
  /// Creates a quad tree node with the given [bounds].
  ///
  /// [innermostDimension] is the smallest size along any dimension that any child of this quad tree node can subdivide
  /// to.
  _QT(this.bounds, this.innermostDimension)
    : assert(bounds.width == bounds.height),
      assert(bounds.isNotEmpty),
      topLeftBounds = Rect.fromPoints(bounds.center, bounds.topLeft),
      topRightBounds = Rect.fromPoints(bounds.center, bounds.topRight),
      bottomLeftBounds = Rect.fromPoints(bounds.center, bounds.bottomLeft),
      bottomRightBounds = Rect.fromPoints(bounds.center, bounds.bottomRight);

  /// The bounds of this quad tree node.
  final Rect bounds;

  /// The smallest size along any dimension that any child of this quad tree node can subdivide to.
  final double innermostDimension;

  /// The bounds of the top left child quad tree node.
  final Rect topLeftBounds;

  /// The bounds of the top right child quad tree node.
  final Rect topRightBounds;

  /// The bounds of the bottom left child quad tree node.
  final Rect bottomLeftBounds;

  /// The bounds of the bottom right child quad tree node.
  final Rect bottomRightBounds;

  /// All child nodes that are either directly inside this quad tree node or in any of its children.
  final Map<NodeIdType, Rect> _allChildNodes = {};

  /// All child edges that are either directly inside this quad tree node or in any of its children.
  final Map<EdgeIdType, Path> _allChildEdges = {};

  /// The top left child quad tree node.
  _QT<NodeIdType, EdgeIdType>? _topLeft;

  /// The top right child quad tree node.
  _QT<NodeIdType, EdgeIdType>? _topRight;

  /// The bottom left child quad tree node.
  _QT<NodeIdType, EdgeIdType>? _bottomLeft;

  /// The bottom right child quad tree node.
  _QT<NodeIdType, EdgeIdType>? _bottomRight;

  /// Whether this quad tree node is the smallest allowed size and will not be subdivided any more.
  bool get isLeaf => bounds.size.width <= innermostDimension;

  /// Put a node identified by [nodeId] with the given bounding [rect] into this quad tree node.
  ///
  /// If the [rect] fully overlaps this quad tree node, there will be no subdivision and the [nodeId] will only be
  /// stored in [_allChildNodes].
  /// Otherwise we subdivide once and defer to the created child quad tree nodes.
  void putNode(NodeIdType nodeId, Rect rect) {
    assert(!_allChildNodes.containsKey(nodeId));
    assert(intersectsRect(rect));
    assert(rect.isNotEmpty);

    _allChildNodes[nodeId] = rect;

    if (!isLeaf && !fullyOverlaps(rect)) {
      if (_rectsIntersect(topLeftBounds, rect)) {
        (_topLeft ??= _QT(topLeftBounds, innermostDimension)).putNode(nodeId, rect);
      }
      if (_rectsIntersect(topRightBounds, rect)) {
        (_topRight ??= _QT(topRightBounds, innermostDimension)).putNode(nodeId, rect);
      }
      if (_rectsIntersect(bottomRightBounds, rect)) {
        (_bottomRight ??= _QT(bottomRightBounds, innermostDimension)).putNode(nodeId, rect);
      }
      if (_rectsIntersect(bottomLeftBounds, rect)) {
        (_bottomLeft ??= _QT(bottomLeftBounds, innermostDimension)).putNode(nodeId, rect);
      }
    }
  }

  /// Put an edge identified by [edgeId] with the given defining [path] into this quad tree node.
  ///
  /// If the bounding [Rect] of the given [path] fully overlaps this quad tree node, there will be no subdivision and
  /// the [edgeId] will only be stored in [_allChildEdges].
  /// Otherwise we subdivide once and defer to the created child quad tree nodes.
  void putEdge(EdgeIdType edgeId, Path path) {
    assert(!_allChildEdges.containsKey(edgeId));
    assert(intersectsPath(path));

    _allChildEdges[edgeId] = path;

    if (!isLeaf && !fullyOverlaps(path.getBounds())) {
      if (_pathAndRectIntersect(path, topLeftBounds)) {
        (_topLeft ??= _QT(topLeftBounds, innermostDimension)).putEdge(edgeId, path);
      }
      if (_pathAndRectIntersect(path, topRightBounds)) {
        (_topRight ??= _QT(topRightBounds, innermostDimension)).putEdge(edgeId, path);
      }
      if (_pathAndRectIntersect(path, bottomRightBounds)) {
        (_bottomRight ??= _QT(bottomRightBounds, innermostDimension)).putEdge(edgeId, path);
      }
      if (_pathAndRectIntersect(path, bottomLeftBounds)) {
        (_bottomLeft ??= _QT(bottomLeftBounds, innermostDimension)).putEdge(edgeId, path);
      }
    }
  }

  /// Remove the node identified by [nodeId] from this quad tree node.
  void removeNode(NodeIdType nodeId) {
    if (!_allChildNodes.containsKey(nodeId)) return;

    _allChildNodes.remove(nodeId);

    _topLeft?.removeNode(nodeId);
    _topRight?.removeNode(nodeId);
    _bottomRight?.removeNode(nodeId);
    _bottomLeft?.removeNode(nodeId);

    if (_topLeft != null && _topLeft!.isEmpty) _topLeft = null;
    if (_topRight != null && _topRight!.isEmpty) _topRight = null;
    if (_bottomRight != null && _bottomRight!.isEmpty) _bottomRight = null;
    if (_bottomLeft != null && _bottomLeft!.isEmpty) _bottomLeft = null;
  }

  /// Remove the edge identified by [edgeId] from this quad tree node.
  void removeEdge(EdgeIdType edgeId) {
    if (!_allChildEdges.containsKey(edgeId)) return;

    _allChildEdges.remove(edgeId);

    _topLeft?.removeEdge(edgeId);
    _topRight?.removeEdge(edgeId);
    _bottomRight?.removeEdge(edgeId);
    _bottomLeft?.removeEdge(edgeId);

    if (_topLeft != null && _topLeft!.isEmpty) _topLeft = null;
    if (_topRight != null && _topRight!.isEmpty) _topRight = null;
    if (_bottomRight != null && _bottomRight!.isEmpty) _bottomRight = null;
    if (_bottomLeft != null && _bottomLeft!.isEmpty) _bottomLeft = null;
  }

  /// Paints this quad tree node's debug view into the given painting [context] at the given [offset].
  ///
  /// [depth] is increased at every level and is used to deflate the painted rects in order to better differentiate the
  /// bounding boxes.
  void debugPaint(PaintingContext context, Offset offset, [Rect? paintBounds]) {
    paintBounds ??= bounds;

    context.canvas.drawRect(
      paintBounds.translate(offset.dx, offset.dy),
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.0,
    );

    _topLeft?.debugPaint(
      context,
      offset,
      Rect.fromLTRB(
        paintBounds.left + 1,
        paintBounds.top + 1,
        bounds.center.dx - 0.5,
        bounds.center.dy - 0.5,
      ),
    );
    _topRight?.debugPaint(
      context,
      offset,
      Rect.fromLTRB(
        bounds.center.dx + 0.5,
        paintBounds.top + 1,
        paintBounds.right - 1,
        bounds.center.dy - 0.5,
      ),
    );
    _bottomLeft?.debugPaint(
      context,
      offset,
      Rect.fromLTRB(
        paintBounds.left + 1,
        bounds.center.dy + 0.5,
        bounds.center.dx - 0.5,
        paintBounds.bottom - 1,
      ),
    );
    _bottomRight?.debugPaint(
      context,
      offset,
      Rect.fromLTRB(
        bounds.center.dx + 0.5,
        bounds.center.dy + 0.5,
        paintBounds.right - 1,
        paintBounds.bottom - 1,
      ),
    );
  }

  /// Get all node IDs that are contained inside a given [rect].
  Iterable<NodeIdType> getNodeIdsInRect(Rect rect) {
    assert(!isEmpty);

    if (!_rectsIntersect(bounds, rect)) return const {};

    if (fullyOverlaps(rect)) return _allChildNodes.keys;

    return {
      ..._topLeft?.getNodeIdsInRect(rect) ?? const {},
      ..._topRight?.getNodeIdsInRect(rect) ?? const {},
      ..._bottomRight?.getNodeIdsInRect(rect) ?? const {},
      ..._bottomLeft?.getNodeIdsInRect(rect) ?? const {},
    };
  }

  /// Get all edge IDs that are contained inside a given [rect].
  Iterable<EdgeIdType> getEdgeIdsInRect(Rect rect) {
    assert(!isEmpty);

    if (!_rectsIntersect(bounds, rect)) return const {};

    if (fullyOverlaps(rect)) return _allChildEdges.keys;

    return {
      ..._topLeft?.getEdgeIdsInRect(rect) ?? const {},
      ..._topRight?.getEdgeIdsInRect(rect) ?? const {},
      ..._bottomRight?.getEdgeIdsInRect(rect) ?? const {},
      ..._bottomLeft?.getEdgeIdsInRect(rect) ?? const {},
    };
  }

  /// Whether this quad tree node intersects a given [rect].
  bool intersectsRect(Rect rect) => _rectsIntersect(rect, bounds);

  /// Whether this quad tree intersects a given [path].
  ///
  /// See also:
  /// * [_pathAndRectIntersect], which is used to calulate the intersection.
  bool intersectsPath(Path path) => _pathAndRectIntersect(path, bounds);

  /// Whether this quad tree node is completely contained in the given rect.
  bool fullyOverlaps(Rect rect) =>
      bounds.left + innermostDimension >= rect.left &&
      bounds.right - innermostDimension <= rect.right &&
      bounds.top + innermostDimension >= rect.top &&
      bounds.bottom - innermostDimension <= rect.bottom;

  /// The largest y-coordinate of any child node's or edge's left bounds.
  double get leftContentEdge {
    if (_topLeft == null && _topRight == null && _bottomRight == null && _bottomLeft == null) {
      return {
        ..._allChildNodes.values,
        ..._allChildEdges.values.map((path) => path.getBounds()),
      }.map((rect) => rect.left).reduce(min);
    }

    if (_topLeft != null || _bottomLeft != null) {
      return min(
        _topLeft?.leftContentEdge ?? double.infinity,
        _bottomLeft?.leftContentEdge ?? double.infinity,
      );
    } else {
      return min(
        _topRight?.leftContentEdge ?? double.infinity,
        _bottomRight?.leftContentEdge ?? double.infinity,
      );
    }
  }

  /// The largest y-coordinate of any child node's or edge's top bounds.
  double get topContentEdge {
    if (_topLeft == null && _topRight == null && _bottomRight == null && _bottomLeft == null) {
      return {
        ..._allChildNodes.values,
        ..._allChildEdges.values.map((path) => path.getBounds()),
      }.map((rect) => rect.top).reduce(min);
    }

    if (_topLeft != null || _topRight != null) {
      return min(
        _topLeft?.topContentEdge ?? double.infinity,
        _topRight?.topContentEdge ?? double.infinity,
      );
    } else {
      return min(
        _bottomLeft?.topContentEdge ?? double.infinity,
        _bottomRight?.topContentEdge ?? double.infinity,
      );
    }
  }

  /// The largest y-coordinate of any child node's or edge's right bounds.
  double get rightContentEdge {
    if (_topLeft == null && _topRight == null && _bottomRight == null && _bottomLeft == null) {
      return {
        ..._allChildNodes.values,
        ..._allChildEdges.values.map((path) => path.getBounds()),
      }.map((rect) => rect.right).reduce(max);
    }

    if (_topRight != null || _bottomRight != null) {
      return max(
        _topRight?.rightContentEdge ?? double.negativeInfinity,
        _bottomRight?.rightContentEdge ?? double.negativeInfinity,
      );
    } else {
      return max(
        _topLeft?.rightContentEdge ?? double.negativeInfinity,
        _bottomLeft?.rightContentEdge ?? double.negativeInfinity,
      );
    }
  }

  /// The largest y-coordinate of any child node's or edge's bottom bounds.
  double get bottomContentEdge {
    if (_topLeft == null && _topRight == null && _bottomRight == null && _bottomLeft == null) {
      return {
        ..._allChildNodes.values,
        ..._allChildEdges.values.map((path) => path.getBounds()),
      }.map((rect) => rect.bottom).reduce(max);
    }

    if (_bottomLeft != null || _bottomRight != null) {
      return max(
        _bottomLeft?.bottomContentEdge ?? double.negativeInfinity,
        _bottomRight?.bottomContentEdge ?? double.negativeInfinity,
      );
    } else {
      return max(
        _topLeft?.bottomContentEdge ?? double.negativeInfinity,
        _topRight?.bottomContentEdge ?? double.negativeInfinity,
      );
    }
  }

  /// Whether there is at least one node contained in this quad tree node.
  bool get hasNodes => _allChildNodes.isNotEmpty;

  /// Whether there is at least one edge contained in this quad tree node.
  bool get hasEdges => _allChildEdges.isNotEmpty;

  /// Whether there are neither nodes noder Edges inside this quad tree node.
  bool get isEmpty => !hasNodes && !hasEdges;

  /// Whether there is at least one node or edge inside this quad tree node.
  bool get isNotEmpty => hasNodes || hasEdges;
}

/// Whether the two given rects [first] and [second] intersect each other.
bool _rectsIntersect(Rect first, Rect second) => first.overlaps(second);

/// Whether the given [path] intersects with the given [rect].
///
/// This only compares the rectengular bounds of path, not the path itself.
bool _pathAndRectIntersect(Path path, Rect rect) => rect.overlaps(
  path.getBounds()
  // inflate, because paths that are fully horizontal have a height of 0.0 (and vice versa)
  .inflate(0.1),
);
