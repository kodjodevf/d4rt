import 'package:d4rt/d4rt.dart';
import 'package:d4rt/src/bridge/bridged_enum.dart';
import 'package:d4rt/src/utils/extensions/string.dart';

class Environment {
  final Environment? _enclosing;
  final Map<String, Object?> _values = {};
  final Map<String, BridgedClass> _bridgedClasses = {};
  final Map<Type, BridgedClass> _bridgedClassesLookupByType = {};
  final Map<String, BridgedEnum> _bridgedEnums = {}; // Store bridged enums
  final List<InterpretedExtension> _unnamedExtensions =
      []; // Store unnamed extensions
  final Map<String, Environment> _prefixedImports = {}; // For prefixed imports

  Environment({Environment? enclosing}) : _enclosing = enclosing;

  Environment? get enclosing => _enclosing;
  Map<String, Object?> get values => _values;

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
    BridgedClass? bridgedClass = _bridgedClassesLookupByType[nativeType];

    String nativeTypeName = nativeType.toString();

    if (bridgedClass == null && (nativeTypeName.substring(0, 1) == '_')) {
      if (nativeTypeName.endsWith('Impl')) {
        nativeTypeName = nativeTypeName.substringBeforeLast('Impl');
      }
      bridgedClass = _bridgedClassesLookupByType.entries
          .firstWhereOrNull((e) =>
              (e.value.name ==
                  nativeTypeName.substring(1).substringBefore('<')) ||
              (e.value.nativeNames
                      ?.any((name) => nativeTypeName.startsWith(name)) ??
                  false))
          ?.value;
    } else if (bridgedClass == null && nativeTypeName.contains('<')) {
      bridgedClass = _bridgedClassesLookupByType.entries
          .firstWhereOrNull((e) => nativeTypeName.contains('${e.value.name}<'))
          ?.value;
    }
    bridgedClass ??= _bridgedClassesLookupByType.entries
        .firstWhereOrNull((e) =>
            (e.value.name == nativeTypeName) ||
            (e.value.nativeNames
                    ?.any((name) => nativeTypeName.startsWith(name)) ??
                false))
        ?.value;

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
        '[Env.get] Attempting to get "$name" in env: $hashCode'); // Log attempt + env hash

    // Check first if the name directly corresponds to a prefixed import.
    if (_prefixedImports.containsKey(name)) {
      Logger.debug(
          "[Env.get] Name '$name' corresponds to a prefixed import. Returning the prefixed environment.");
      return _prefixedImports[name]; // Return the Environment itself.
    }

    // Check if it's a prefixed access (ex: math.pi)
    if (name.contains('.')) {
      final parts = name.split('.');
      if (parts.length == 2) {
        final prefix = parts[0];
        final identifier = parts[1];
        if (_prefixedImports.containsKey(prefix)) {
          Logger.debug(
              "[Env.get] Prefixed access for '$name'. Searching for '$identifier' in the prefixed environment '$prefix'.");
          // Recursive call on the stored environment for the prefix.
          // No need to check _enclosing here, the prefixed environment will do that.
          try {
            return _prefixedImports[prefix]!.get(identifier);
          } on RuntimeError catch (e) {
            // If the identifier is not found in the prefixed environment, we want the original error to be propagated.
            // Or, according to the desired semantics, we could raise a new error indicating that 'identifier' was not found IN 'prefix'.
            throw RuntimeError(
                "Undefined name '$identifier' in imported prefix '$prefix'. Original error: ${e.message}");
          }
        } else {
          // The prefix itself is not found as a prefixed import.
          // We could fall into the normal search if 'prefix.identifier' is a valid variable name.
          // However, in Dart, an identifier cannot contain a '.' except for access.
          // So, if the prefix is not in _prefixedImports, it's an error.
          Logger.debug(
              "[Env.get] Prefix '$prefix' for '$name' not found in prefixed imports.");
        }
      } else {
        // Handle the case of multiple points, for example a.b.c. For now, we only support prefix.identifier.
        Logger.warn(
            "[Env.get] Name '$name' contains multiple points, not supported for simple prefixed access.");
        // Falling into the normal search could be an option, but let's raise an error for now
        // because it probably indicates an unexpected usage or an invalid variable name.
        throw RuntimeError(
            "Complex prefixed access not supported: $name. Use the form prefix.identifier.");
      }
    }

    // Normal search if there's no valid prefixed access or if the prefix is not resolved
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

    if (_enclosing != null) {
      Logger.debug(
          '[Env.get] Looking for \'$name\' in parent env: ${_enclosing.hashCode}');
      return _enclosing.get(name); // Recurse
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

    if (_enclosing != null) {
      Logger.debug(
          " [Env.assign] '$name' not found locally, assigning in parent env: ${_enclosing.hashCode}");
      return _enclosing.assign(
          name, value); // Delegate to the parent environment
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
    if (_enclosing != null) {
      return _enclosing.findDefiningEnvironment(name);
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
      current = current._enclosing;
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

  /// Creates a shallow copy of this environment, optionally filtering symbols.
  ///
  /// If [showNames] is provided, only symbols (values, bridged classes, enums, prefixed imports)
  /// whose names are in [showNames] will be included in the new environment.
  /// If [hideNames] is provided, all symbols will be included *except* those
  /// whose names are in [hideNames].
  ///
  /// It is an error to provide both [showNames] and [hideNames].
  /// Unnamed extensions are always copied.
  Environment shallowCopyFiltered({
    Set<String>? showNames,
    Set<String>? hideNames,
  }) {
    if (showNames != null && hideNames != null) {
      throw ArgumentError(
          'Cannot provide both showNames and hideNames to shallowCopyFiltered.');
    }

    final newEnv = Environment(enclosing: _enclosing);

    // Filter _values
    _values.forEach((name, value) {
      bool include = true;
      if (showNames != null) {
        include = showNames.contains(name);
      } else if (hideNames != null) {
        include = !hideNames.contains(name);
      }
      if (include) {
        newEnv._values[name] = value;
      }
    });

    // Filter _bridgedClasses and rebuild _bridgedClassesLookupByType
    _bridgedClasses.forEach((name, bridgedClass) {
      bool include = true;
      if (showNames != null) {
        include = showNames.contains(name);
      } else if (hideNames != null) {
        include = !hideNames.contains(name);
      }
      if (include) {
        newEnv._bridgedClasses[name] = bridgedClass;
        newEnv._bridgedClassesLookupByType[bridgedClass.nativeType] =
            bridgedClass;
      }
    });

    // Filter _bridgedEnums
    _bridgedEnums.forEach((name, bridgedEnum) {
      bool include = true;
      if (showNames != null) {
        include = showNames.contains(name);
      } else if (hideNames != null) {
        include = !hideNames.contains(name);
      }
      if (include) {
        newEnv._bridgedEnums[name] = bridgedEnum;
      }
    });

    // Filter _prefixedImports
    _prefixedImports.forEach((name, environment) {
      bool include = true;
      if (showNames != null) {
        include = showNames.contains(name);
      } else if (hideNames != null) {
        include = !hideNames.contains(name);
      }
      if (include) {
        newEnv._prefixedImports[name] =
            environment; // Copy the reference to the prefixed environment
      }
    });

    // Copy unnamed extensions (cannot be filtered by name)
    newEnv._unnamedExtensions.addAll(_unnamedExtensions);

    Logger.debug(
        "[Environment.shallowCopyFiltered] Created filtered environment. Original size: ${_values.length} values. New size: ${newEnv._values.length} values.");
    return newEnv;
  }

  /// Imports definitions from another environment into this one.
  /// Can be filtered using [show] or [hide] combinators.
  /// If no filter is provided, all symbols from [other] are merged.
  /// This method directly modifies the current environment.
  void importEnvironment(Environment other,
      {Set<String>? show, Set<String>? hide}) {
    if (show != null && hide != null) {
      throw ArgumentError(
          'Cannot provide both show and hide to importEnvironment.');
    }

    Environment sourceEnvToImportFrom;

    if (show != null || hide != null) {
      sourceEnvToImportFrom =
          other.shallowCopyFiltered(showNames: show, hideNames: hide);
      Logger.debug(
          "[Environment.importEnvironment] Importing from a filtered version of other env (hashCode: ${other.hashCode}).");
    } else {
      sourceEnvToImportFrom = other;
      Logger.debug(
          "[Environment.importEnvironment] Importing directly from other env (hashCode: ${other.hashCode}).");
    }

    // Perform the merge from sourceEnvToImportFrom
    sourceEnvToImportFrom._values.forEach((name, value) {
      if (_values.containsKey(name) ||
          _bridgedClasses.containsKey(name) ||
          _bridgedEnums.containsKey(name) ||
          _prefixedImports.containsKey(name)) {
        throw RuntimeError(
            "Name conflict in environment: Symbol '$name' is already defined.");
      }
      _values[name] = value;
    });

    sourceEnvToImportFrom._bridgedClasses.forEach((name, bridgedClass) {
      if (_values.containsKey(name) ||
          _bridgedClasses.containsKey(name) ||
          _bridgedEnums.containsKey(name) ||
          _prefixedImports.containsKey(name)) {
        throw RuntimeError(
            "Name conflict in environment: Symbol '$name' (bridged class) is already defined.");
      }
      _bridgedClasses[name] = bridgedClass;
      _bridgedClassesLookupByType[bridgedClass.nativeType] = bridgedClass;
    });

    sourceEnvToImportFrom._bridgedEnums.forEach((name, bridgedEnum) {
      if (_values.containsKey(name) ||
          _bridgedClasses.containsKey(name) ||
          _bridgedEnums.containsKey(name) ||
          _prefixedImports.containsKey(name)) {
        throw RuntimeError(
            "Name conflict in environment: Symbol '$name' (bridged enum) is already defined.");
      }
      _bridgedEnums[name] = bridgedEnum;
    });

    sourceEnvToImportFrom._prefixedImports.forEach((name, env) {
      if (_values.containsKey(name) ||
          _bridgedClasses.containsKey(name) ||
          _bridgedEnums.containsKey(name) ||
          _prefixedImports.containsKey(name)) {
        throw RuntimeError(
            "Name conflict in environment: Symbol '$name' (prefixed import) is already defined or collides with another symbol type.");
      }
      _prefixedImports[name] = env;
    });

    // Unnamed extensions are additive.
    _unnamedExtensions.addAll(sourceEnvToImportFrom._unnamedExtensions);

    Logger.debug(
        "[Environment.importEnvironment] Merge complete. Current env (hashCode: $hashCode) updated.");
  }

  // New method to handle prefixed imports
  void definePrefixedImport(String prefix, Environment importEnvironment) {
    Logger.debug(
        "[Env.definePrefixedImport] Defining prefixed import '$prefix' with environment $importEnvironment (hash: ${importEnvironment.hashCode})");
    _prefixedImports[prefix] = importEnvironment;
  }
}
