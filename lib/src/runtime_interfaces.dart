/// Common interface for types defined at runtime (interpreted or bridged).
abstract class RuntimeType {
  /// The name of the type.
  String get name;

  /// Checks if this type is a subtype of [other].
  bool isSubtypeOf(RuntimeType other, {Object? value});
}

/// A runtime type with explicit generic arguments, for example `Box<int>`.
class AppliedRuntimeType implements RuntimeType {
  final RuntimeType baseType;
  final List<RuntimeType> typeArguments;

  AppliedRuntimeType(this.baseType, List<RuntimeType> typeArguments)
      : typeArguments = List.unmodifiable(typeArguments);

  @override
  String get name =>
      '${baseType.name}<${typeArguments.map((type) => type.name).join(', ')}>';

  @override
  bool isSubtypeOf(RuntimeType other, {Object? value}) {
    if (other is AppliedRuntimeType) {
      final baseMatches = identical(baseType, other.baseType) ||
          baseType.name == other.baseType.name ||
          baseType.isSubtypeOf(other.baseType, value: value);
      if (!baseMatches || typeArguments.length != other.typeArguments.length) {
        return false;
      }

      for (int index = 0; index < typeArguments.length; index++) {
        if (other.typeArguments[index].name == 'dynamic' ||
            other.typeArguments[index].name == 'Object') {
          continue;
        }

        if (!typeArguments[index]
            .isSubtypeOf(other.typeArguments[index], value: value)) {
          return false;
        }
      }

      return true;
    }

    return baseType.isSubtypeOf(other, value: value);
  }

  @override
  String toString() => name;
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
