/// Transform Pipeline for Bridge Generator.
///
/// Applies a series of transformations to collected metadata:
/// - Type mapping (converting complex types)
/// - Filtering (removing unsupported constructs)
/// - Enrichment (adding bridge-specific information)
library;

import 'generator_config.dart';
import 'metadata_collector.dart';

// =============================================================================
// TRANSFORM RESULT
// =============================================================================

/// Result of transformation pipeline.
class TransformResult {
  /// Transformed classes ready for code generation.
  final List<BridgeableClass> classes;

  /// Transformed enums ready for code generation.
  final List<BridgeableEnum> enums;

  /// Transformed functions ready for code generation.
  final List<BridgeableFunction> functions;

  /// Warnings during transformation.
  final List<String> warnings;

  const TransformResult({
    required this.classes,
    required this.enums,
    required this.functions,
    required this.warnings,
  });
}

// =============================================================================
// BRIDGEABLE TYPES
// =============================================================================

/// A class ready for bridge code generation.
class BridgeableClass {
  /// Class name.
  final String name;

  /// Native type expression.
  final String nativeType;

  /// Whether has generic parameters.
  final bool isGeneric;

  /// Type arguments (with bounds).
  final String? typeArguments;

  /// Bridgeable constructors.
  final List<BridgeableConstructor> constructors;

  /// Bridgeable instance methods.
  final List<BridgeableMethod> methods;

  /// Bridgeable instance getters.
  final List<BridgeableGetter> getters;

  /// Bridgeable instance setters.
  final List<BridgeableSetter> setters;

  /// Bridgeable static methods.
  final List<BridgeableMethod> staticMethods;

  /// Bridgeable static getters.
  final List<BridgeableGetter> staticGetters;

  /// Bridgeable static setters.
  final List<BridgeableSetter> staticSetters;

  /// Documentation.
  final String? documentation;

  /// Required imports for this class.
  final Set<String> requiredImports;

  /// Custom library URI for registration.
  final String? libraryUri;

  const BridgeableClass({
    required this.name,
    required this.nativeType,
    this.isGeneric = false,
    this.typeArguments,
    this.constructors = const [],
    this.methods = const [],
    this.getters = const [],
    this.setters = const [],
    this.staticMethods = const [],
    this.staticGetters = const [],
    this.staticSetters = const [],
    this.documentation,
    this.requiredImports = const {},
    this.libraryUri,
  });
}

/// A bridgeable constructor.
class BridgeableConstructor {
  /// Constructor name (empty for default).
  final String name;

  /// Parameters with their bridge representations.
  final List<BridgeableParameter> parameters;

  /// Whether this is a factory constructor.
  final bool isFactory;

  /// Whether this is a const constructor.
  final bool isConst;

  /// Call expression template.
  final String callTemplate;

  const BridgeableConstructor({
    required this.name,
    this.parameters = const [],
    this.isFactory = false,
    this.isConst = false,
    required this.callTemplate,
  });
}

/// A bridgeable method.
class BridgeableMethod {
  /// Method name.
  final String name;

  /// Return type for bridge.
  final String returnType;

  /// Whether returns a value.
  final bool hasReturn;

  /// Parameters.
  final List<BridgeableParameter> parameters;

  /// Call expression template.
  final String callTemplate;

  /// Whether async.
  final bool isAsync;

  /// Type arguments for generic methods.
  final String? typeArguments;

  const BridgeableMethod({
    required this.name,
    required this.returnType,
    this.hasReturn = true,
    this.parameters = const [],
    required this.callTemplate,
    this.isAsync = false,
    this.typeArguments,
  });
}

/// A bridgeable getter.
class BridgeableGetter {
  /// Getter name.
  final String name;

  /// Return type for bridge.
  final String returnType;

  /// Access expression template.
  final String accessTemplate;

  const BridgeableGetter({
    required this.name,
    required this.returnType,
    required this.accessTemplate,
  });
}

/// A bridgeable setter.
class BridgeableSetter {
  /// Setter name.
  final String name;

  /// Parameter type.
  final String parameterType;

  /// Assignment expression template.
  final String assignTemplate;

  const BridgeableSetter({
    required this.name,
    required this.parameterType,
    required this.assignTemplate,
  });
}

/// A bridgeable operator.
class BridgeableOperator {
  /// Operator symbol.
  final String symbol;

  /// Operator name for map key.
  final String mapKey;

  /// Return type.
  final String returnType;

  /// Parameters (for binary operators).
  final List<BridgeableParameter> parameters;

  /// Call expression template.
  final String callTemplate;

  const BridgeableOperator({
    required this.symbol,
    required this.mapKey,
    required this.returnType,
    this.parameters = const [],
    required this.callTemplate,
  });
}

/// A bridgeable parameter.
class BridgeableParameter {
  /// Parameter name.
  final String name;

  /// Bridge type (after mapping).
  final String type;

  /// Whether required.
  final bool isRequired;

  /// Whether named.
  final bool isNamed;

  /// Default value expression.
  final String? defaultValue;

  /// Extraction expression (how to get from args).
  final String extractionExpr;

  const BridgeableParameter({
    required this.name,
    required this.type,
    this.isRequired = true,
    this.isNamed = false,
    this.defaultValue,
    required this.extractionExpr,
  });
}

/// A bridgeable enum.
class BridgeableEnum {
  /// Enum name.
  final String name;

  /// Enum values.
  final List<String> values;

  /// Bridgeable getters.
  final List<BridgeableGetter> getters;

  /// Bridgeable methods.
  final List<BridgeableMethod> methods;

  /// Bridgeable static getters.
  final List<BridgeableGetter> staticGetters;

  /// Bridgeable static methods.
  final List<BridgeableMethod> staticMethods;

  /// Bridgeable static setters.
  final List<BridgeableSetter> staticSetters;

  /// Optional library URI for registration.
  final String? libraryUri;

  /// Documentation.
  final String? documentation;

  const BridgeableEnum({
    required this.name,
    required this.values,
    this.getters = const [],
    this.methods = const [],
    this.staticGetters = const [],
    this.staticMethods = const [],
    this.staticSetters = const [],
    this.libraryUri,
    this.documentation,
  });
}

/// A bridgeable function.
class BridgeableFunction {
  /// Function name.
  final String name;

  /// Return type.
  final String returnType;

  /// Whether has return value.
  final bool hasReturn;

  /// Parameters.
  final List<BridgeableParameter> parameters;

  /// Call expression template.
  final String callTemplate;

  /// Whether async.
  final bool isAsync;

  /// Documentation.
  final String? documentation;

  const BridgeableFunction({
    required this.name,
    required this.returnType,
    this.hasReturn = true,
    this.parameters = const [],
    required this.callTemplate,
    this.isAsync = false,
    this.documentation,
  });
}

// =============================================================================
// TRANSFORM PIPELINE
// =============================================================================

/// Pipeline for transforming collected metadata.
class TransformPipeline {
  final GeneratorConfig config;
  final List<String> _warnings = [];

  /// Accumulated metadata from multiple files.
  final List<CollectedMetadata> _accumulated = [];

  /// Current type parameter bounds being processed.
  final Map<String, String> _currentBounds = {};

  TransformPipeline({required this.config});

  /// Transforms collected metadata into bridgeable structures.
  TransformResult transform(CollectedMetadata metadata) {
    _warnings.clear();

    final classes = metadata.classes
        .map(_transformClass)
        .whereType<BridgeableClass>()
        .toList();

    final enums =
        metadata.enums.map(_transformEnum).whereType<BridgeableEnum>().toList();

    final functions = metadata.functions
        .map(_transformFunction)
        .whereType<BridgeableFunction>()
        .toList();

    return TransformResult(
      classes: classes,
      enums: enums,
      functions: functions,
      warnings: List.unmodifiable(_warnings),
    );
  }

  /// Accumulates metadata from multiple sources.
  void accumulate(CollectedMetadata metadata) {
    _accumulated.add(metadata);
  }

  /// Transforms all accumulated metadata.
  TransformResult transformAccumulated() {
    final merged = _accumulated.fold(
      CollectedMetadata.empty,
      (prev, curr) => prev.merge(curr),
    );
    return transform(merged);
  }

  // -------------------------------------------------------------------------
  // CLASS TRANSFORMATION
  // -------------------------------------------------------------------------

  BridgeableClass? _transformClass(ClassMetadata meta) {
    // Filter unsupported classes
    if (meta.isAbstract && !config.includeAbstractClasses) {
      return null;
    }

    _currentBounds.clear();
    for (final tp in meta.typeParameters) {
      _currentBounds[tp.name] = tp.bound?.fullName ?? 'dynamic';
    }

    _positionalIndex = 0;

    final constructors = meta.constructors
        .map((c) => _transformConstructor(c, meta))
        .whereType<BridgeableConstructor>()
        .toList();

    final methods = <BridgeableMethod>[];

    for (final m in meta.methods) {
      if (m.isOperator && config.includeOperators) {
        final op = _transformOperator(m);
        if (op != null) {
          methods.add(op);
        }
      } else {
        methods.add(_transformMethod(m));
      }
    }

    final getters = meta.getters.map(_transformGetter).toList();
    final setters = meta.setters.map(_transformSetter).toList();

    // Add fields as getters and setters
    for (final field in meta.fields) {
      if (field.name.startsWith('_') && !config.includePrivateMembers) {
        continue;
      }
      getters.add(BridgeableGetter(
        name: field.name,
        returnType: _mapType(field.type.fullName),
        accessTemplate: 'target.${field.name}',
      ));
      if (!field.isFinal) {
        setters.add(BridgeableSetter(
          name: field.name,
          parameterType: _mapType(field.type.fullName),
          assignTemplate: 'target.${field.name} = value',
        ));
      }
    }

    final staticMethods = config.includeStaticMembers
        ? meta.staticMethods.map((m) => _transformMethod(m, meta.name)).toList()
        : <BridgeableMethod>[];

    final staticGetters = config.includeStaticMembers
        ? meta.staticGetters.map((g) => _transformGetter(g, meta.name)).toList()
        : <BridgeableGetter>[];

    final staticSetters = config.includeStaticMembers
        ? meta.staticSetters.map((s) => _transformSetter(s, meta.name)).toList()
        : <BridgeableSetter>[];

    // Add static fields as static getters and setters
    if (config.includeStaticMembers) {
      for (final field in meta.staticFields) {
        if (field.name.startsWith('_') && !config.includePrivateMembers) {
          continue;
        }
        staticGetters.add(BridgeableGetter(
          name: field.name,
          returnType: _mapType(field.type.fullName),
          accessTemplate: '${meta.name}.${field.name}',
        ));
        if (!field.isFinal && !field.isConst) {
          staticSetters.add(BridgeableSetter(
            name: field.name,
            parameterType: _mapType(field.type.fullName),
            assignTemplate: '${meta.name}.${field.name} = value',
          ));
        }
      }
    }

    final classTypeArgs = meta.typeParameters
        .map((tp) => tp.bound?.fullName ?? 'dynamic')
        .join(', ');

    return BridgeableClass(
      name: meta.name,
      nativeType: meta.name,
      isGeneric: meta.typeParameters.isNotEmpty,
      typeArguments: classTypeArgs.isNotEmpty ? classTypeArgs : null,
      constructors: constructors,
      methods: methods,
      getters: getters,
      setters: setters,
      staticMethods: staticMethods,
      staticGetters: staticGetters,
      staticSetters: staticSetters,
      libraryUri: _getLibraryUri(meta.annotations),
      documentation: meta.documentation,
    );
  }

  BridgeableConstructor? _transformConstructor(
      ConstructorMetadata meta, ClassMetadata classMeta) {
    if (classMeta.isAbstract && !meta.isFactory) {
      return null;
    }
    _positionalIndex = 0;
    final params = meta.parameters.map(_transformParameter).toList();

    final positionalArgs =
        params.where((p) => !p.isNamed).map((p) => p.extractionExpr).join(', ');

    final namedArgs = params.where((p) => p.isNamed).map((p) {
      return '${p.name}: ${p.extractionExpr}';
    }).join(', ');

    final allArgs = [
      if (positionalArgs.isNotEmpty) positionalArgs,
      if (namedArgs.isNotEmpty) namedArgs,
    ].join(', ');

    final typeArgs = classMeta.typeParameters
        .map((tp) => tp.bound?.fullName ?? 'dynamic')
        .join(', ');
    final typeArgsSuffix = typeArgs.isNotEmpty ? '<$typeArgs>' : '';

    final constructorName = meta.name.isEmpty ? '' : '.${meta.name}';
    final callTemplate =
        '${classMeta.name}$typeArgsSuffix$constructorName($allArgs)';

    return BridgeableConstructor(
      name: meta.name,
      parameters: params,
      isFactory: meta.isFactory,
      isConst: meta.isConst,
      callTemplate: callTemplate,
    );
  }

  BridgeableMethod _transformMethod(MethodMetadata meta, [String? className]) {
    final oldBounds = Map<String, String>.from(_currentBounds);
    for (final tp in meta.typeParameters) {
      _currentBounds[tp.name] = tp.bound?.fullName ?? 'dynamic';
    }

    _positionalIndex = 0; // Reset for each method

    final params = meta.parameters.map(_transformParameter).toList();

    final positionalArgs =
        params.where((p) => !p.isNamed).map((p) => p.extractionExpr).join(', ');

    final namedArgs = params.where((p) => p.isNamed).map((p) {
      return '${p.name}: ${p.extractionExpr}';
    }).join(', ');

    final allArgs = [
      if (positionalArgs.isNotEmpty) positionalArgs,
      if (namedArgs.isNotEmpty) namedArgs,
    ].join(', ');

    final typeArgs = meta.typeParameters
        .map((tp) => tp.bound?.fullName ?? 'dynamic')
        .join(', ');
    final typeArgsSuffix = typeArgs.isNotEmpty ? '<$typeArgs>' : '';

    final targetExpr = className ?? 'target';
    final callTemplate = '$targetExpr.${meta.name}$typeArgsSuffix($allArgs)';

    final result = BridgeableMethod(
      name: meta.name,
      returnType: _mapType(meta.returnType.fullName),
      hasReturn: meta.returnType.name != 'void',
      parameters: params,
      callTemplate: callTemplate,
      isAsync: meta.isAsync,
      typeArguments: typeArgs.isNotEmpty ? typeArgs : null,
    );

    _currentBounds.clear();
    _currentBounds.addAll(oldBounds);
    return result;
  }

  BridgeableGetter _transformGetter(GetterMetadata meta, [String? className]) {
    final targetExpr = className ?? 'target';
    return BridgeableGetter(
      name: meta.name,
      returnType: _mapType(meta.returnType.fullName),
      accessTemplate: '$targetExpr.${meta.name}',
    );
  }

  BridgeableSetter _transformSetter(SetterMetadata meta, [String? className]) {
    final targetExpr = className ?? 'target';
    return BridgeableSetter(
      name: meta.name,
      parameterType: _mapType(meta.parameterType.fullName),
      assignTemplate: '$targetExpr.${meta.name} = value',
    );
  }

  BridgeableMethod? _transformOperator(MethodMetadata meta) {
    if (meta.operatorSymbol == null) return null;

    _positionalIndex = 0; // Reset for each operator

    final originalSymbol = meta.operatorSymbol!;
    var symbol = originalSymbol;
    var methodName = originalSymbol;

    // Determine if it's a unary operator based on parameter count
    if (symbol == '-' && meta.parameters.isEmpty) {
      symbol = 'unary-';
      methodName = 'unary-';
    } else if (symbol == '~' && meta.parameters.isEmpty) {
      symbol = 'unary~';
      methodName = 'unary~';
    }

    final params = meta.parameters.map(_transformParameter).toList();

    String callTemplate;
    if (params.isEmpty) {
      // Unary operator - use special handling
      if (symbol == 'unary-') {
        callTemplate = '-(target)';
      } else if (symbol == 'unary~') {
        callTemplate = '~(target)';
      } else {
        callTemplate = '$symbol(target)';
      }
    } else if (symbol == '[]') {
      callTemplate = 'target[${params.first.extractionExpr}]';
    } else if (symbol == '[]=') {
      callTemplate =
          'target[${params.first.extractionExpr}] = ${params.last.extractionExpr}';
    } else {
      // Binary operator
      final param = params.first;
      callTemplate = '(target $symbol ${param.extractionExpr})';
    }

    return BridgeableMethod(
      name: methodName,
      returnType: _mapType(meta.returnType.fullName),
      parameters: params,
      callTemplate: callTemplate,
      isAsync: false,
    );
  }

  /// Check if a type is a Function type (callbacks, callable, etc.)
  /// These should NOT be wrapped with .asTarget<>()
  bool _isFunctionType(String type) {
    return type.contains('Function') ||
        type == 'Callable' ||
        type == 'InterpretedFunction' ||
        type.endsWith('Callback') ||
        type.startsWith('ValueChanged<') ||
        type.startsWith('AsyncValueSetter<') ||
        type.startsWith('AsyncValueGetter<') ||
        type.contains('Predicate');
  }

  /// Splits Map type arguments into key and value types.
  List<String> _splitMapTypes(String type) {
    // type is "Map<K, V>" or "Map<K, V>?"
    final start = type.indexOf('<');
    final end = type.lastIndexOf('>');
    if (start == -1 || end == -1) return ['dynamic', 'dynamic'];

    final inner = type.substring(start + 1, end);
    int depth = 0;
    for (int i = 0; i < inner.length; i++) {
      if (inner[i] == '<') depth++;
      if (inner[i] == '>') depth--;
      if (inner[i] == ',' && depth == 0) {
        return [
          inner.substring(0, i).trim(),
          inner.substring(i + 1).trim(),
        ];
      }
    }
    return ['dynamic', 'dynamic'];
  }

  /// Extracts the inner type from a generic collection (List, Set, etc.)
  String _getInnerType(String type, int prefixLength) {
    // type is "List<T>" or "List<T>?"
    final start = type.indexOf('<');
    final end = type.lastIndexOf('>');
    if (start == -1 || end == -1) return 'dynamic';
    return type.substring(start + 1, end);
  }

  BridgeableParameter _transformParameter(ParameterMetadata meta) {
    final rawType = _mapType(meta.type.fullName);
    // Replace generic parameters inside the type with dynamic (e.g., List<E> -> List<dynamic>)
    var type = _replaceGenericParametersWithDynamic(rawType);

    // Normalize dynamic? to dynamic (since dynamic is already nullable)
    if (type == 'dynamic?') {
      type = 'dynamic';
    }

    final index = meta.isNamed ? null : _positionalIndex++;

    // Check if it's a generic type parameter (K, V, T, etc.) or contains generic parameters
    final isGenericParam =
        _isGenericParameter(type) || _containsGenericParameters(type);

    // Check if it's a Function type (these are passed directly without wrapping)
    final isFunctionType = _isFunctionType(type);

    String extractionExpr;
    final paramName = meta.name;

    if (meta.isNamed) {
      if (meta.isRequired) {
        if (isFunctionType) {
          extractionExpr = _wrapFunctionType(
              "namedArgs.required<Callable>('$paramName')", type);
        } else if (type == 'dynamic' || isGenericParam) {
          extractionExpr = "namedArgs.required<dynamic>('$paramName')";
        } else if (type.startsWith('List<')) {
          final inner = _getInnerType(type, 5);
          extractionExpr = "namedArgs.asList<$inner>('$paramName')";
        } else if (type.startsWith('Map<')) {
          final parts = _splitMapTypes(type);
          extractionExpr =
              "namedArgs.asMap<${parts[0]}, ${parts[1]}>('$paramName')";
        } else if (type.startsWith('Set<')) {
          final inner = _getInnerType(type, 4);
          extractionExpr = "namedArgs.asSet<$inner>('$paramName')";
        } else if (type.startsWith('Iterable<')) {
          final inner = _getInnerType(type, 9);
          extractionExpr = "namedArgs.asList<$inner>('$paramName')";
        } else {
          extractionExpr = "namedArgs.required<$type>('$paramName')";
        }
      } else {
        final defaultVal = meta.defaultValue ?? 'null';
        if (isFunctionType) {
          extractionExpr =
              "namedArgs.containsKey('$paramName') ? ${_wrapFunctionType("namedArgs.required<Callable>('$paramName')", type)} : $defaultVal";
        } else if (type == 'dynamic' || isGenericParam) {
          if (defaultVal == 'null') {
            extractionExpr =
                "namedArgs.optionalNullable<dynamic>('$paramName')";
          } else {
            extractionExpr =
                "namedArgs.optional<dynamic>('$paramName', $defaultVal)";
          }
        } else if (type.startsWith('List<')) {
          final inner = _getInnerType(type, 5);
          extractionExpr = "namedArgs.asListOrNull<$inner>('$paramName')";
          if (defaultVal != 'null') {
            extractionExpr += " ?? $defaultVal";
          }
        } else if (type.startsWith('Map<')) {
          final parts = _splitMapTypes(type);
          extractionExpr =
              "namedArgs.asMapOrNull<${parts[0]}, ${parts[1]}>('$paramName')";
          if (defaultVal != 'null') {
            extractionExpr += " ?? $defaultVal";
          }
        } else if (type.startsWith('Set<')) {
          final inner = _getInnerType(type, 4);
          extractionExpr = "namedArgs.asSetOrNull<$inner>('$paramName')";
          if (defaultVal != 'null') {
            extractionExpr += " ?? $defaultVal";
          }
        } else if (type.startsWith('Iterable<')) {
          final inner = _getInnerType(type, 9);
          extractionExpr = "namedArgs.asListOrNull<$inner>('$paramName')";
          if (defaultVal != 'null') {
            extractionExpr += " ?? $defaultVal";
          }
        } else {
          if (defaultVal == 'null') {
            extractionExpr = "namedArgs.optionalNullable<$type>('$paramName')";
          } else {
            extractionExpr =
                "namedArgs.optional<$type>('$paramName', $defaultVal)";
          }
        }
      }
    } else {
      if (meta.isRequired) {
        if (isFunctionType) {
          extractionExpr = _wrapFunctionType(
              "positionalArgs.required<Callable>($index, '$paramName')", type);
        } else if (type == 'dynamic' || isGenericParam) {
          extractionExpr =
              "positionalArgs.required<dynamic>($index, '$paramName')";
        } else if (type.startsWith('List<')) {
          final inner = _getInnerType(type, 5);
          extractionExpr =
              "positionalArgs.asList<$inner>($index, '$paramName')";
        } else if (type.startsWith('Map<')) {
          final parts = _splitMapTypes(type);
          extractionExpr =
              "positionalArgs.extractMap<${parts[0]}, ${parts[1]}>($index, '$paramName')";
        } else if (type.startsWith('Set<')) {
          final inner = _getInnerType(type, 4);
          extractionExpr = "positionalArgs.asSet<$inner>($index, '$paramName')";
        } else if (type.startsWith('Iterable<')) {
          final inner = _getInnerType(type, 9);
          extractionExpr =
              "positionalArgs.asList<$inner>($index, '$paramName')";
        } else {
          extractionExpr =
              "positionalArgs.required<$type>($index, '$paramName')";
        }
      } else {
        final defaultVal = meta.defaultValue ?? 'null';
        if (isFunctionType) {
          final checkExpr = index == 0
              ? "positionalArgs.isNotEmpty"
              : "positionalArgs.length > $index";
          extractionExpr =
              "$checkExpr ? ${_wrapFunctionType("positionalArgs.required<Callable>($index, '$paramName')", type)} : $defaultVal";
        } else if (type == 'dynamic' || isGenericParam) {
          if (defaultVal == 'null') {
            extractionExpr =
                "positionalArgs.optionalNullable<dynamic>($index, '$paramName')";
          } else {
            extractionExpr =
                "positionalArgs.optional<dynamic>($index, '$paramName', $defaultVal)";
          }
        } else if (type.startsWith('List<')) {
          final inner = _getInnerType(type, 5);
          extractionExpr =
              "positionalArgs.asListOrNull<$inner>($index, '$paramName')";
          if (defaultVal != 'null') {
            extractionExpr += " ?? $defaultVal";
          }
        } else if (type.startsWith('Map<')) {
          final parts = _splitMapTypes(type);
          extractionExpr =
              "positionalArgs.extractMapOrNull<${parts[0]}, ${parts[1]}>($index, '$paramName')";
          if (defaultVal != 'null') {
            extractionExpr += " ?? $defaultVal";
          }
        } else if (type.startsWith('Set<')) {
          final inner = _getInnerType(type, 4);
          extractionExpr =
              "positionalArgs.asSetOrNull<$inner>($index, '$paramName')";
          if (defaultVal != 'null') {
            extractionExpr += " ?? $defaultVal";
          }
        } else if (type.startsWith('Iterable<')) {
          final inner = _getInnerType(type, 9);
          extractionExpr =
              "positionalArgs.asListOrNull<$inner>($index, '$paramName')";
          if (defaultVal != 'null') {
            extractionExpr += " ?? $defaultVal";
          }
        } else {
          if (defaultVal == 'null') {
            extractionExpr =
                "positionalArgs.optionalNullable<$type>($index, '$paramName')";
          } else {
            extractionExpr =
                "positionalArgs.optional<$type>($index, '$paramName', $defaultVal)";
          }
        }
      }
    }

    return BridgeableParameter(
      name: meta.name,
      type: type,
      isRequired: meta.isRequired,
      isNamed: meta.isNamed,
      defaultValue: meta.defaultValue,
      extractionExpr: extractionExpr,
    );
  }

  int _positionalIndex = 0;

  /// Wraps a Callable expression in a native Dart function closure.
  /// For example: (arg) => (expr).call(visitor, [arg]) as ReturnType
  String _wrapFunctionType(String callableExpr, String functionType) {
    // Normalize common Flutter types
    var normalizedType = functionType;
    if (normalizedType.startsWith('VoidCallback')) {
      normalizedType = 'void Function()';
    } else if (normalizedType.startsWith('AsyncCallback')) {
      normalizedType = 'Future<void> Function()';
    } else if (normalizedType.startsWith('ValueChanged<')) {
      final inner =
          normalizedType.substring(13, normalizedType.lastIndexOf('>'));
      normalizedType = 'void Function($inner)';
    } else if (normalizedType.startsWith('AsyncValueSetter<')) {
      final inner =
          normalizedType.substring(17, normalizedType.lastIndexOf('>'));
      normalizedType = 'Future<void> Function($inner)';
    } else if (normalizedType.startsWith('AsyncValueGetter<')) {
      final inner =
          normalizedType.substring(17, normalizedType.lastIndexOf('>'));
      normalizedType = 'Future<$inner> Function()';
    } else if (normalizedType.contains('ScrollNotificationPredicate')) {
      normalizedType = 'bool Function(ScrollNotification)';
    }

    // Default to dynamic Function if it's just "Function"
    if (normalizedType == 'Function') {
      return '(...args) => $callableExpr.call(visitor, args)';
    }

    // Extract return type (everything before "Function")
    final functionIndex = normalizedType.indexOf('Function');
    if (functionIndex == -1) {
      // If we still don't have "Function", it might be a custom typedef we don't know
      // Fallback to generic wrapper
      return '(arg) => $callableExpr.call(visitor, [arg])';
    }

    final returnType = normalizedType.substring(0, functionIndex).trim();
    final isAsync = returnType.startsWith('Future');
    final asyncKw = isAsync ? 'async ' : '';
    final awaitKw = isAsync ? 'await ' : '';

    // For void Function() - no return, no args
    if (normalizedType.endsWith('Function()')) {
      return '() $asyncKw=> $awaitKw $callableExpr.call(visitor, [])';
    }

    // For Function with parameters (e.g., "bool Function(int)", "T Function(int, String)")
    final openParen = normalizedType.indexOf('(');
    final closeParen = normalizedType.lastIndexOf(')');
    if (openParen > 0 && closeParen > openParen) {
      final paramsSpecs = normalizedType.substring(openParen + 1, closeParen);
      final paramList = paramsSpecs
          .split(',')
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();

      // Add cast to return type if not void or dynamic
      final callExpr = (returnType != 'void' &&
              returnType != 'dynamic' &&
              returnType.isNotEmpty)
          ? '($awaitKw $callableExpr.call(visitor, [%args%]) as $returnType)'
          : '$awaitKw $callableExpr.call(visitor, [%args%])';

      if (paramList.isEmpty) {
        return "() $asyncKw=> ${callExpr.replaceAll('%args%', '')}";
      }

      if (paramList.length == 1) {
        return "(arg) $asyncKw=> ${callExpr.replaceAll('%args%', 'arg')}";
      }

      // More parameters: generate them dynamically
      final argNames = List.generate(paramList.length, (i) => 'arg${i + 1}');
      final argsStr = argNames.join(', ');
      return "(${argNames.join(', ')}) $asyncKw=> ${callExpr.replaceAll('%args%', argsStr)}";
    }

    // Default fallback
    return '(arg) $asyncKw=> $awaitKw $callableExpr.call(visitor, [arg])';
  }

  // -------------------------------------------------------------------------
  // ENUM TRANSFORMATION
  // -------------------------------------------------------------------------

  BridgeableEnum _transformEnum(EnumMetadata meta) {
    final methods = <BridgeableMethod>[];
    final staticMethods = <BridgeableMethod>[];

    for (final m in meta.methods) {
      if (m.isStatic) {
        staticMethods.add(_transformMethod(m));
        continue;
      }

      if (m.isOperator && config.includeOperators) {
        final op = _transformOperator(m);
        if (op != null) {
          methods.add(op);
        }
      } else {
        methods.add(_transformMethod(m));
      }
    }

    final getters =
        meta.getters.where((g) => !g.isStatic).map(_transformGetter).toList();
    final staticGetters =
        meta.getters.where((g) => g.isStatic).map(_transformGetter).toList();
    final staticSetters =
        meta.setters.where((s) => s.isStatic).map(_transformSetter).toList();

    return BridgeableEnum(
      name: meta.name,
      values: meta.values.map((v) => v.name).toList(),
      getters: getters,
      methods: methods,
      staticGetters: staticGetters,
      staticMethods: staticMethods,
      staticSetters: staticSetters,
      libraryUri: _getLibraryUri(meta.annotations),
      documentation: meta.documentation,
    );
  }

  // -------------------------------------------------------------------------
  // FUNCTION TRANSFORMATION
  // -------------------------------------------------------------------------

  BridgeableFunction _transformFunction(FunctionMetadata meta) {
    _currentBounds.clear();
    for (final tp in meta.typeParameters) {
      _currentBounds[tp.name] = tp.bound?.fullName ?? 'dynamic';
    }

    _positionalIndex = 0;
    final params = meta.parameters.map(_transformParameter).toList();

    final positionalArgs =
        params.where((p) => !p.isNamed).map((p) => p.extractionExpr).join(', ');

    final namedArgs = params.where((p) => p.isNamed).map((p) {
      return '${p.name}: ${p.extractionExpr}';
    }).join(', ');

    final allArgs = [
      if (positionalArgs.isNotEmpty) positionalArgs,
      if (namedArgs.isNotEmpty) namedArgs,
    ].join(', ');

    final callTemplate = '${meta.name}($allArgs)';

    final result = BridgeableFunction(
      name: meta.name,
      returnType: _mapType(meta.returnType.fullName),
      hasReturn: meta.returnType.name != 'void',
      parameters: params,
      callTemplate: callTemplate,
      isAsync: meta.isAsync,
      documentation: meta.documentation,
    );

    _currentBounds.clear();
    return result;
  }

  // -------------------------------------------------------------------------
  // HELPERS
  // -------------------------------------------------------------------------

  /// Check if a type is a generic type parameter (e.g., T, K, V, R, E).
  /// Generic parameters are typically single uppercase letters, or short patterns
  /// like K2, V3, etc. They should be treated as dynamic.
  bool _isGenericParameter(String type) {
    // Single uppercase letter: T, K, V, R, E, U, S, etc.
    if (type.length == 1 && type[0].toUpperCase() == type[0]) {
      return true;
    }

    // Multi-letter patterns starting with uppercase: K2, V3, etc.
    if (type.length <= 3 && type[0].toUpperCase() == type[0]) {
      // Check if remaining characters are all digits
      for (int i = 1; i < type.length; i++) {
        final char = type[i];
        if (char.codeUnitAt(0) < 48 || char.codeUnitAt(0) > 57) {
          return false;
        }
      }
      return true;
    }

    return false;
  }

  /// Check if a type contains generic parameters (e.g., List&lt;T&gt;, R Function(T)).
  /// Types that contain generic parameters should be treated as dynamic.
  /// But NOT if it's a collection type like List, Map, Set with generic parameters.
  bool _containsGenericParameters(String type) {
    // Skip collection types - they should keep their structure (List<E>, Map<K,V>, etc.)
    if (type.startsWith('List<') ||
        type.startsWith('Map<') ||
        type.startsWith('Set<') ||
        type.startsWith('Iterable<') ||
        type.startsWith('Future<') ||
        type.startsWith('Stream<')) {
      return false;
    }

    // Check for uppercase letters that look like generic parameters in Function types
    final pattern = RegExp(r'[A-Z]\d?(?![a-z])');

    // If type contains patterns like <T>, (T), Function(T), etc., it has generics
    if (type.contains('<') || type.contains('(')) {
      return pattern.hasMatch(type);
    }

    return false;
  }

  /// Replace generic type parameters (like E, T, K, V) with 'dynamic' throughout a type.
  /// E.g., "List&lt;E&gt;" becomes "List&lt;dynamic&gt;", "R Function(T)" becomes "dynamic Function(dynamic)"
  String _replaceGenericParametersWithDynamic(String type) {
    // Replace single uppercase letter parameters and numbered ones (T, E, K, V, K2, V3, etc.)
    // but only when they look like type parameters
    return type.replaceAllMapped(
      RegExp(r'\b[A-Z]\d?\b'), // word boundary for safety
      (match) {
        final name = match.group(0)!;
        // Check if this looks like a generic parameter (single uppercase or with digits)
        if (_isGenericParameter(name)) {
          // Use the bound if available, otherwise default to dynamic
          return _currentBounds[name] ?? 'dynamic';
        }
        return name;
      },
    );
  }

  String _mapType(String type) {
    var result = type;

    // Apply custom type mappings
    if (config.typeMappings.containsKey(type)) {
      result = config.typeMappings[type]!;
    } else {
      // Handle nullable types
      final isNullable = type.endsWith('?');
      final baseType = isNullable ? type.substring(0, type.length - 1) : type;

      // Check for mapped base type
      if (config.typeMappings.containsKey(baseType)) {
        final mapped = config.typeMappings[baseType]!;
        result = isNullable ? '$mapped?' : mapped;
      }
    }

    // Replace generic parameters with dynamic/bounds
    result = _replaceGenericParametersWithDynamic(result);

    // Normalize dynamic? to dynamic (since dynamic is already nullable in Dart)
    if (result == 'dynamic?') {
      result = 'dynamic';
    }

    return result;
  }

  String? _getLibraryUri(List<AnnotationMetadata> annotations) {
    for (final ann in annotations) {
      if (ann.name == 'D4rtBridge') {
        final uri = ann.namedArguments['libraryUri'];
        if (uri != null) {
          // Strip quotes if they exist
          if ((uri.startsWith("'") && uri.endsWith("'")) ||
              (uri.startsWith('"') && uri.endsWith('"'))) {
            return uri.substring(1, uri.length - 1);
          }
          return uri;
        }
      }
    }
    return null;
  }
}
