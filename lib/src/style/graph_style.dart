import "package:flutter/foundation.dart";
import "package:flutter/material.dart" show ThemeExtension, Colors;
import "package:flutter/painting.dart";

import "../util/nullable.dart";

/// The style for a [GraphViewport] widget.
///
/// A style can be applied either by supplying it directly to [GraphViewport.new] or by supplying it through
/// [ThemeData] - either in a [MaterialApp] or in a [Theme] widget:
/// ```dart
/// Theme(
///   data: ThemeData(
///     extensions: {
///       // ...
///       GraphStyle(
///         // ...
///       ),
///       // ...
///     },
///   )
/// ```
@immutable
class GraphStyle extends ThemeExtension<GraphStyle> {
  /// Constructs a graph style.
  const GraphStyle({
    this.backgroundColor,
  });

  /// Constructs a fallback graph style which is used by [GraphViewport] when neither a style is supplied dirrectly nor
  /// a graph style was supplied through a [Theme] up the widget tree.
  const GraphStyle.fallback()
    : this(
        backgroundColor: Colors.black,
      );

  /// The graph's background color.
  final Color? backgroundColor;

  /// Creates a copy of this graph style with alle the given fields replaced by the non-null parameter values.
  @override
  GraphStyle copyWith({
    Nullable<Color>? backgroundColor,
  }) {
    return GraphStyle(
      backgroundColor: (backgroundColor != null) ? backgroundColor.value : this.backgroundColor,
    );
  }

  @override
  GraphStyle lerp(ThemeExtension<GraphStyle>? other, double t) {
    if (identical(this, other) || other is! GraphStyle) return this;

    return GraphStyle(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t)!,
    );
  }

  /// Returns a new graph style that is a combination of this style and the given [other] style.
  ///
  /// The null properties of the given [other] graph style are replaced with the non-null properties of this graph
  /// style. The [other] style _inherits_ the properties of this style. Another way to think of it is that the "missing"
  /// properties of the [other] style are _filled_ by the properties of this style.
  ///
  /// If the given graph style is null, returns this graph style.
  GraphStyle merge(GraphStyle? other) {
    if (identical(this, other) || other == null) {
      return this;
    }

    return copyWith(
      backgroundColor: (other.backgroundColor != null) ? Nullable(other.backgroundColor) : null,
    );
  }
}
