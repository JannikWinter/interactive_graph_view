import "package:flutter/foundation.dart";
import "package:flutter/material.dart" show ThemeExtension, Colors;
import "package:flutter/painting.dart";

@immutable
class GraphStyle extends ThemeExtension<GraphStyle> {
  const GraphStyle({required this.backgroundColor});

  const GraphStyle.fallback()
    : this(
        backgroundColor: Colors.black,
      );

  final Color backgroundColor;

  @override
  GraphStyle copyWith({Color? backgroundColor}) {
    return GraphStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }

  @override
  GraphStyle lerp(ThemeExtension<GraphStyle>? other, double t) {
    if (identical(this, other) || other is! GraphStyle) return this;

    return GraphStyle(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t)!,
    );
  }
}
