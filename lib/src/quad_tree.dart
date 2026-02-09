import "dart:math";

import "package:flutter/material.dart";

const int _subdivisionMinNodeSize = 100;
const int _subdivisionChildThreshold = 1;
const int _subdivisionSteps = 5;
final int _rootQuadTreeDimension = _subdivisionMinNodeSize * pow(2, _subdivisionSteps - 1).toInt();

typedef _IndexRange = ({int start, int end});
typedef _IndexRange2D = ({_IndexRange horizontal, _IndexRange vertical});
typedef _Index = (int, int);

class QuadTree<NodeIdType, EdgeIdType> {
  final Map<_Index, _QT> _rootQuadTrees = {};

  final Map<NodeIdType, Set<_Index>> _nodeIdToIndex = {};
  final Map<EdgeIdType, Set<_Index>> _edgeIdToIndex = {};

  Rect? _contentRect;

  final Map<NodeIdType, Rect> _allChildNodes = {};
  final Map<EdgeIdType, Path> _allChildEdges = {};

  void debugPaint(PaintingContext context, Offset offset) {
    for (final qt in _rootQuadTrees.values) {
      qt.debugPaint(context, offset, 0);
    }
  }

  _IndexRange2D _computeIndexRange(Rect rect) {
    return (
      horizontal: (
        start: (rect.left / _rootQuadTreeDimension).round(),
        end: (rect.right / _rootQuadTreeDimension).round(),
      ),
      vertical: (
        start: (rect.top / _rootQuadTreeDimension).round(),
        end: (rect.bottom / _rootQuadTreeDimension).round(),
      ),
    );
  }

  _QT? _getQTForIndex(_Index index, {required bool create}) {
    if (!_rootQuadTrees.containsKey(index) && create) {
      _rootQuadTrees[index] = _QT(
        Rect.fromCenter(
          center: Offset(index.$1.toDouble(), index.$2.toDouble()) * _rootQuadTreeDimension.toDouble(),
          width: _rootQuadTreeDimension.toDouble(),
          height: _rootQuadTreeDimension.toDouble(),
        ),
      );
    }

    return _rootQuadTrees[index];
  }

  void putNode(NodeIdType nodeId, Rect rect) {
    if (_allChildNodes[nodeId] == rect) return;

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

  void putEdge(EdgeIdType edgeId, Path path) {
    if (_allChildEdges[edgeId] == path) return;

    removeEdge(edgeId);

    _allChildEdges[edgeId] = path;

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

  void removeAllNodes(Iterable<NodeIdType> nodeIds) {
    for (final NodeIdType nodeId in nodeIds) {
      _removeNodeImpl(nodeId, recalculateContentRect: false);
    }
    _recalculateContentRect();
  }

  void removeAllEdges(Iterable<EdgeIdType> edgeIds) {
    for (final EdgeIdType edgeId in edgeIds) {
      removeEdge(edgeId);
    }
  }

  void removeNode(NodeIdType nodeId) {
    _removeNodeImpl(nodeId, recalculateContentRect: true);
  }

  void _removeNodeImpl(NodeIdType nodeId, {required bool recalculateContentRect}) {
    if (!_allChildNodes.containsKey(nodeId)) return;

    for (final _Index index in _nodeIdToIndex[nodeId] ?? []) {
      final qt = _getQTForIndex(index, create: false)!;
      qt.removeNode(nodeId);

      if (qt.nNodes == 0) {
        assert(qt.nEdges == 0, "QuadTree should not have edges if it has no nodes");
        _rootQuadTrees.remove(index);
      }
    }

    _allChildNodes.remove(nodeId);
    _nodeIdToIndex.remove(nodeId);

    if (recalculateContentRect) {
      _recalculateContentRect();
    }
  }

  void removeEdge(EdgeIdType edgeId) {
    if (!_allChildEdges.containsKey(edgeId)) return;

    for (final _Index index in _edgeIdToIndex[edgeId] ?? []) {
      final qt = _getQTForIndex(index, create: false)!;
      qt.removeEdge(edgeId);
    }

    _allChildEdges.remove(edgeId);
    _edgeIdToIndex.remove(edgeId);
  }

  void clear() {
    _rootQuadTrees.clear();
    _nodeIdToIndex.clear();
    _edgeIdToIndex.clear();
    _allChildNodes.clear();
    _allChildEdges.clear();
  }

  Iterable<NodeIdType> getNodeIdsInRect(Rect rect) {
    final range = _computeIndexRange(rect);

    return {
      for (int x = range.horizontal.start; x <= range.horizontal.end; x++)
        for (int y = range.vertical.start; y <= range.vertical.end; y++)
          ...(_getQTForIndex((x, y), create: false)?.getNodesInRect(rect) ?? []),
    };
  }

  Iterable<EdgeIdType> getEdgeIdsInRect(Rect rect) {
    final range = _computeIndexRange(rect);

    return {
      for (int x = range.horizontal.start; x <= range.horizontal.end; x++)
        for (int y = range.vertical.start; y <= range.vertical.end; y++)
          ...(_getQTForIndex((x, y), create: false)?.getEdgesInRect(rect) ?? []),
    };
  }

  void _recalculateContentRect() {
    // We do not need to include edges here, because they currently can't be outside the node-spanning content rect

    assert(_allChildNodes.isEmpty == _rootQuadTrees.isEmpty);

    if (_allChildNodes.isEmpty) {
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
    final double leftmostX = leftmostQuadTrees.map((qt) => _rootQuadTrees[qt]!.leftContentEdge!).reduce(min);
    final double topmostY = topmostQuadTrees.map((qt) => _rootQuadTrees[qt]!.topContentEdge!).reduce(min);
    final double rightmostX = rightmostQuadTrees.map((qt) => _rootQuadTrees[qt]!.rightContentEdge!).reduce(max);
    final double bottommostY = bottommostQuadTrees.map((qt) => _rootQuadTrees[qt]!.bottomContentEdge!).reduce(max);

    // create a rect that spans all of these edges and return it
    _contentRect = Rect.fromLTRB(leftmostX, topmostY, rightmostX, bottommostY);
  }

  Rect get contentRect => _contentRect ?? Rect.zero;
}

class _QT<NodeIdType, EdgeIdType> {
  _QT(this.bounds)
    : assert(bounds.width == bounds.height),
      topLeftBounds = Rect.fromPoints(bounds.topLeft, bounds.center),
      topRightBounds = Rect.fromPoints(bounds.topCenter, bounds.centerRight),
      bottomLeftBounds = Rect.fromPoints(bounds.centerLeft, bounds.bottomCenter),
      bottomRightBounds = Rect.fromPoints(bounds.center, bounds.bottomRight);

  final Rect bounds;

  final Rect topLeftBounds;
  final Rect topRightBounds;
  final Rect bottomLeftBounds;
  final Rect bottomRightBounds;

  final Map<NodeIdType, Rect> _childNodes = {};
  final Map<EdgeIdType, Path> _childEdges = {};

  int get nNodes => _childNodes.length;
  int get nEdges => _childEdges.length;

  _QT? _topLeft;
  _QT? _topRight;
  _QT? _bottomLeft;
  _QT? _bottomRight;

  bool get isLeaf => (_topLeft == null && _topRight == null && _bottomRight == null && _bottomLeft == null);
  bool get _shouldBeSubdivided =>
      (bounds.size.width > _subdivisionMinNodeSize) &&
      (nNodes >= _subdivisionChildThreshold || nEdges >= _subdivisionChildThreshold);

  void _maybeSubdivide() {
    if (!isLeaf) return;
    if (!_shouldBeSubdivided) return;

    _topLeft = _QT(topLeftBounds);
    _topRight = _QT(topRightBounds);
    _bottomRight = _QT(bottomRightBounds);
    _bottomLeft = _QT(bottomLeftBounds);
  }

  void _maybeMerge() {
    if (isLeaf) return;
    if (_shouldBeSubdivided) return;

    _topLeft = null;
    _topRight = null;
    _bottomRight = null;
    _bottomLeft = null;
  }

  void putNode(NodeIdType nodeId, Rect rect) {
    assert(intersectsRect(rect));

    _childNodes[nodeId] = rect;
    _maybeSubdivide();
    if (!isLeaf) {
      if (_topLeft!.intersectsRect(rect)) _topLeft!.putNode(nodeId, rect);
      if (_topRight!.intersectsRect(rect)) _topRight!.putNode(nodeId, rect);
      if (_bottomRight!.intersectsRect(rect)) _bottomRight!.putNode(nodeId, rect);
      if (_bottomLeft!.intersectsRect(rect)) _bottomLeft!.putNode(nodeId, rect);
    }
  }

  void putEdge(EdgeIdType edgeId, Path path) {
    assert(intersectsPath(path));

    _childEdges[edgeId] = path;
    _maybeSubdivide();
    if (!isLeaf) {
      if (_topLeft!.intersectsPath(path)) _topLeft!.putEdge(edgeId, path);
      if (_topRight!.intersectsPath(path)) _topRight!.putEdge(edgeId, path);
      if (_bottomRight!.intersectsPath(path)) _bottomRight!.putEdge(edgeId, path);
      if (_bottomLeft!.intersectsPath(path)) _bottomLeft!.putEdge(edgeId, path);
    }
  }

  void removeNode(NodeIdType nodeId) {
    if (!_childNodes.containsKey(nodeId)) return;

    _childNodes.remove(nodeId);

    _maybeMerge();

    if (!isLeaf) {
      _topLeft!.removeNode(nodeId);
      _topRight!.removeNode(nodeId);
      _bottomRight!.removeNode(nodeId);
      _bottomLeft!.removeNode(nodeId);
    }
  }

  void removeEdge(EdgeIdType edgeId) {
    if (!_childEdges.containsKey(edgeId)) return;

    _childEdges.remove(edgeId);

    _maybeMerge();

    if (!isLeaf) {
      _topLeft!.removeEdge(edgeId);
      _topRight!.removeEdge(edgeId);
      _bottomRight!.removeEdge(edgeId);
      _bottomLeft!.removeEdge(edgeId);
    }
  }

  void clear() {
    _childNodes.clear();
    _childEdges.clear();

    _topLeft = null;
    _topRight = null;
    _bottomRight = null;
    _bottomLeft = null;
  }

  void debugPaint(PaintingContext context, Offset offset, int depth) {
    context.canvas.drawRect(
      bounds.translate(offset.dx, offset.dy).deflate(depth.toDouble()),
      Paint()
        ..color = (_childNodes.isNotEmpty || _childEdges.isNotEmpty) ? Colors.red : Colors.blue
        ..style = PaintingStyle.stroke,
    );

    _topLeft?.debugPaint(context, offset, depth + 1);
    _topRight?.debugPaint(context, offset, depth + 1);
    _bottomLeft?.debugPaint(context, offset, depth + 1);
    _bottomRight?.debugPaint(context, offset, depth + 1);
  }

  Iterable<NodeIdType> getNodesInRect(Rect rect) {
    if (bounds.intersect(rect).size == bounds.size) return _childNodes.keys;

    if (!isLeaf) {
      return {
        if (_topLeft!.intersectsRect(rect)) ..._topLeft!.getNodesInRect(rect),
        if (_topRight!.intersectsRect(rect)) ..._topRight!.getNodesInRect(rect),
        if (_bottomRight!.intersectsRect(rect)) ..._bottomRight!.getNodesInRect(rect),
        if (_bottomLeft!.intersectsRect(rect)) ..._bottomLeft!.getNodesInRect(rect),
      };
    }

    return _childNodes.entries.where((entry) => rectsIntersect(entry.value, rect)).map((entry) => entry.key);
  }

  Iterable<EdgeIdType> getEdgesInRect(Rect rect) {
    if (bounds.intersect(rect).size == bounds.size) return _childEdges.keys;

    if (!isLeaf) {
      return {
        if (_topLeft!.intersectsRect(rect)) ..._topLeft!.getEdgesInRect(rect),
        if (_topRight!.intersectsRect(rect)) ..._topRight!.getEdgesInRect(rect),
        if (_bottomRight!.intersectsRect(rect)) ..._bottomRight!.getEdgesInRect(rect),
        if (_bottomLeft!.intersectsRect(rect)) ..._bottomLeft!.getEdgesInRect(rect),
      };
    }

    return _childEdges.entries.where((entry) => pathAndRectIntersect(entry.value, rect)).map((entry) => entry.key);
  }

  bool rectsIntersect(Rect first, Rect second) => !first.intersect(second).size.isEmpty;
  bool pathAndRectIntersect(Path path, Rect rect) => !rect
      .intersect(
        path.getBounds()
        // inflate, because paths that are fully horizontal have a height of 0.0 (and vice versa)
        .inflate(0.1),
      )
      .size
      .isEmpty;

  bool intersectsRect(Rect rect) => rectsIntersect(rect, bounds);
  bool intersectsPath(Path path) => pathAndRectIntersect(path, bounds);

  double? get leftContentEdge {
    if (!hasNodes) return null;
    if (isLeaf) return _childNodes.values.map((rect) => rect.left).reduce(min);

    assert(_topLeft != null && _topRight != null && _bottomLeft != null && _bottomRight != null);

    if (_topLeft!.isNotEmpty || _bottomLeft!.isNotEmpty) {
      return min(
        _topLeft!.leftContentEdge ?? double.infinity,
        _bottomLeft!.leftContentEdge ?? double.infinity,
      );
    } else {
      return min(
        _topRight!.leftContentEdge ?? double.infinity,
        _bottomRight!.leftContentEdge ?? double.infinity,
      );
    }
  }

  double? get topContentEdge {
    if (!hasNodes) return null;
    if (isLeaf) return _childNodes.values.map((rect) => rect.top).reduce(min);

    assert(_topLeft != null && _topRight != null && _bottomLeft != null && _bottomRight != null);

    if (_topLeft!.isNotEmpty || _topRight!.isNotEmpty) {
      return min(
        _topLeft!.topContentEdge ?? double.infinity,
        _topRight!.topContentEdge ?? double.infinity,
      );
    } else {
      return min(
        _bottomLeft!.topContentEdge ?? double.infinity,
        _bottomRight!.topContentEdge ?? double.infinity,
      );
    }
  }

  double? get rightContentEdge {
    if (!hasNodes) return null;
    if (isLeaf) return _childNodes.values.map((rect) => rect.right).reduce(max);

    assert(_topLeft != null && _topRight != null && _bottomLeft != null && _bottomRight != null);

    if (_topRight!.isNotEmpty || _bottomRight!.isNotEmpty) {
      return max(
        _topRight!.rightContentEdge ?? double.negativeInfinity,
        _bottomRight!.rightContentEdge ?? double.negativeInfinity,
      );
    } else {
      return max(
        _topLeft!.rightContentEdge ?? double.negativeInfinity,
        _bottomLeft!.rightContentEdge ?? double.negativeInfinity,
      );
    }
  }

  double? get bottomContentEdge {
    if (!hasNodes) return null;
    if (isLeaf) return _childNodes.values.map((rect) => rect.bottom).reduce(max);

    assert(_topLeft != null && _topRight != null && _bottomLeft != null && _bottomRight != null);

    if (_bottomLeft!.isNotEmpty || _bottomRight!.isNotEmpty) {
      return max(
        _bottomLeft!.bottomContentEdge ?? double.negativeInfinity,
        _bottomRight!.bottomContentEdge ?? double.negativeInfinity,
      );
    } else {
      return max(
        _topLeft!.bottomContentEdge ?? double.negativeInfinity,
        _topRight!.bottomContentEdge ?? double.negativeInfinity,
      );
    }
  }

  bool get hasNodes => _childNodes.isNotEmpty;
  bool get hasEdges => _childEdges.isNotEmpty;
  bool get isEmpty => !hasNodes && !hasEdges;
  bool get isNotEmpty => hasNodes || hasEdges;
}
