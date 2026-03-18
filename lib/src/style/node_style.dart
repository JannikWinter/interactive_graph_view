import "dart:ui";

import "package:flutter/foundation.dart" show immutable;
import "package:flutter/material.dart" show ThemeExtension, Colors;
import "package:flutter/painting.dart";

import "../util/nullable.dart";

/// The style for a [NodeWidget].
///
/// Note that some properties will not apply when using [NodeWidget.custom]. For more information, see
/// [NodeWidget.custom] and [NodeWidget.basic].
///
/// A style can be applied either by supplying it directly to the constructor of [NodeWidget] or by supplying it through
/// [ThemeData] - either in a [MaterialApp] or in a [Theme] widget:
/// ```dart
/// Theme(
///   data: ThemeData(
///     extensions: {
///       // ...
///       NodeStyle(
///         // ...
///       ),
///       // ...
///     },
///   )
/// ```
@immutable
class NodeStyle extends ThemeExtension<NodeStyle> {
  /// Constructs a node style.
  const NodeStyle({
    this.textStyle = const TextStyle(),
    this.padding,
    this.backgroundColor,
    this.borderSide,
    this.maxWidth,
    this.clipBehavior,
    this.borderRadius,
  });

  /// Constructs a fallback node style.
  ///
  /// This is used by [NodeWidget.basic] (and [BasicNodeBackground] and [BasicNodeContent]) when neither a style is
  /// supplied directly nor a `NodeStyle` was supplied through a [Theme] up the widget tree.
  const NodeStyle.fallback()
    : this(
        textStyle: const TextStyle(),
        padding: const EdgeInsets.all(6.0),
        backgroundColor: Colors.blue,
        borderSide: const BorderSide(style: BorderStyle.none),
        maxWidth: 400,
        clipBehavior: Clip.none,
        borderRadius: Radius.zero,
      );

  /// The text style for the text of the node.
  final TextStyle textStyle;

  /// The padding applied to the text of the node.
  final EdgeInsets? padding;

  /// The node's background color.
  final Color? backgroundColor;

  /// The `BorderSide` applied to all sides of the border.
  ///
  /// Supply a `BoderSide` with `style` set to [BorderStyle.none], if there should not be a border.
  final BorderSide? borderSide;

  /// The maximum width the node is allowed to take before the content wraps.
  ///
  /// If the content or background of the node overflows this maximum width, it will be clipped according to
  /// [clipBehavior].
  final double? maxWidth;

  /// The node's clipping behavior.
  ///
  /// If the content or background of the node overflows this maximum width, it will be clipped according to
  /// this value.
  final Clip? clipBehavior;

  /// The node's border radius applied to each corner.
  final Radius? borderRadius;

  /// Creates a copy of this node style with all the given fields replaced by the non-null parameter values.
  @override
  NodeStyle copyWith({
    TextStyle? textStyle,
    Nullable<EdgeInsets>? padding,
    Nullable<Color>? backgroundColor,
    Nullable<BorderSide>? borderSide,
    Nullable<double>? maxWidth,
    Nullable<Clip>? clipBehavior,
    Nullable<Radius>? borderRadius,
  }) {
    return NodeStyle(
      textStyle: textStyle ?? this.textStyle,
      padding: (padding != null) ? padding.value : this.padding,
      backgroundColor: (backgroundColor != null) ? backgroundColor.value : this.backgroundColor,
      borderSide: (borderSide != null) ? borderSide.value : this.borderSide,
      maxWidth: (maxWidth != null) ? maxWidth.value : this.maxWidth,
      clipBehavior: (clipBehavior != null) ? clipBehavior.value : this.clipBehavior,
      borderRadius: (borderRadius != null) ? borderRadius.value : this.borderRadius,
    );
  }

  @override
  NodeStyle lerp(ThemeExtension<NodeStyle>? other, double t) {
    if (identical(this, other) || other is! NodeStyle) {
      return this;
    }

    return NodeStyle(
      textStyle: TextStyle.lerp(textStyle, other.textStyle, t)!,
      padding: EdgeInsets.lerp(padding, other.padding, t),
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      borderSide: BorderSide.lerp(
        borderSide ?? const BorderSide(style: BorderStyle.none),
        other.borderSide ?? const BorderSide(style: BorderStyle.none),
        t,
      ),
      maxWidth: lerpDouble(maxWidth, other.maxWidth, t),
      clipBehavior: (t < 0.5) ? clipBehavior : other.clipBehavior,
      borderRadius: Radius.lerp(borderRadius, other.borderRadius, t),
    );
  }

  /// Returns a new node style that is a combination of this style and the given [other] style.
  ///
  /// The null properties of the given [other] node style are replaced with the non-null properties of this node style.
  /// The [other] style _inherits_ the properties of this style. Another way to think of it is that the "missing"
  /// properties of the [other] style are _filled_ by the properties of this style.
  ///
  /// If the given node style is null, returns this node style.
  NodeStyle merge(NodeStyle? other) {
    if (identical(this, other) || other == null) {
      return this;
    }

    return copyWith(
      textStyle: textStyle.merge(other.textStyle),
      padding: Nullable((other.padding != null) ? other.padding : padding),
      backgroundColor: Nullable((other.backgroundColor != null) ? other.backgroundColor : backgroundColor),
      borderSide: Nullable((other.borderSide != null) ? other.borderSide : borderSide),
      maxWidth: Nullable((other.maxWidth != null) ? other.maxWidth : maxWidth),
      clipBehavior: Nullable((other.clipBehavior != null) ? other.clipBehavior : clipBehavior),
      borderRadius: Nullable((other.borderRadius != null) ? other.borderRadius : borderRadius),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }

    return other is NodeStyle &&
        textStyle == other.textStyle &&
        padding == other.padding &&
        backgroundColor == other.backgroundColor &&
        borderSide == other.borderSide &&
        maxWidth == other.maxWidth &&
        clipBehavior == other.clipBehavior &&
        borderRadius == other.borderRadius;
  }

  @override
  int get hashCode => Object.hash(
    textStyle,
    padding,
    backgroundColor,
    borderSide,
    maxWidth,
    clipBehavior,
    borderRadius,
  );
}
