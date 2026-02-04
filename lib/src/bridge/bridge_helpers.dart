/// Bridge Helpers - Fluent extensions for D4rt bridge operations.
/// ```
library;

import 'bridged_types.dart';

// =============================================================================
// ARGUMENT EXTRACTION EXTENSIONS
// =============================================================================

/// Extension for extracting positional arguments from bridge method calls.
extension BridgePositionalArgs on List<Object?> {
  /// Extracts a required argument at the given index with type checking.
  ///
  /// Throws [ArgumentError] if:
  /// - Index is out of bounds
  /// - Value is null (for non-nullable types)
  /// - Value cannot be cast to type T
  T required<T>(int index, String paramName, [String? context]) {
    final ctx = context != null ? ' in $context' : '';

    if (index >= length) {
      throw ArgumentError(
        'Missing required argument "$paramName"$ctx: '
        'expected at index $index but only $length arguments provided',
      );
    }

    final raw = this[index];
    final value = raw is BridgedInstance ? raw.nativeObject : raw;

    if (value == null && null is! T) {
      throw ArgumentError(
        'Argument "$paramName"$ctx cannot be null: expected $T',
      );
    }

    if (value is T) return value;

    // Handle num conversion for double/int
    if (T == double && value is num) return value.toDouble() as T;
    if (T == int && value is num) return value.toInt() as T;

    throw ArgumentError(
      'Invalid type for "$paramName"$ctx: '
      'expected $T, got ${value.runtimeType}',
    );
  }

  /// Extracts an optional argument at the given index with a default value.
  T optional<T>(int index, String paramName, T defaultValue) {
    if (index >= length) return defaultValue;

    final raw = this[index];
    if (raw == null) return defaultValue;

    final value = raw is BridgedInstance ? raw.nativeObject : raw;
    if (value is T) return value as T;
    return defaultValue;
  }

  /// Extracts an optional nullable argument at the given index.
  T? optionalNullable<T>(int index, String paramName) {
    if (index >= length) return null;

    final raw = this[index];
    if (raw == null) return null;

    final value = raw is BridgedInstance ? raw.nativeObject : raw;
    if (value is T) return value as T;
    return null;
  }

  /// Extracts a List argument with element type coercion.
  ///
  /// D4rt creates `List<Object?>` for list literals. This method
  /// coerces each element to the expected type.
  List<T> asList<T>(int index, String paramName, [String? context]) {
    final ctx = context != null ? ' in $context' : '';
    final raw = required<Object>(index, paramName, context);

    final value = raw is BridgedInstance ? raw.nativeObject : raw;

    if (value is! List) {
      throw ArgumentError(
        'Argument "$paramName"$ctx must be a List: got ${value.runtimeType}',
      );
    }

    if (value is List<T>) return value;

    try {
      return value.map<T>((e) {
        if (e is BridgedInstance) return e.nativeObject as T;
        return e as T;
      }).toList();
    } catch (e) {
      throw ArgumentError(
        'Cannot coerce List elements to $T for "$paramName"$ctx: $e',
      );
    }
  }

  /// Extracts an optional List argument with element type coercion.
  List<T>? asListOrNull<T>(int index, String paramName) {
    if (index >= length || this[index] == null) return null;
    return asList<T>(index, paramName);
  }

  /// Extracts a Set argument with element type coercion.
  Set<T> asSet<T>(int index, String paramName, [String? context]) {
    final list = asList<T>(index, paramName, context);
    return list.toSet();
  }

  /// Extracts an optional Set argument with element type coercion.
  Set<T>? asSetOrNull<T>(int index, String paramName) {
    if (index >= length || this[index] == null) return null;
    return asSet<T>(index, paramName);
  }

  /// Extracts a Map argument with key/value type coercion.
  /// (Alias for extractMap)
  Map<K, V> asMap<K, V>(int index, String paramName, [String? context]) =>
      extractMap<K, V>(index, paramName, context);

  /// Extracts an optional Map argument with key/value type coercion.
  /// (Alias for extractMapOrNull)
  Map<K, V>? asMapOrNull<K, V>(int index, String paramName) =>
      extractMapOrNull<K, V>(index, paramName);

  /// Extracts a Map argument with key/value type coercion.
  Map<K, V> extractMap<K, V>(int index, String paramName, [String? context]) {
    final ctx = context != null ? ' in $context' : '';
    final raw = required<Object>(index, paramName, context);

    final value = raw is BridgedInstance ? raw.nativeObject : raw;

    if (value is! Map) {
      throw ArgumentError(
        'Argument "$paramName"$ctx must be a Map: got ${value.runtimeType}',
      );
    }

    if (value is Map<K, V>) return value;

    try {
      return value.map<K, V>((k, v) {
        final key = k is BridgedInstance ? k.nativeObject as K : k as K;
        final val = v is BridgedInstance ? v.nativeObject as V : v as V;
        return MapEntry(key, val);
      });
    } catch (e) {
      throw ArgumentError(
        'Cannot coerce Map to Map<$K, $V> for "$paramName"$ctx: $e',
      );
    }
  }

  /// Extracts an optional Map argument with key/value type coercion.
  Map<K, V>? extractMapOrNull<K, V>(int index, String paramName) {
    if (index >= length || this[index] == null) return null;
    return extractMap<K, V>(index, paramName);
  }

  /// Validates that at least [count] arguments were provided.
  void requireCount(int count, [String? context]) {
    if (length < count) {
      final ctx = context != null ? ' for $context' : '';
      throw ArgumentError(
        'Expected at least $count arguments$ctx, got $length',
      );
    }
  }

  /// Validates that exactly [count] arguments were provided.
  void requireExactCount(int count, [String? context]) {
    if (length != count) {
      final ctx = context != null ? ' for $context' : '';
      throw ArgumentError(
        'Expected exactly $count arguments$ctx, got $length',
      );
    }
  }
}

// =============================================================================
// NAMED ARGUMENT EXTENSIONS
// =============================================================================

/// Extension for extracting named arguments from bridge method calls.
extension BridgeNamedArgs on Map<String, Object?> {
  /// Extracts a required named argument with type checking.
  T required<T>(String name, [String? context]) {
    final ctx = context != null ? ' in $context' : '';

    if (!containsKey(name)) {
      throw ArgumentError('Missing required named argument "$name"$ctx');
    }

    final raw = this[name];
    final value = raw is BridgedInstance ? raw.nativeObject : raw;

    if (value == null && null is! T) {
      throw ArgumentError(
        'Named argument "$name"$ctx cannot be null: expected $T',
      );
    }

    if (value is T) return value;

    // Handle num conversion for double/int
    if (T == double && value is num) return value.toDouble() as T;
    if (T == int && value is num) return value.toInt() as T;

    throw ArgumentError(
      'Invalid type for named argument "$name"$ctx: '
      'expected $T, got ${value.runtimeType}',
    );
  }

  /// Extracts an optional named argument with a default value.
  T optional<T>(String name, T defaultValue) {
    if (!containsKey(name)) return defaultValue;

    final raw = this[name];
    if (raw == null) return defaultValue;

    final value = raw is BridgedInstance ? raw.nativeObject : raw;
    if (value is T) return value as T;
    return defaultValue;
  }

  /// Extracts an optional nullable named argument.
  T? optionalNullable<T>(String name) {
    if (!containsKey(name)) return null;

    final raw = this[name];
    if (raw == null) return null;

    final value = raw is BridgedInstance ? raw.nativeObject : raw;
    if (value is T) return value as T;
    return null;
  }

  /// Extracts a List named argument with element type coercion.
  List<T> asList<T>(String name, [String? context]) {
    final ctx = context != null ? ' in $context' : '';
    final raw = required<Object>(name, context);

    final value = raw is BridgedInstance ? raw.nativeObject : raw;

    if (value is! List) {
      throw ArgumentError(
        'Named argument "$name"$ctx must be a List: got ${value.runtimeType}',
      );
    }

    if (value is List<T>) return value;

    try {
      return value.map<T>((e) {
        if (e is BridgedInstance) return e.nativeObject as T;
        return e as T;
      }).toList();
    } catch (e) {
      throw ArgumentError(
        'Cannot coerce List elements to $T for named argument "$name"$ctx: $e',
      );
    }
  }

  /// Extracts an optional List named argument with element type coercion.
  List<T>? asListOrNull<T>(String name) {
    if (!containsKey(name) || this[name] == null) return null;
    return asList<T>(name);
  }

  /// Extracts a Map named argument with key/value type coercion.
  Map<K, V> asMap<K, V>(String name, [String? context]) {
    final ctx = context != null ? ' in $context' : '';
    final raw = required<Object>(name, context);

    final value = raw is BridgedInstance ? raw.nativeObject : raw;

    if (value is! Map) {
      throw ArgumentError(
        'Named argument "$name"$ctx must be a Map: got ${value.runtimeType}',
      );
    }

    if (value is Map<K, V>) return value;

    try {
      return value.map<K, V>((k, v) {
        final key = k is BridgedInstance ? k.nativeObject as K : k as K;
        final val = v is BridgedInstance ? v.nativeObject as V : v as V;
        return MapEntry(key, val);
      });
    } catch (e) {
      throw ArgumentError(
        'Cannot coerce Map to Map<$K, $V> for named argument "$name"$ctx: $e',
      );
    }
  }

  /// Extracts an optional Map named argument with key/value type coercion.
  Map<K, V>? asMapOrNull<K, V>(String name) {
    if (!containsKey(name) || this[name] == null) return null;
    return asMap<K, V>(name);
  }

  /// Extracts a Map named argument with key/value type coercion.
  /// (Alias for asMap)
  Map<K, V> extractMap<K, V>(String name, [String? context]) =>
      asMap<K, V>(name, context);

  /// Extracts an optional Map named argument with key/value type coercion.
  /// (Alias for asMapOrNull)
  Map<K, V>? extractMapOrNull<K, V>(String name) => asMapOrNull<K, V>(name);

  /// Extracts a Set named argument with element type coercion.
  Set<T> asSet<T>(String name, [String? context]) {
    final list = asList<T>(name, context);
    return list.toSet();
  }

  /// Extracts an optional Set named argument with element type coercion.
  Set<T>? asSetOrNull<T>(String name) {
    if (!containsKey(name) || this[name] == null) return null;
    return asSet<T>(name);
  }

  /// Validates that all required named arguments are present.
  void requireKeys(List<String> keys, [String? context]) {
    final missing = keys.where((k) => !containsKey(k)).toList();
    if (missing.isNotEmpty) {
      final ctx = context != null ? ' in $context' : '';
      throw ArgumentError(
        'Missing required named arguments$ctx: ${missing.join(', ')}',
      );
    }
  }
}

// =============================================================================
// INSTANCE VALIDATION EXTENSIONS
// =============================================================================

/// Extension for validating and extracting bridge instance targets.
extension BridgeInstanceValidation on Object? {
  /// Validates and extracts the native object from a bridge target.
  ///
  /// Handles both raw instances and BridgedInstance wrappers.
  T asTarget<T>(String className) {
    if (this == null) {
      throw ArgumentError(
        'Cannot invoke instance method on null target for $className',
      );
    }

    final target = this!;

    if (target is BridgedInstance) {
      final native = target.nativeObject;
      if (native is T) return native as T;

      throw ArgumentError(
        'Invalid target type for $className: '
        'expected $T, got ${native.runtimeType}',
      );
    }

    if (target is T) return target as T;

    throw ArgumentError(
      'Invalid target type for $className: expected $T, got ${target.runtimeType}',
    );
  }

  /// Coerces this value to type T, unwrapping BridgedInstance if necessary.
  T coerce<T>(String paramName, [String? context]) {
    final value =
        this is BridgedInstance ? (this as BridgedInstance).nativeObject : this;

    if (value == null && null is! T) {
      final ctx = context != null ? ' in $context' : '';
      throw ArgumentError(
          'Argument "$paramName"$ctx cannot be null: expected $T');
    }

    if (value is T) return value;

    // Handle num conversion for double/int
    if (T == double && value is num) return value.toDouble() as T;
    if (T == int && value is num) return value.toInt() as T;

    final ctx = context != null ? ' in $context' : '';
    throw ArgumentError(
      'Invalid type for "$paramName"$ctx: expected $T, got ${value.runtimeType}',
    );
  }
}
