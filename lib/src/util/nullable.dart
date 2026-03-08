import "package:flutter/foundation.dart";

/// A type used to be able to overwrite nullable values in e.g. `copyWith()` methods.
///
/// Usually in a `copyWith(...)` method, all parameters are nullable and `null` by default. If you supply a different
/// value than `null` for any parameter, the respective field is replaced in the copy.
///
/// This is not possible for nullable fields. We would never be able to overwrite this field by `null` in the copy.
///
/// That's where this type comes in. A nullable field is exposed as follows:
/// ```dart
/// T copyWith({Nullable<int>? nullableValue}) {...}
/// ```
/// When you do not want to replace the value in the copy you just supply `null` as usual.
///
/// When you instead want to replace the value in the copy, you supply `Nullable(newValue)`, where `newValue` can also
/// be null.
@immutable
class Nullable<ValueType extends Object> {
  /// Constructs a new nullable of a given [value].
  const Nullable(this.value);

  /// The nullable value.
  final ValueType? value;
}
