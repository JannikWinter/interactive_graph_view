import "dart:collection";
import "dart:math";
import "dart:ui";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart" show Colors;
import "package:flutter/rendering.dart";
import "package:path_drawing/path_drawing.dart";

import "../style/arrow_style.dart";
import "../style/curve_style.dart";
import "../style/line_shadow.dart";
import "../style/line_style.dart";
import "edge_parent_data.dart";
import "graph_element.dart";

final class GraphEdgeRenderObject<NodeIdType> extends GraphElementRenderObject {
  static const double _hitTestPathStepSize = 5.0;

  GraphEdgeRenderObject({
    required NodeIdType startNodeId,
    required NodeIdType endNodeId,
    required String? text,
    required ArrowStyle arrowStyle,
    required CurveStyle curveStyle,
    required LineStyle lineStyle,
    required TextStyle textStyle,
    required Color textBackgroundColor,
    required Color color,
    required List<LineShadow> shadow,
  }) : _startNodeId = startNodeId,
       _endNodeId = endNodeId,
       _text = text,
       _arrowStyle = arrowStyle,
       _curveStyle = curveStyle,
       _lineStyle = lineStyle,
       _textStyle = textStyle,
       _textBackgroundColor = textBackgroundColor,
       _color = color,
       _shadow = shadow {
    _recreateTextPainter();
  }

  NodeIdType _startNodeId;
  NodeIdType get startNodeId => _startNodeId;
  set startNodeId(NodeIdType value) {
    if (_startNodeId == value) return;

    _startNodeId = value;
    markParentNeedsLayout();
  }

  NodeIdType _endNodeId;
  NodeIdType get endNodeId => _endNodeId;
  set endNodeId(NodeIdType value) {
    if (_endNodeId == value) return;

    _endNodeId = value;
    markParentNeedsLayout();
  }

  TextPainter? _textPainter;
  void _recreateTextPainter() {
    if (text != null) {
      _textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
      );
    } else {
      _textPainter = null;
    }
  }

  String? get text => _text;
  String? _text;
  set text(String? value) {
    if (_text == value) {
      return;
    }

    _text = value;
    _recreateTextPainter();
    markNeedsLayout();
  }

  ArrowStyle get arrowStyle => _arrowStyle;
  ArrowStyle _arrowStyle;
  set arrowStyle(ArrowStyle value) {
    if (_arrowStyle == value) return;

    _arrowStyle = value;
    markNeedsLayout();
  }

  CurveStyle get curveStyle => _curveStyle;
  CurveStyle _curveStyle;
  set curveStyle(CurveStyle value) {
    if (_curveStyle == value) return;

    _curveStyle = value;
    markNeedsLayout();
  }

  LineStyle get lineStyle => _lineStyle;
  LineStyle _lineStyle;
  set lineStyle(LineStyle value) {
    if (_lineStyle == value) return;

    _lineStyle = value;
    markNeedsLayout();
  }

  TextStyle get textStyle => _textStyle;
  TextStyle _textStyle;
  set textStyle(TextStyle value) {
    if (_textStyle == value) return;

    _textStyle = value;
    _recreateTextPainter();
    markNeedsLayout();
  }

  Color get textBackgroundColor => _textBackgroundColor;
  Color _textBackgroundColor;
  set textBackgroundColor(Color value) {
    if (_textBackgroundColor == value) return;

    _textBackgroundColor = value;
    markNeedsPaint();
  }

  Color get color => _color;
  Color _color;
  set color(Color value) {
    if (_color == value) return;

    _color = value;
    markNeedsPaint();
  }

  UnmodifiableListView<LineShadow> get shadow => UnmodifiableListView(_shadow);
  List<LineShadow> _shadow;
  set shadow(List<LineShadow> value) {
    if (listEquals(_shadow, value)) return;

    _shadow = List.from(value);
    markNeedsPaint();
  }

  late Path _hitTestPath;
  late Path _basicLinePath;
  late Path _linePath;
  late Path _arrowPath;

  late Offset _textPosition;
  late Offset _arrowPosition;
  late double _arrowDirection;

  Path get linePath => _basicLinePath;

  @override
  void performLayout() {
    final GraphViewportEdgeParentData parentData = this.parentData as GraphViewportEdgeParentData;

    final Offset startNodeCenter = parentData.startNodeCenter;
    final Size startNodeSize = parentData.startNodeSize;

    final Offset endNodeCenter = parentData.endNodeCenter;
    final Size endNodeSize = parentData.endNodeSize;
    final Radius endNodeBorderRadius = parentData.endNodeBorderRadius;

    final Offset startToEnd = parentData.centerToCenter;
    final Offset endToStart = parentData.centerToCenterBackwards;
    final Offset direction = startToEnd / startToEnd.distance;
    final Offset rotated1 = Offset(-direction.dy, direction.dx) * parentData.hitboxThickness / 2;
    final Offset rotated2 = -rotated1;

    if (_textPainter != null) {
      _textPainter!.layout();
    }

    _hitTestPath = Path()
      ..moveTo(startNodeCenter.dx, startNodeCenter.dy)
      ..relativeLineTo(rotated1.dx, rotated1.dy)
      ..relativeLineTo(startToEnd.dx, startToEnd.dy)
      ..relativeLineTo(rotated2.dx * 2, rotated2.dy * 2)
      ..relativeLineTo(endToStart.dx, endToStart.dy)
      ..close();

    _arrowPath = Path()
      ..moveTo(0, 0)
      ..lineTo(-arrowStyle.length, -arrowStyle.width / 2)
      ..lineTo(-arrowStyle.length, arrowStyle.width / 2)
      ..close();

    switch (curveStyle) {
      case StraightCurveStyle():
        {
          final double lineSlope = (startToEnd.dy / startToEnd.dx).abs();

          Offset computeNodeBorderIntersection({
            required Offset lineToNode,
            required Size nodeSize,
            required Offset nodeCenter,
          }) {
            final double lineSlope = (lineToNode.dy / lineToNode.dx).abs();

            final double xOffset;
            final double yOffset;
            if (lineSlope < (nodeSize.height / nodeSize.width).abs()) {
              // horizontal
              xOffset = nodeSize.width / 2;
              yOffset = lineSlope * xOffset;
            } else {
              // vertical
              yOffset = nodeSize.height / 2;
              xOffset = yOffset / lineSlope;
            }

            return nodeCenter +
                Offset(
                  xOffset * -lineToNode.dx.sign,
                  yOffset * -lineToNode.dy.sign,
                );
          }

          Offset lineStartAtNodeBorder = computeNodeBorderIntersection(
            nodeSize: startNodeSize,
            nodeCenter: startNodeCenter,
            lineToNode: -startToEnd,
          );
          Offset lineEndAtNodeBorder = computeNodeBorderIntersection(
            nodeSize: endNodeSize,
            nodeCenter: endNodeCenter,
            lineToNode: startToEnd,
          );

          final double m1 =
              (endNodeSize.height - 2 * endNodeBorderRadius.y) / endNodeSize.width; // slope to the first corner edge
          final double m2 =
              endNodeSize.height / (endNodeSize.width - 2 * endNodeBorderRadius.x); // slope to the second corner edge
          final bool isAtCorner = lineSlope > m1 && lineSlope < m2;
          if (isAtCorner) {
            // Ellipse-Line-Intersection
            // Source: https://www.ambrbit.com/TrigoCalc/Circles2/Ellipse/EllipseLine.htm

            // The formula expects the long side to be on the x-axis, so we flip where we need to
            final bool isFlipped = endNodeBorderRadius.x < endNodeBorderRadius.y;

            final double a = max(endNodeBorderRadius.x, endNodeBorderRadius.y); // long side
            final double b = min(endNodeBorderRadius.x, endNodeBorderRadius.y); // short side
            final double m; // line slope
            final double c; // line y-axis intersection (y = mx + c)

            if (isFlipped) {
              m = (1 / lineSlope);
              c = m * (endNodeSize.height / 2 - endNodeBorderRadius.y) - endNodeSize.width / 2 + endNodeBorderRadius.x;
            } else {
              m = lineSlope;
              c = m * (endNodeSize.width / 2 - endNodeBorderRadius.x) - endNodeSize.height / 2 + endNodeBorderRadius.y;
            }

            final double aSquared = a * a;
            final double bSquared = b * b;
            final double mSquared = m * m;
            final double cSquared = c * c;

            final double numerator1 = -aSquared * m * c;
            final double numerator2 = a * b * sqrt(aSquared * mSquared + bSquared - cSquared);
            final double denominator = bSquared + aSquared * mSquared;

            final double x1;
            final double y1;
            if (isFlipped) {
              y1 = (numerator1 + numerator2) / denominator;
              x1 = m * y1 + c;
            } else {
              x1 = (numerator1 + numerator2) / denominator;
              y1 = m * x1 + c;
            }

            final Offset correctedOffsetFromEndPosition = Offset(
              endNodeSize.width / 2 - endNodeBorderRadius.x + x1,
              -endNodeSize.height / 2 + endNodeBorderRadius.y - y1,
            );

            lineEndAtNodeBorder =
                endNodeCenter - (startToEnd / startToEnd.distance) * correctedOffsetFromEndPosition.distance;
          }

          _arrowDirection = startToEnd.direction;
          _arrowPosition = lineEndAtNodeBorder;

          final Offset startBorderToEndBorder = lineEndAtNodeBorder - lineStartAtNodeBorder;
          final Offset lineEndWithoutArrow =
              _arrowPosition - (startBorderToEndBorder / startBorderToEndBorder.distance) * (arrowStyle.length - 0.1);

          _textPosition = lineStartAtNodeBorder + startBorderToEndBorder / 2;

          _basicLinePath = Path()
            ..moveTo(startNodeCenter.dx, startNodeCenter.dy)
            ..lineTo(lineEndWithoutArrow.dx, lineEndWithoutArrow.dy);
        }

      // TODO: implement CubicBezierCurveStyle
      // case CubicBezierCurveStyle():
      //   {}
    }

    switch (lineStyle) {
      case DashedLineStyle(dashSize: final double dashSize, gapSize: final double gapSize):
        _linePath = dashPath(
          _basicLinePath,
          dashArray: CircularIntervalList([
            dashSize,
            gapSize,
          ]),
        );

      case DottedLineStyle(thickness: final double thickness, gapSize: final double gapSize):
        _linePath = dashPath(
          _basicLinePath,
          dashArray: CircularIntervalList([
            thickness,
            gapSize,
          ]),
        );

      case SolidLineStyle():
        _linePath = Path.from(_basicLinePath);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.canvas.save();
    context.canvas.translate(offset.dx, offset.dy);

    for (final LineShadow shadow in shadow) {
      context.canvas.drawPath(
        _linePath,
        shadow.toPaint(),
      );

      _paintArrow(
        context.canvas,
        shadow.toPaint(),
      );
    }

    context.canvas.drawPath(
      _linePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = color
        ..strokeWidth = lineStyle.thickness,
    );

    _paintArrow(
      context.canvas,
      Paint()..color = color,
    );

    if (_textPainter != null) {
      final double textWidth = _textPainter!.width;
      final double textHeight = _textPainter!.height;

      if (textBackgroundColor != Colors.transparent) {
        context.canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: _textPosition, width: textWidth + 15, height: textHeight + 10),
            Radius.circular(10),
          ),
          Paint()..color = textBackgroundColor,
        );
      }
      _textPainter!.paint(
        context.canvas,
        _textPosition - Offset(textWidth, textHeight) / 2,
      );
    }

    context.canvas.restore();
  }

  void _paintArrow(Canvas canvas, Paint paint) {
    canvas.save();

    canvas.translate(_arrowPosition.dx, _arrowPosition.dy);
    canvas.rotate(_arrowDirection);

    canvas.drawPath(
      _arrowPath,
      paint,
    );

    canvas.restore();
  }

  @override
  Rect get semanticBounds {
    final GraphViewportEdgeParentData parentData = this.parentData as GraphViewportEdgeParentData;

    return Rect.fromPoints(parentData.startNodeCenter, parentData.endNodeCenter);
  }

  @override
  Rect get paintBounds {
    if (_textPainter == null) {
      return semanticBounds;
    } else {
      final Rect textBounds = Rect.fromCenter(
        center: _textPosition,
        width: _textPainter!.width,
        height: _textPainter!.height,
      );
      return semanticBounds.expandToInclude(textBounds);
    }
  }

  double? getDistanceSquaredTo(Offset position) {
    if (!_hitTestPath.contains(position)) return null;

    final PathMetrics pathMetrics = _basicLinePath.computeMetrics();

    double minDistanceSquared = double.infinity;

    for (final PathMetric pathMetric in pathMetrics) {
      for (double d = 0; d < pathMetric.length; d += _hitTestPathStepSize) {
        final Offset point = pathMetric.getTangentForOffset(d)!.position;
        final double distanceSquared = (point - position).distanceSquared;

        if (distanceSquared < minDistanceSquared) {
          minDistanceSquared = distanceSquared;
        }
      }
    }

    return minDistanceSquared;
  }

  @override
  bool hitTest(BoxHitTestResult result, Offset position) {
    if (_hitTestPath.contains(position)) {
      result.add(HitTestEntry(this));
    }

    return false;
  }
}
