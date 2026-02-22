import "dart:math";
import "dart:ui";

import "package:flutter/rendering.dart";
import "package:path_drawing/path_drawing.dart";

import "../config.dart";
import "../curve_style.dart";
import "../line_shadow.dart";
import "../line_style.dart";
import "../parent_data.dart";
import "graph_element.dart";

final class GraphEdgeRenderObject extends GraphElementRenderObject {
  static const double _hitTestPathStepSize = 5.0;

  GraphEdgeRenderObject({
    required String? text,
    required Color color,
    required double thickness,
    required LineStyle lineStyle,
    required CurveStyle curveStyle,
    required List<LineShadow> shadow,
  }) : _text = text,
       _color = color,
       _thickness = thickness,
       _lineStyle = lineStyle,
       _curveStyle = curveStyle,
       _shadow = shadow;

  String? get text => _text;
  String? _text;
  set text(String? value) {
    if (_text == value) {
      return;
    }

    _text = value;
    markNeedsPaint();
  }

  Color get color => _color;
  Color _color;
  set color(Color value) {
    if (_color == value) {
      return;
    }

    _color = value;
    markNeedsPaint();
  }

  double get thickness => _thickness;
  double _thickness;
  set thickness(double value) {
    if (_thickness == value) {
      return;
    }

    _thickness = value;
    markNeedsPaint();
  }

  LineStyle get lineStyle => _lineStyle;
  LineStyle _lineStyle;
  set lineStyle(LineStyle value) {
    if (_lineStyle == value) {
      return;
    }

    _lineStyle = value;
    markNeedsPaint();
  }

  CurveStyle get curveStyle => _curveStyle;
  CurveStyle _curveStyle;
  set curveStyle(CurveStyle value) {
    if (_curveStyle == value) {
      return;
    }

    _curveStyle = value;
    markParentNeedsLayout();
  }

  List<LineShadow> get shadow => _shadow;
  List<LineShadow> _shadow;
  set shadow(List<LineShadow> value) {
    if (_shadow == value) {
      return;
    }

    _shadow = value;
    markNeedsPaint();
  }

  late Path _hitTestPath;
  late Path _basicLinePath;
  late Path _linePath;
  late Offset _textPosition;
  late Offset _arrowPosition;
  late double _arrowDirection;

  static Path get _arrowPath => Path()
    ..moveTo(0, 0)
    ..lineTo(-Config.lineArrowLength, -Config.lineArrowHalfWidth)
    ..lineTo(-Config.lineArrowLength, Config.lineArrowHalfWidth)
    ..close();

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
    final Offset rotated1 = Offset(-direction.dy, direction.dx) * Config.edgeHitBoxHalfThickness;
    final Offset rotated2 = -rotated1;

    _hitTestPath = Path()
      ..moveTo(startNodeCenter.dx, startNodeCenter.dy)
      ..relativeLineTo(rotated1.dx, rotated1.dy)
      ..relativeLineTo(startToEnd.dx, startToEnd.dy)
      ..relativeLineTo(rotated2.dx * 2, rotated2.dy * 2)
      ..relativeLineTo(endToStart.dx, endToStart.dy)
      ..close();

    switch (curveStyle) {
      case CurveStyle.straight:
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
              _arrowPosition - (startBorderToEndBorder / startBorderToEndBorder.distance) * Config.lineArrowLength;

          _textPosition = lineStartAtNodeBorder + startBorderToEndBorder / 2;

          _basicLinePath = Path()
            ..moveTo(startNodeCenter.dx, startNodeCenter.dy)
            ..lineTo(lineEndWithoutArrow.dx, lineEndWithoutArrow.dy);
        }

      // TODO: implement CurveStyle.cubicBezier
      // case CurveStyle.cubicBezier:
      //   {}
    }

    switch (lineStyle) {
      case LineStyle.dashed:
        _linePath = dashPath(
          _basicLinePath,
          dashArray: CircularIntervalList([
            Config.edgeDashedSegmentLength,
            Config.edgeDashedPauseLength,
          ]),
        );

      case LineStyle.dotted:
        _linePath = dashPath(
          _basicLinePath,
          dashArray: CircularIntervalList([
            thickness,
            Config.edgeDottedPauseLength,
          ]),
        );

      case LineStyle.solid:
        _linePath = Path.from(_basicLinePath);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.canvas.save();
    context.canvas.translate(offset.dx, offset.dy);

    for (final LineShadow shadow in _shadow) {
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
        ..strokeWidth = thickness,
    );

    _paintArrow(
      context.canvas,
      Paint()..color = color,
    );

    if (text != null) {
      final TextPainter edgeLabelTextPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: Config.nullNodeTextStyle.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w300,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      edgeLabelTextPainter.layout();

      final double textWidth = edgeLabelTextPainter.width;
      final double textHeight = edgeLabelTextPainter.height;

      context.canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: _textPosition, width: textWidth + 15, height: textHeight + 10),
          Radius.circular(10),
        ),
        Paint()..color = Config.canvasBackgroundColor.withValues(alpha: 0.8),
      );
      edgeLabelTextPainter.paint(
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
      return true;
    }

    return false;
  }
}
