import "package:flutter/foundation.dart";

@immutable
class Nullable<ValueType extends Object> {
  const Nullable(this.value);

  final ValueType? value;
}
