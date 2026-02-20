import 'package:analyzer/dart/ast/ast.dart';
import 'package:d4rt/d4rt.dart';

/// Represents information about a declaration in the executed code.
/// This is the base class for all introspection results.
sealed class DeclarationInfo {
  /// The name of the declaration.
  final String name;

  /// The type of declaration (function, class, variable, enum, extension).
  String get declarationType;

  const DeclarationInfo({required this.name});

  @override
  String toString() => '$declarationType: $name';
}

/// Information about a function declaration.
class FunctionInfo extends DeclarationInfo {
  /// The number of required positional parameters.
  final int arity;

  /// Whether the function is asynchronous.
  final bool isAsync;

  /// Whether the function is a generator (sync* or async*).
  final bool isGenerator;

  /// The declared return type, if available.
  final String? returnType;

  /// Parameter names in order.
  final List<String> parameterNames;

  /// Named parameter names.
  final List<String> namedParameterNames;

  const FunctionInfo({
    required super.name,
    required this.arity,
    this.isAsync = false,
    this.isGenerator = false,
    this.returnType,
    this.parameterNames = const [],
    this.namedParameterNames = const [],
  });

  @override
  String get declarationType => 'function';

  @override
  String toString() {
    final params = [
      ...parameterNames,
      if (namedParameterNames.isNotEmpty) '{${namedParameterNames.join(', ')}}',
    ].join(', ');
    final returnStr = returnType != null ? ' -> $returnType' : '';
    final asyncStr = isAsync ? 'async ' : '';
    final genStr = isGenerator ? '* ' : '';
    return '$asyncStr${genStr}function $name($params)$returnStr';
  }
}

/// Information about a class declaration.
class ClassInfo extends DeclarationInfo {
  /// Names of the superclasses/superinterfaces.
  final List<String> superTypes;

  /// Names of implemented interfaces.
  final List<String> interfaces;

  /// Names of mixed-in mixins.
  final List<String> mixins;

  /// Method names defined in this class.
  final List<String> methods;

  /// Field names defined in this class.
  final List<String> fields;

  /// Constructor names (including named constructors).
  final List<String> constructors;

  /// Whether this is an abstract class.
  final bool isAbstract;

  const ClassInfo({
    required super.name,
    this.superTypes = const [],
    this.interfaces = const [],
    this.mixins = const [],
    this.methods = const [],
    this.fields = const [],
    this.constructors = const [],
    this.isAbstract = false,
  });

  @override
  String get declarationType => isAbstract ? 'abstract class' : 'class';

  @override
  String toString() {
    final buffer = StringBuffer('$declarationType $name');
    if (superTypes.isNotEmpty) {
      buffer.write(' extends ${superTypes.join(', ')}');
    }
    if (interfaces.isNotEmpty) {
      buffer.write(' implements ${interfaces.join(', ')}');
    }
    if (mixins.isNotEmpty) {
      buffer.write(' with ${mixins.join(', ')}');
    }
    return buffer.toString();
  }
}

/// Information about a variable declaration.
class VariableInfo extends DeclarationInfo {
  /// The declared type of the variable, if available.
  final String? declaredType;

  /// The current runtime type of the value.
  final String valueType;

  /// The current value (may be the actual value or a string representation).
  final Object? value;

  /// Whether the variable is final.
  final bool isFinal;

  /// Whether the variable is const.
  final bool isConst;

  /// Whether the variable is late.
  final bool isLate;

  const VariableInfo({
    required super.name,
    this.declaredType,
    required this.valueType,
    this.value,
    this.isFinal = false,
    this.isConst = false,
    this.isLate = false,
  });

  @override
  String get declarationType {
    if (isConst) return 'const';
    if (isFinal) return 'final';
    if (isLate) return 'late var';
    return 'var';
  }

  @override
  String toString() {
    final typeStr = declaredType ?? valueType;
    return '$declarationType $name: $typeStr = $value';
  }
}

/// Information about an enum declaration.
class EnumInfo extends DeclarationInfo {
  /// The enum values.
  final List<String> values;

  /// Methods defined in the enum.
  final List<String> methods;

  const EnumInfo({
    required super.name,
    required this.values,
    this.methods = const [],
  });

  @override
  String get declarationType => 'enum';

  @override
  String toString() => 'enum $name { ${values.join(', ')} }';
}

/// Information about an extension declaration.
class ExtensionInfo extends DeclarationInfo {
  /// The type this extension extends.
  final String onType;

  /// Methods defined in this extension.
  final List<String> methods;

  const ExtensionInfo({
    required super.name,
    required this.onType,
    this.methods = const [],
  });

  @override
  String get declarationType => 'extension';

  @override
  String toString() => 'extension $name on $onType';
}

/// Result of introspection containing all declarations found in the executed code.
class IntrospectionResult {
  /// All function declarations.
  final List<FunctionInfo> functions;

  /// All class declarations.
  final List<ClassInfo> classes;

  /// All variable declarations.
  final List<VariableInfo> variables;

  /// All enum declarations.
  final List<EnumInfo> enums;

  /// All extension declarations.
  final List<ExtensionInfo> extensions;

  const IntrospectionResult({
    this.functions = const [],
    this.classes = const [],
    this.variables = const [],
    this.enums = const [],
    this.extensions = const [],
  });

  /// Get all declarations as a single list.
  List<DeclarationInfo> get all => [
        ...functions,
        ...classes,
        ...variables,
        ...enums,
        ...extensions,
      ];

  /// Get a declaration by name, returns null if not found.
  DeclarationInfo? getByName(String name) {
    for (final decl in all) {
      if (decl.name == name) return decl;
    }
    return null;
  }

  /// Check if a declaration with the given name exists.
  bool contains(String name) => getByName(name) != null;

  @override
  String toString() {
    final buffer = StringBuffer('IntrospectionResult:\n');
    if (functions.isNotEmpty) {
      buffer.writeln('  Functions (${functions.length}):');
      for (final f in functions) {
        buffer.writeln('    - $f');
      }
    }
    if (classes.isNotEmpty) {
      buffer.writeln('  Classes (${classes.length}):');
      for (final c in classes) {
        buffer.writeln('    - $c');
      }
    }
    if (variables.isNotEmpty) {
      buffer.writeln('  Variables (${variables.length}):');
      for (final v in variables) {
        buffer.writeln('    - $v');
      }
    }
    if (enums.isNotEmpty) {
      buffer.writeln('  Enums (${enums.length}):');
      for (final e in enums) {
        buffer.writeln('    - $e');
      }
    }
    if (extensions.isNotEmpty) {
      buffer.writeln('  Extensions (${extensions.length}):');
      for (final e in extensions) {
        buffer.writeln('    - $e');
      }
    }
    return buffer.toString();
  }
}

/// Helper class to build introspection results from an environment.
class IntrospectionBuilder {
  /// Builds an IntrospectionResult from the given environment.
  /// Optionally takes a CompilationUnit to extract additional metadata.
  static IntrospectionResult buildFromEnvironment(
    Environment environment, {
    bool includeBuiltins = false,
    CompilationUnit? compilationUnit,
  }) {
    final functions = <FunctionInfo>[];
    final classes = <ClassInfo>[];
    final variables = <VariableInfo>[];
    final enums = <EnumInfo>[];
    final extensions = <ExtensionInfo>[];

    // Build a map of variable type metadata from the AST
    final variableTypeMap = <String, String>{};
    final processedExtensions = <String>{};

    if (compilationUnit != null) {
      // Extract variable type annotations from AST
      for (final declaration in compilationUnit.declarations) {
        if (declaration is TopLevelVariableDeclaration) {
          final typeAnnotation = declaration.variables.type;
          final typeName = typeAnnotation?.toSource();
          for (final variable in declaration.variables.variables) {
            if (typeName != null) {
              variableTypeMap[variable.name.lexeme] = typeName;
            }
          }
        } else if (declaration is ExtensionDeclaration) {
          // Handle extensions (including unnamed ones) from AST
          final extName = declaration.name?.lexeme ?? '';
          final onTypeNode = declaration.onClause?.extendedType;
          final onType = onTypeNode?.toSource() ?? 'unknown';
          final methodNames = <String>[];

          for (final member in declaration.members) {
            if (member is MethodDeclaration) {
              methodNames.add(member.name.lexeme);
            }
          }

          if (extName.isEmpty) {
            // Unnamed extension - create with generated name
            extensions.add(ExtensionInfo(
              name: '<unnamed extension on $onType>',
              onType: onType,
              methods: methodNames,
            ));
          }
          processedExtensions.add(extName);
        }
      }
    }

    // Process the environment values
    for (final entry in environment.values.entries) {
      final name = entry.key;
      final value = entry.value;

      // Skip internal/builtin names unless requested
      if (!includeBuiltins && _isBuiltinName(name)) {
        continue;
      }

      if (value is InterpretedFunction) {
        functions.add(_buildFunctionInfo(name, value));
      } else if (value is InterpretedClass) {
        classes.add(_buildClassInfo(name, value));
      } else if (value is InterpretedEnum) {
        enums.add(_buildEnumInfo(name, value));
      } else if (value is InterpretedExtension) {
        extensions.add(_buildExtensionInfo(name, value));
      } else {
        // It's a variable - use type metadata if available
        final declaredType = variableTypeMap[name];
        variables
            .add(_buildVariableInfo(name, value, declaredType: declaredType));
      }
    }

    return IntrospectionResult(
      functions: functions,
      classes: classes,
      variables: variables,
      enums: enums,
      extensions: extensions,
    );
  }

  static bool _isBuiltinName(String name) {
    // List of common builtin/stdlib names to filter out
    const builtins = {
      'print',
      'identical',
      'Object',
      'String',
      'int',
      'double',
      'bool',
      'List',
      'Map',
      'Set',
      'Future',
      'Stream',
      'Iterable',
      'Iterator',
      'Null',
      'num',
      'Type',
      'Symbol',
      'Function',
      'dynamic',
      'void',
      'Never',
    };
    return builtins.contains(name);
  }

  static FunctionInfo _buildFunctionInfo(
      String name, InterpretedFunction func) {
    // Extract parameter names using the new getters
    final paramNames = func.positionalParameterNames;
    final namedParamNames = func.namedParameterNames;

    return FunctionInfo(
      name: name,
      arity: func.arity,
      isAsync: func.isAsync,
      isGenerator: func.isGenerator || func.isAsyncGenerator,
      returnType: func.declaredReturnType?.name,
      parameterNames: paramNames,
      namedParameterNames: namedParamNames,
    );
  }

  static ClassInfo _buildClassInfo(String name, InterpretedClass klass) {
    final methods = <String>[];
    final fields = <String>[];
    final constructors = <String>[];
    final superTypes = <String>[];
    final interfaces = <String>[];
    final mixins = <String>[];

    // Extract methods (include getters and setters as methods)
    for (final methodName in klass.methods.keys) {
      methods.add(methodName);
    }
    for (final getterName in klass.getters.keys) {
      methods.add(getterName);
    }
    for (final setterName in klass.setters.keys) {
      if (!methods.contains(setterName)) {
        methods.add(setterName);
      }
    }
    // Include static methods as well
    for (final methodName in klass.staticMethods.keys) {
      methods.add(methodName);
    }

    // Extract fields from fieldDeclarations
    for (final fieldDecl in klass.fieldDeclarations) {
      for (final variable in fieldDecl.fields.variables) {
        fields.add(variable.name.lexeme);
      }
    }
    // Include static fields
    for (final fieldName in klass.staticFields.keys) {
      if (!fields.contains(fieldName)) {
        fields.add(fieldName);
      }
    }

    // Extract constructor names
    constructors.add(name); // Default constructor
    for (final ctorName in klass.constructors.keys) {
      if (ctorName != name && ctorName.isNotEmpty) {
        constructors.add(ctorName);
      }
    }

    // Extract superclass - add to superTypes
    if (klass.superclass != null) {
      superTypes.add(klass.superclass!.name);
    }

    // Extract interfaces - add to both superTypes and interfaces
    for (final iface in klass.interfaces) {
      interfaces.add(iface.name);
      if (!superTypes.contains(iface.name)) {
        superTypes.add(iface.name);
      }
    }

    // Extract mixins - add to both superTypes and mixins
    for (final mixin in klass.mixins) {
      mixins.add(mixin.name);
      if (!superTypes.contains(mixin.name)) {
        superTypes.add(mixin.name);
      }
    }

    return ClassInfo(
      name: name,
      superTypes: superTypes,
      interfaces: interfaces,
      mixins: mixins,
      methods: methods,
      fields: fields,
      constructors: constructors,
      isAbstract: klass.isAbstract,
    );
  }

  static EnumInfo _buildEnumInfo(String name, InterpretedEnum enumType) {
    final values = <String>[];
    final methods = <String>[];

    // Extract enum values
    for (final valueName in enumType.values.keys) {
      values.add(valueName);
    }

    // Extract methods
    for (final methodName in enumType.methods.keys) {
      methods.add(methodName);
    }

    return EnumInfo(
      name: name,
      values: values,
      methods: methods,
    );
  }

  static ExtensionInfo _buildExtensionInfo(
      String name, InterpretedExtension ext) {
    final methods = <String>[];

    // Extract methods
    for (final methodName in ext.members.keys) {
      methods.add(methodName);
    }

    return ExtensionInfo(
      name: name,
      onType: ext.onType.name,
      methods: methods,
    );
  }

  static VariableInfo _buildVariableInfo(String name, Object? value,
      {String? declaredType}) {
    String valueType;
    if (value == null) {
      valueType = 'Null';
    } else if (value is InterpretedInstance) {
      valueType = value.klass.name;
    } else if (value is BridgedInstance) {
      valueType = value.bridgedClass.name;
    } else {
      valueType = value.runtimeType.toString();
    }

    return VariableInfo(
      name: name,
      declaredType: declaredType,
      valueType: valueType,
      value: value,
    );
  }
}
