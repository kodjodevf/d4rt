/// Common interface for types defined at runtime (interpreted or bridged).
abstract class RuntimeType {
  /// The name of the type.
  String get name;

  /// Checks if this type is a subtype of [other].
  bool isSubtypeOf(RuntimeType other, {Object? value});
}

/// Common interface for values defined at runtime (interpreted or bridged instances).
abstract class RuntimeValue {
  /// The runtime type of this value.
  RuntimeType get valueType;

  /// Accesses a property or method of this value.
  Object? get(String name);

  /// Sets a property of this value.
  void set(String name, Object? value);
}
