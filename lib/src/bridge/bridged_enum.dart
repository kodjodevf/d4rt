import 'package:d4rt/d4rt.dart';
import 'package:d4rt/src/module_loader.dart';

/// Represents an enum type defined in the host Dart environment and bridged into the interpreter.
/// It holds the definition and provides access to its values.
class BridgedEnum implements RuntimeType {
  /// The name of the enum.
  @override
  final String name;

  /// A map of the enum's value names to their corresponding BridgedEnumValue instances.
  final Map<String, BridgedEnumValue> values;

  /// Instance getter adapters (shared by all values).
  Map<String, BridgedInstanceGetterAdapter> instanceGetterAdapters = {};

  /// Instance method adapters (shared by all values).
  Map<String, BridgedMethodAdapter> instanceMethodAdapters = {};

  /// Creates a definition for a bridged enum.
  BridgedEnum(this.name, this.values);

  @override
  String toString() => 'BridgedEnum($name)';

  @override
  bool isSubtypeOf(RuntimeType other) {
    return other.name == 'Object' || other == this;
  }

  /// Retrieves an enum value by its name.
  BridgedEnumValue? getValue(String valueName) {
    return values[valueName];
  }

  /// Returns the list of all values for this enum.
  List<BridgedEnumValue> get enumValues => values.values.toList();
}

/// Represents a specific value of a [BridgedEnum].
/// It holds the value's name, index, and the original native enum value.
class BridgedEnumValue implements RuntimeValue {
  /// The [BridgedEnum] definition this value belongs to.
  final BridgedEnum enumType;

  /// The name of the enum value (e.g., 'red' for Color.red).
  final String name;

  /// The index of the enum value in its definition order.
  final int index;

  /// The original native Dart enum value.
  final Object nativeValue;

  /// Instance getter adapters (potentially specific to this value if needed in the future,
  /// but currently shared via BridgedEnum).
  final Map<String, BridgedInstanceGetterAdapter> _instanceGetterAdapters;

  /// Instance method adapters.
  final Map<String, BridgedMethodAdapter> _instanceMethodAdapters;

  BridgedEnumValue(this.enumType, this.name, this.index, this.nativeValue,
      {Map<String, BridgedInstanceGetterAdapter>?
          getters, // Rendre optionnels ici
      Map<String, BridgedMethodAdapter>? methods})
      : _instanceGetterAdapters = getters ?? {},
        _instanceMethodAdapters = methods ?? {};

  // Implement the required getter from RuntimeValue
  @override
  RuntimeType get valueType => enumType;

  @override
  Object? get(String identifier) {
    // Access standard enum properties
    switch (identifier) {
      case 'index':
        return index;
      case 'name':
        return name;
      // 'toString' is handled below via adapters or the invoke method
      default:
        // 1. Check for custom instance getters
        final getterAdapter = _instanceGetterAdapters[identifier] ??
            enumType.instanceGetterAdapters[identifier];
        if (getterAdapter != null) {
          try {
            // Note: The visitor is null here because get() has no visitor context.
            // If the adapter needs the visitor, the interface will need to be revised.
            return getterAdapter(null, nativeValue);
          } catch (e) {
            throw RuntimeError(
                'Error executing bridged getter "$identifier" on ${enumType.name}.$name: $e');
          }
        }

        // 2. Check for instance methods (for cases like .toString() called as a getter)
        // Or to return a callable function representing the method.
        final methodAdapter = _instanceMethodAdapters[identifier] ??
            enumType.instanceMethodAdapters[identifier];
        if (methodAdapter != null) {
          // Return a function that wraps the bridged method call
          // (or handle directly if it's a getter disguised as a method, like toString)
          if (identifier == 'toString') {
            // Special case for toString() via get
            // We could call the toString adapter if it exists, otherwise fallback
            try {
              // Try to call the toString adapter (which should not need args)
              return methodAdapter(
                  InterpreterVisitor(
                      globalEnvironment: Environment(),
                      moduleLoader: ModuleLoader(Environment(), {}, [], [])),
                  nativeValue,
                  [],
                  {});
            } catch (_) {
              // Fallback if the adapter does not exist or fails
              return '${enumType.name}.$name';
            }
          }
          // For other methods, we could return a callable function here if needed.
          // For now, throw an error if trying to access a method via get.
          throw RuntimeError(
              'Cannot access method "$identifier" as a property on enum value ${enumType.name}.$name. Use call syntax ().');
        }

        // 3. If it's neither a standard property, nor a custom getter/method
        throw RuntimeError(
            'Property "$identifier" not found on enum value ${enumType.name}.$name');
    }
  }

  @override
  void set(String identifier, Object? value) {
    // Enum values are typically immutable
    throw RuntimeError(
        'Cannot set property "$identifier" on enum value ${enumType.name}.$name');
  }

  Object? invoke(InterpreterVisitor visitor, String method, List<Object?> args,
      Map<String, Object?> namedArgs) {
    final methodAdapter = _instanceMethodAdapters[method] ??
        enumType.instanceMethodAdapters[method];
    if (methodAdapter == null) {
      // Special case: if calling .toString() and there is no specific adapter,
      // return the standard representation.
      if (method == 'toString' && args.isEmpty && namedArgs.isEmpty) {
        return '${enumType.name}.$name';
      }
      throw RuntimeError(
          'Method "$method" not found on enum value ${enumType.name}.$name');
    }

    try {
      // Call the bridged method adapter
      return methodAdapter(
        visitor, // Pass the visitor
        nativeValue, // The native enum object is the target
        args, // Interpreted positional arguments
        namedArgs, // Interpreted named arguments (if supported by the adapter)
      );
    } catch (e) {
      throw RuntimeError(
          'Error executing bridged method "$method" on ${enumType.name}.$name: $e');
    }
  }

  @override
  String toString() {
    // Try to call the toString() adapter if it exists
    final toStringAdapter = _instanceMethodAdapters['toString'] ??
        enumType.instanceMethodAdapters['toString'];
    if (toStringAdapter != null) {
      try {
        // Call without specific visitor or argument here, as it's just for representation
        return toStringAdapter(
            InterpreterVisitor(
                globalEnvironment: Environment(),
                moduleLoader: ModuleLoader(Environment(), {}, [], [])),
            nativeValue,
            [],
            {}).toString();
      } catch (_) {
        // Fallback if the adapter fails
        return '${enumType.name}.$name (native toString failed)';
      }
    }
    // Provide a default representation if no toString adapter is provided
    return '${enumType.name}.$name';
  }

  // Consider adding equality checks based on nativeValue or index/type if needed
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BridgedEnumValue &&
          runtimeType == other.runtimeType &&
          // Compare bridged enum types by name to avoid instance issues
          enumType.name == other.enumType.name &&
          index == other.index &&
          nativeValue == other.nativeValue; // Compare native values too

  @override
  int get hashCode =>
      enumType.name.hashCode ^ index.hashCode ^ nativeValue.hashCode;
}
