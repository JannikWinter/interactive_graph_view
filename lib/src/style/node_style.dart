import "package:flutter/foundation.dart" show immutable;
import "package:flutter/material.dart" show ThemeExtension, Colors;
import "package:flutter/painting.dart";

import "../util/nullable.dart" show Nullable;

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
    required this.textStyle,
    this.padding = const EdgeInsets.all(8.0),
    required this.backgroundColor,
    this.borderSide,
  });

  /// Constructs a fallback node style which is used by [NodeWidget.basic] (and [BasicNodeBackground] and
  /// [BasicNodeContent]) when neither a style is supplied directly nor a `NodeStyle` was supplied through a [Theme]
  /// up the widget tree.
  const NodeStyle.fallback()
    : this(
        textStyle: const TextStyle(color: Colors.white),
        backgroundColor: Colors.blue,
      );

  /// The text style for the text of the node.
  final TextStyle textStyle;

  /// The padding applied to the text of the node.
  final EdgeInsets padding;

  /// The node's background color
  final Color backgroundColor;

  /// The `BorderSide` applied to all sides of the border.
  ///
  /// Supply `null` if there should not be a border.
  final BorderSide? borderSide;

  /// Creates a copy of this node style with all the given fields replaced by the non-null parameter values.
  ///
  /// If you want to replace [borderSide] in the copy, supply `Nullable(value)`, where value can also be null
  /// (see [Nullable]).
  @override
  NodeStyle copyWith({
    TextStyle? textStyle,
    EdgeInsets? padding,
    Color? backgroundColor,
    Nullable<BorderSide>? borderSide,
  }) {
    return NodeStyle(
      textStyle: textStyle ?? this.textStyle,
      padding: padding ?? this.padding,
      backgroundColor: backgroundColor ?? this.backgroundColor,
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
      padding: EdgeInsets.lerp(padding, other.padding, t)!,
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t)!,
      borderSide: BorderSide.lerp(
        borderSide ?? const BorderSide(width: 0),
        other.borderSide ?? const BorderSide(width: 0),
        t,
      ),
    );
  }
}
