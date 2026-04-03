/// Common interface for types defined at runtime (interpreted or bridged).
abstract class RuntimeType {
  /// The name of the type.
  String get name;

  /// Checks if this type is a subtype of [other].
  bool isSubtypeOf(RuntimeType other, {Object? value});
}

/// A lightweight runtime type identified by its name.
class NamedRuntimeType implements RuntimeType {
  @override
  final String name;

  const NamedRuntimeType(this.name);

  @override
  bool isSubtypeOf(RuntimeType other, {Object? value}) {
    if (identical(this, other) || name == other.name) {
      return true;
    }

    if (other.name == 'dynamic') {
      return true;
    }

    if (other.name == 'Object') {
      return name != 'void';
    }

    if ((name == 'int' || name == 'double') && other.name == 'num') {
      return true;
    }

    return false;
  }

  @override
  String toString() => name;
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

/// A runtime type representing a function signature.
class FunctionRuntimeType implements RuntimeType {
  static const RuntimeType _dynamicType = NamedRuntimeType('dynamic');

  final RuntimeType returnType;
  final List<RuntimeType> positionalParameterTypes;
  final int requiredPositionalParameterCount;
  final Map<String, RuntimeType> namedParameterTypes;
  final Set<String> requiredNamedParameters;
  final int typeParameterCount;
  final bool isUntyped;

  FunctionRuntimeType({
    RuntimeType? returnType,
    List<RuntimeType>? positionalParameterTypes,
    this.requiredPositionalParameterCount = 0,
    Map<String, RuntimeType>? namedParameterTypes,
    Set<String>? requiredNamedParameters,
    this.typeParameterCount = 0,
    this.isUntyped = false,
  })  : returnType = returnType ?? _dynamicType,
        positionalParameterTypes =
            List.unmodifiable(positionalParameterTypes ?? const []),
        namedParameterTypes = Map.unmodifiable(namedParameterTypes ?? const {}),
        requiredNamedParameters =
            Set.unmodifiable(requiredNamedParameters ?? const {});

  factory FunctionRuntimeType.untyped() => FunctionRuntimeType(isUntyped: true);

  @override
  String get name {
    if (isUntyped &&
        positionalParameterTypes.isEmpty &&
        namedParameterTypes.isEmpty &&
        typeParameterCount == 0) {
      return 'Function';
    }

    final parts = <String>[];
    for (int index = 0; index < positionalParameterTypes.length; index++) {
      final parameterType = positionalParameterTypes[index];
      if (index == requiredPositionalParameterCount &&
          requiredPositionalParameterCount < positionalParameterTypes.length) {
        parts.add('[');
      }
      parts.add(parameterType.name);
      if (index < positionalParameterTypes.length - 1) {
        parts.add(', ');
      }
    }
    if (requiredPositionalParameterCount < positionalParameterTypes.length) {
      parts.add(']');
    }

    if (namedParameterTypes.isNotEmpty) {
      if (parts.isNotEmpty) {
        parts.add(', ');
      }
      parts.add('{');
      final namedEntries = namedParameterTypes.entries.toList()
        ..sort((left, right) => left.key.compareTo(right.key));
      for (int index = 0; index < namedEntries.length; index++) {
        final entry = namedEntries[index];
        if (requiredNamedParameters.contains(entry.key)) {
          parts.add('required ');
        }
        parts.add('${entry.value.name} ${entry.key}');
        if (index < namedEntries.length - 1) {
          parts.add(', ');
        }
      }
      parts.add('}');
    }

    final typeParameterSuffix = typeParameterCount > 0
        ? '<${List.filled(typeParameterCount, '_').join(', ')}>'
        : '';
    return '${returnType.name} Function$typeParameterSuffix(${parts.join()})';
  }

  @override
  bool isSubtypeOf(RuntimeType other, {Object? value}) {
    if (other.name == 'dynamic' || other.name == 'Object') {
      return true;
    }

    if (other.name == 'Function') {
      return true;
    }

    if (other is! FunctionRuntimeType) {
      return false;
    }

    if (other.isUntyped) {
      return true;
    }

    if (isUntyped) {
      return false;
    }

    if (typeParameterCount != other.typeParameterCount) {
      return false;
    }

    if (requiredPositionalParameterCount !=
            other.requiredPositionalParameterCount ||
        positionalParameterTypes.length !=
            other.positionalParameterTypes.length) {
      return false;
    }

    if (requiredNamedParameters.length !=
            other.requiredNamedParameters.length ||
        !requiredNamedParameters.containsAll(other.requiredNamedParameters) ||
        namedParameterTypes.length != other.namedParameterTypes.length) {
      return false;
    }

    for (final name in namedParameterTypes.keys) {
      if (!other.namedParameterTypes.containsKey(name)) {
        return false;
      }
    }

    if (!_isReturnTypeCompatible(returnType, other.returnType)) {
      return false;
    }

    for (int index = 0; index < positionalParameterTypes.length; index++) {
      if (!_isParameterTypeCompatible(positionalParameterTypes[index],
          other.positionalParameterTypes[index])) {
        return false;
      }
    }

    for (final entry in namedParameterTypes.entries) {
      if (!_isParameterTypeCompatible(
          entry.value, other.namedParameterTypes[entry.key]!)) {
        return false;
      }
    }

    return true;
  }

  bool _isReturnTypeCompatible(RuntimeType actual, RuntimeType expected) {
    if (expected.name == 'dynamic' || expected.name == 'Object') {
      return true;
    }

    return actual.isSubtypeOf(expected);
  }

  bool _isParameterTypeCompatible(RuntimeType actual, RuntimeType expected) {
    if (expected.name == 'dynamic' || expected.name == 'Object') {
      return true;
    }

    return expected.isSubtypeOf(actual);
  }

  @override
  String toString() => name;
}

/// A runtime type representing a record shape.
class RecordRuntimeType implements RuntimeType {
  final List<RuntimeType> positionalFieldTypes;
  final Map<String, RuntimeType> namedFieldTypes;

  RecordRuntimeType(
    List<RuntimeType> positionalFieldTypes,
    Map<String, RuntimeType> namedFieldTypes,
  )   : positionalFieldTypes = List.unmodifiable(positionalFieldTypes),
        namedFieldTypes = Map.unmodifiable(namedFieldTypes);

  @override
  String get name {
    if (positionalFieldTypes.isEmpty && namedFieldTypes.isEmpty) {
      return 'Record';
    }

    final parts = <String>[];
    for (int index = 0; index < positionalFieldTypes.length; index++) {
      parts.add(positionalFieldTypes[index].name);
      if (index < positionalFieldTypes.length - 1 ||
          namedFieldTypes.isNotEmpty) {
        parts.add(', ');
      }
    }

    if (namedFieldTypes.isNotEmpty) {
      parts.add('{');
      final namedEntries = namedFieldTypes.entries.toList()
        ..sort((left, right) => left.key.compareTo(right.key));
      for (int index = 0; index < namedEntries.length; index++) {
        final entry = namedEntries[index];
        parts.add('${entry.value.name} ${entry.key}');
        if (index < namedEntries.length - 1) {
          parts.add(', ');
        }
      }
      parts.add('}');
    }

    return '(${parts.join()})';
  }

  @override
  bool isSubtypeOf(RuntimeType other, {Object? value}) {
    if (other.name == 'dynamic' || other.name == 'Object') {
      return true;
    }

    if (other.name == 'Record') {
      return true;
    }

    if (other is! RecordRuntimeType) {
      return false;
    }

    if (positionalFieldTypes.length != other.positionalFieldTypes.length ||
        namedFieldTypes.length != other.namedFieldTypes.length) {
      return false;
    }

    for (final key in namedFieldTypes.keys) {
      if (!other.namedFieldTypes.containsKey(key)) {
        return false;
      }
    }

    for (int index = 0; index < positionalFieldTypes.length; index++) {
      if (!_isFieldTypeCompatible(
          positionalFieldTypes[index], other.positionalFieldTypes[index])) {
        return false;
      }
    }

    for (final entry in namedFieldTypes.entries) {
      if (!_isFieldTypeCompatible(
          entry.value, other.namedFieldTypes[entry.key]!)) {
        return false;
      }
    }

    return true;
  }

  bool _isFieldTypeCompatible(RuntimeType actual, RuntimeType expected) {
    if (expected.name == 'dynamic' || expected.name == 'Object') {
      return true;
    }

    return actual.isSubtypeOf(expected);
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
