import 'package:d4rt/d4rt.dart';
import 'package:d4rt/src/bridge/bridged_enum.dart';

class Environment {
  final Environment? enclosing;
  final Map<String, Object?> _values = {};
  final Map<String, BridgedClass> _bridgedClasses = {};
  final Map<Type, BridgedClass> _bridgedClassesLookupByType = {};
  final Map<String, BridgedEnum> _bridgedEnums = {}; // Store bridged enums
  final List<InterpretedExtension> _unnamedExtensions =
      []; // Store unnamed extensions

  Environment({this.enclosing});

  void define(String name, Object? value) {
    if (_values.containsKey(name) ||
        _bridgedClasses.containsKey(name) ||
        _bridgedEnums.containsKey(name)) {
      // CHECK: Also check bridged enums
      Logger.warn("Redefining variable or colliding with bridged type: $name");
    }
    _values[name] = value;
  }

  void defineBridge(BridgedClassDefinition definition) {
    final bridgedClass = definition.buildBridgedClass();
    final name = bridgedClass.name;

    if (_values.containsKey(name) ||
        _bridgedClasses.containsKey(name) ||
        _bridgedEnums.containsKey(name)) {
      // CHECK: Also check bridged enums
      Logger.warn(
          "Redefining bridged class or colliding with existing definition: $name");
    }
    _bridgedClasses[name] = bridgedClass;
    _bridgedClassesLookupByType[bridgedClass.nativeType] = bridgedClass;
    Logger.debug("[Environment] Defined bridge for class: $name");
  }

  BridgedInstance? toBridgedInstance(Object? nativeObject) {
    if (nativeObject == null) {
      return null;
    }
    final bridgedClass = toBridgedClass(nativeObject.runtimeType);

    return BridgedInstance(bridgedClass, nativeObject);
  }

  BridgedClass toBridgedClass(Type nativeType) {
    final bridgedClass = _bridgedClassesLookupByType[nativeType];

    if (bridgedClass == null) {
      throw RuntimeError(
          'Cannot bridge native object: No registered bridged class found for native type $nativeType.');
    }
    return bridgedClass;
  }

  // Method to define bridged enums
  void defineBridgedEnum(BridgedEnum bridgedEnum) {
    final name = bridgedEnum.name;
    if (_values.containsKey(name) ||
        _bridgedClasses.containsKey(name) ||
        _bridgedEnums.containsKey(name)) {
      Logger.warn(
          "Redefining bridged enum or colliding with existing definition: $name");
    }
    _bridgedEnums[name] = bridgedEnum;
    Logger.debug("[Environment] Defined bridge for enum: $name");
  }

  /// Retrieves the value associated with [name].
  /// Searches the current environment, then recursively searches parent environments.
  /// Returns `null` if the name is not found in the entire chain.
  dynamic get(String name) {
    Logger.debug(
        '[Env.get] Attempting to get \'$name\' in env: $hashCode'); // Log attempt + env hash
    if (_values.containsKey(name)) {
      Logger.debug('[Env.get] Found \'$name\' locally in env: $hashCode');
      return _values[name];
    }

    if (_bridgedClasses.containsKey(name)) {
      Logger.debug(
          " [Env.get] Found bridged class '$name' locally in env: $hashCode");
      return _bridgedClasses[name];
    }

    // Check for bridged enums
    if (_bridgedEnums.containsKey(name)) {
      Logger.debug(
          " [Env.get] Found bridged enum '$name' locally in env: $hashCode");
      return _bridgedEnums[name];
    }

    if (enclosing != null) {
      Logger.debug(
          '[Env.get] Looking for \'$name\' in parent env: ${enclosing.hashCode}');
      return enclosing!.get(name); // Recurse
    }

    Logger.debug(
        '[Env.get] \'$name\' not found in env chain starting from: $hashCode (no parent)'); // Log chain end
    throw RuntimeError("Undefined variable: $name");
  }

  Object? assign(String name, Object? value) {
    Logger.debug(
        "[Env.assign] Attempting to assign '$name' = $value in env: $hashCode");
    if (_values.containsKey(name)) {
      Logger.debug(" [Env.assign] Assigned '$name' locally in env: $hashCode");
      _values[name] = value;
      return value;
    }

    if (_bridgedClasses.containsKey(name)) {
      throw RuntimeError("Cannot assign to the name of a bridged class: $name");
    }

    // Prevent assigning to bridged enum names
    if (_bridgedEnums.containsKey(name)) {
      throw RuntimeError("Cannot assign to the name of a bridged enum: $name");
    }

    if (enclosing != null) {
      Logger.debug(
          " [Env.assign] '$name' not found locally, assigning in parent env: ${enclosing.hashCode}");
      return enclosing!
          .assign(name, value); // Delegate to the parent environment
    }

    Logger.debug(
        "[Env.assign] Variable '$name' not found for assignment, throwing error.");
    throw RuntimeError("Assigning to undefined variable '$name'.");
  }

  // Check if a variable is defined in *this* specific scope
  bool isDefinedLocally(String name) {
    return _values.containsKey(name);
  }

  // Find the environment where a variable is defined
  Environment? findDefiningEnvironment(String name) {
    if (_values.containsKey(name)) {
      return this;
    }
    if (enclosing != null) {
      return enclosing!.findDefiningEnvironment(name);
    }
    return null; // Not found in this scope or any enclosing scope
  }

  // Method to add unnamed extensions
  void addUnnamedExtension(InterpretedExtension extension) {
    _unnamedExtensions.add(extension);
  }

  // Method to find applicable extension members (Placeholder)
  Callable? findExtensionMember(Object? target, String name,
      {InterpreterVisitor? visitor}) {
    final targetType = getRuntimeType(target); // Helper to get RuntimeType
    if (targetType == null) return null;
    // Search current environment and enclosing ones
    Environment? current = this;
    while (current != null) {
      // Check unnamed extensions
      for (final ext in current._unnamedExtensions) {
        if (targetType.isSubtypeOf(ext.onType)) {
          final member = ext.findMember(name);
          if (member != null) {
            Logger.debug(
                " [Environment] Found extension member '$name' in unnamed ext on ${ext.onType.name}");
            // Need to bind 'target' to the call somehow.
            // This will likely require returning a bound callable or modifying the call site.
            return member; // Return the raw callable for now
          }
        }
      }
      // Check named extensions (stored as values)
      for (final value in current._values.values) {
        if (value is InterpretedExtension) {
          if (targetType.isSubtypeOf(value.onType)) {
            final member = value.findMember(name);
            if (member != null) {
              Logger.debug(
                  "[Environment] Found extension member '$name' in named ext '${value.name}' on ${value.onType.name}");
              return member; // Return the raw callable
            }
          } else if (targetType is NativeFunction &&
              visitor != null &&
              value.onType is NativeFunction) {
            final valueType = value.onType as NativeFunction;
            if (valueType.name == targetType.name) {
              final member = value.findMember(name);
              if (member != null) {
                Logger.debug(
                    "[Environment] Found extension member '$name' in named ext '${value.name}' on ${value.onType.name}");
                return member; // Return the raw callable
              }
            }
          }
        }
      }
      current = current.enclosing;
    }
    return null; // Not found
  }

  // Placeholder helper to get RuntimeType - needs actual implementation
  RuntimeType? getRuntimeType(Object? value) {
    if (value is InterpretedInstance) {
      return value.klass; // InterpretedClass is a RuntimeType
    }
    if (value is BridgedInstance) {
      return value.bridgedClass; // BridgedClass is a RuntimeType
    }
    // Handle Dart primitive/core types by looking them up in the environment
    // Assumes core types (String, int, bool, List, Map, etc.) are registered as BridgedClass
    String? typeName;
    if (value == null) typeName = 'Null';
    if (value is String) typeName = 'String';
    if (value is int) typeName = 'int';
    if (value is double) typeName = 'double';
    if (value is bool) typeName = 'bool';
    if (value is List) typeName = 'List';
    if (value is Map) typeName = 'Map';

    if (typeName != null) {
      try {
        final typeObj = get(typeName); // Look up the type name
        if (typeObj is RuntimeType) {
          return typeObj;
        } else {
          Logger.warn(
              "[getRuntimeType] Found symbol '$typeName' but it's not a RuntimeType (${typeObj?.runtimeType})");
        }
      } on RuntimeError {
        Logger.warn(
            "[getRuntimeType] RuntimeType for primitive '$typeName' not found in environment.");
      }
    }

    return null; // Type couldn't be determined
  }
}
