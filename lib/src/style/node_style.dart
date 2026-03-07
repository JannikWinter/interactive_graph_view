import "package:flutter/foundation.dart" show immutable;
import "package:flutter/material.dart" show ThemeExtension, Colors;
import "package:flutter/painting.dart";

import "../util/nullable.dart" show Nullable;

@immutable
class NodeStyle extends ThemeExtension<NodeStyle> {
  const NodeStyle({
    required this.textStyle,
    this.padding = const EdgeInsets.all(8.0),
    required this.backgroundColor,
    this.borderSide,
  });

  const NodeStyle.fallback()
    : this(
        textStyle: const TextStyle(color: Colors.white),
        backgroundColor: Colors.blue,
      );

  final TextStyle textStyle;
  final EdgeInsets padding;
  final Color backgroundColor;
  final BorderSide? borderSide;

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
