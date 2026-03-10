import "package:flutter/foundation.dart" show immutable;
import "package:flutter/material.dart" show ThemeExtension, Colors;
import "package:flutter/painting.dart";

import "../util/nullable.dart";

/// The style for a [NodeWidget].
///
/// Note that this will will only be applied when using [BasicNodeBackground] and [BasicNodeBackground], e.g. by
/// using [NodeWidget.basic]..
///
/// A style can be applied either by supplying it directly to [NodeWidget.basic] or by supplying it through
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
///
/// Note that this will not be used when constructing a node through [NodeWidget.custom].
@immutable
class NodeStyle extends ThemeExtension<NodeStyle> {
  /// Constructs a node style.
  const NodeStyle({
    this.textStyle = const TextStyle(),
    this.padding,
    this.backgroundColor,
    this.borderSide,
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
      );

  /// The text style for the text of the node.
  final TextStyle textStyle;

  /// The padding applied to the text of the node.
  final EdgeInsets? padding;

  /// The node's background color
  final Color? backgroundColor;

  /// The `BorderSide` applied to all sides of the border.
  ///
  /// Supply a `BoderSide` with `style` set to [BorderStyle.none], if there should not be a border.
  final BorderSide? borderSide;

  /// Creates a copy of this node style with all the given fields replaced by the non-null parameter values.
  @override
  NodeStyle copyWith({
    TextStyle? textStyle,
    Nullable<EdgeInsets>? padding,
    Nullable<Color>? backgroundColor,
    Nullable<BorderSide>? borderSide,
  }) {
    return NodeStyle(
      textStyle: textStyle ?? this.textStyle,
      padding: (padding != null) ? padding.value : this.padding,
      backgroundColor: (backgroundColor != null) ? backgroundColor.value : this.backgroundColor,
      borderSide: (borderSide != null) ? borderSide.value : this.borderSide,
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
      padding: (other.padding != null) ? Nullable(other.padding) : null,
      backgroundColor: (other.backgroundColor != null) ? Nullable(other.backgroundColor) : null,
      borderSide: (other.borderSide != null) ? Nullable(other.borderSide) : null,
    );
  }
}
