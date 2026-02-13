/// Metadata Collector for Bridge Generator.
///
/// Extracts structured metadata from Dart source files including:
/// - Class information (constructors, methods, fields)
/// - Enum definitions
/// - Top-level functions
/// - Type information
library;

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'generator_config.dart';

// =============================================================================
// COLLECTED METADATA
// =============================================================================

/// Complete metadata collected from a source file.
class CollectedMetadata {
  /// Source file path.
  final String? sourcePath;

  /// Collected classes.
  final List<ClassMetadata> classes;

  /// Collected enums.
  final List<EnumMetadata> enums;

  /// Collected top-level functions.
  final List<FunctionMetadata> functions;

  /// Collected top-level variables.
  final List<VariableMetadata> variables;

  /// Imports in the source file.
  final List<String> imports;

  /// Warnings during collection.
  final List<String> warnings;

  const CollectedMetadata({
    this.sourcePath,
    required this.classes,
    required this.enums,
    required this.functions,
    required this.variables,
    required this.imports,
    this.warnings = const [],
  });

  /// Empty metadata.
  static const empty = CollectedMetadata(
    classes: [],
    enums: [],
    functions: [],
    variables: [],
    imports: [],
  );

  /// Merges two metadata collections.
  CollectedMetadata merge(CollectedMetadata other) {
    return CollectedMetadata(
      sourcePath: sourcePath ?? other.sourcePath,
      classes: [...classes, ...other.classes],
      enums: [...enums, ...other.enums],
      functions: [...functions, ...other.functions],
      variables: [...variables, ...other.variables],
      imports: {...imports, ...other.imports}.toList(),
      warnings: [...warnings, ...other.warnings],
    );
  }
}

// =============================================================================
// CLASS METADATA
// =============================================================================

/// Metadata for a class.
class ClassMetadata {
  /// Class name.
  final String name;

  /// Documentation comment.
  final String? documentation;

  /// Whether the class is abstract.
  final bool isAbstract;

  /// Generic type parameters.
  final List<TypeParameterMetadata> typeParameters;

  /// Superclass name (if any).
  final String? superclass;

  /// Implemented interfaces.
  final List<String> interfaces;

  /// Mixed-in types.
  final List<String> mixins;

  /// Constructors.
  final List<ConstructorMetadata> constructors;

  /// Instance methods.
  final List<MethodMetadata> methods;

  /// Instance getters.
  final List<GetterMetadata> getters;

  /// Instance setters.
  final List<SetterMetadata> setters;

  /// Static methods.
  final List<MethodMetadata> staticMethods;

  /// Static getters.
  final List<GetterMetadata> staticGetters;

  /// Static setters.
  final List<SetterMetadata> staticSetters;

  /// Instance fields.
  final List<FieldMetadata> fields;

  /// Static fields.
  final List<FieldMetadata> staticFields;

  /// Annotations on the class.
  final List<AnnotationMetadata> annotations;

  /// Source location.
  final SourceLocation? location;

  const ClassMetadata({
    required this.name,
    this.documentation,
    this.isAbstract = false,
    this.typeParameters = const [],
    this.superclass,
    this.interfaces = const [],
    this.mixins = const [],
    this.constructors = const [],
    this.methods = const [],
    this.getters = const [],
    this.setters = const [],
    this.staticMethods = const [],
    this.staticGetters = const [],
    this.staticSetters = const [],
    this.fields = const [],
    this.staticFields = const [],
    this.annotations = const [],
    this.location,
  });

  /// Whether this class has any bridgeable members.
  bool get hasBridgeableMembers =>
      constructors.isNotEmpty ||
      methods.isNotEmpty ||
      getters.isNotEmpty ||
      setters.isNotEmpty;
}

// =============================================================================
// ENUM METADATA
// =============================================================================

/// Metadata for an enum.
class EnumMetadata {
  /// Enum name.
  final String name;

  /// Documentation comment.
  final String? documentation;

  /// Enum values.
  final List<EnumValueMetadata> values;

  /// Methods defined on the enum.
  final List<MethodMetadata> methods;

  /// Getters defined on the enum.
  final List<GetterMetadata> getters;

  /// Setters defined on the enum.
  final List<SetterMetadata> setters;

  /// Annotations on the enum.
  final List<AnnotationMetadata> annotations;

  /// Source location.
  final SourceLocation? location;

  const EnumMetadata({
    required this.name,
    this.documentation,
    required this.values,
    this.methods = const [],
    this.getters = const [],
    this.setters = const [],
    this.annotations = const [],
    this.location,
  });
}

/// Metadata for an enum value.
class EnumValueMetadata {
  /// Value name.
  final String name;

  /// Documentation comment.
  final String? documentation;

  /// Constructor arguments (for enhanced enums).
  final List<String> arguments;

  const EnumValueMetadata({
    required this.name,
    this.documentation,
    this.arguments = const [],
  });
}

// =============================================================================
// FUNCTION METADATA
// =============================================================================

/// Metadata for a function (top-level or method).
class FunctionMetadata {
  /// Function name.
  final String name;

  /// Documentation comment.
  final String? documentation;

  /// Return type.
  final TypeMetadata returnType;

  /// Parameters.
  final List<ParameterMetadata> parameters;

  /// Generic type parameters.
  final List<TypeParameterMetadata> typeParameters;

  /// Whether async.
  final bool isAsync;

  /// Whether a generator (sync* or async*).
  final bool isGenerator;

  /// Annotations.
  final List<AnnotationMetadata> annotations;

  /// Source location.
  final SourceLocation? location;

  const FunctionMetadata({
    required this.name,
    this.documentation,
    required this.returnType,
    this.parameters = const [],
    this.typeParameters = const [],
    this.isAsync = false,
    this.isGenerator = false,
    this.annotations = const [],
    this.location,
  });
}

// =============================================================================
// METHOD METADATA
// =============================================================================

/// Metadata for a method.
class MethodMetadata {
  /// Method name.
  final String name;

  /// Documentation comment.
  final String? documentation;

  /// Return type.
  final TypeMetadata returnType;

  /// Parameters.
  final List<ParameterMetadata> parameters;

  /// Generic type parameters.
  final List<TypeParameterMetadata> typeParameters;

  /// Whether this is an operator.
  final bool isOperator;

  /// Operator symbol (if isOperator is true).
  final String? operatorSymbol;

  /// Whether async.
  final bool isAsync;

  /// Whether static (relevant for enums).
  final bool isStatic;

  /// Annotations.
  final List<AnnotationMetadata> annotations;

  /// Source location.
  final SourceLocation? location;

  const MethodMetadata({
    required this.name,
    this.documentation,
    required this.returnType,
    this.parameters = const [],
    this.typeParameters = const [],
    this.isOperator = false,
    this.operatorSymbol,
    this.isAsync = false,
    this.isStatic = false,
    this.annotations = const [],
    this.location,
  });
}

// =============================================================================
// GETTER/SETTER METADATA
// =============================================================================

/// Metadata for a getter.
class GetterMetadata {
  /// Getter name.
  final String name;

  /// Documentation comment.
  final String? documentation;

  /// Return type.
  final TypeMetadata returnType;

  /// Whether static (relevant for enums).
  final bool isStatic;

  /// Annotations.
  final List<AnnotationMetadata> annotations;

  /// Source location.
  final SourceLocation? location;

  const GetterMetadata({
    required this.name,
    this.documentation,
    required this.returnType,
    this.isStatic = false,
    this.annotations = const [],
    this.location,
  });
}

/// Metadata for a setter.
class SetterMetadata {
  /// Setter name.
  final String name;

  /// Documentation comment.
  final String? documentation;

  /// Parameter type.
  final TypeMetadata parameterType;

  /// Whether the setter is static.
  final bool isStatic;

  /// Annotations.
  final List<AnnotationMetadata> annotations;

  /// Source location.
  final SourceLocation? location;

  const SetterMetadata({
    required this.name,
    this.documentation,
    required this.parameterType,
    this.isStatic = false,
    this.annotations = const [],
    this.location,
  });
}

// =============================================================================
// CONSTRUCTOR METADATA
// =============================================================================

/// Metadata for a constructor.
class ConstructorMetadata {
  /// Constructor name (empty string for default constructor).
  final String name;

  /// Documentation comment.
  final String? documentation;

  /// Parameters.
  final List<ParameterMetadata> parameters;

  /// Whether this is a factory constructor.
  final bool isFactory;

  /// Whether this is a const constructor.
  final bool isConst;

  /// Annotations.
  final List<AnnotationMetadata> annotations;

  /// Source location.
  final SourceLocation? location;

  const ConstructorMetadata({
    required this.name,
    this.documentation,
    this.parameters = const [],
    this.isFactory = false,
    this.isConst = false,
    this.annotations = const [],
    this.location,
  });

  /// Display name for the constructor.
  String get displayName => name.isEmpty ? 'default' : name;
}

// =============================================================================
// FIELD/VARIABLE METADATA
// =============================================================================

/// Metadata for a field.
class FieldMetadata {
  /// Field name.
  final String name;

  /// Documentation comment.
  final String? documentation;

  /// Field type.
  final TypeMetadata type;

  /// Whether final.
  final bool isFinal;

  /// Whether const.
  final bool isConst;

  /// Whether late.
  final bool isLate;

  /// Default value expression (as string).
  final String? defaultValue;

  /// Annotations.
  final List<AnnotationMetadata> annotations;

  /// Source location.
  final SourceLocation? location;

  const FieldMetadata({
    required this.name,
    this.documentation,
    required this.type,
    this.isFinal = false,
    this.isConst = false,
    this.isLate = false,
    this.defaultValue,
    this.annotations = const [],
    this.location,
  });
}

/// Metadata for a top-level variable.
class VariableMetadata {
  /// Variable name.
  final String name;

  /// Documentation comment.
  final String? documentation;

  /// Variable type.
  final TypeMetadata type;

  /// Whether final.
  final bool isFinal;

  /// Whether const.
  final bool isConst;

  /// Default value expression.
  final String? defaultValue;

  /// Annotations.
  final List<AnnotationMetadata> annotations;

  /// Source location.
  final SourceLocation? location;

  const VariableMetadata({
    required this.name,
    this.documentation,
    required this.type,
    this.isFinal = false,
    this.isConst = false,
    this.defaultValue,
    this.annotations = const [],
    this.location,
  });
}

// =============================================================================
// PARAMETER METADATA
// =============================================================================

/// Metadata for a parameter.
class ParameterMetadata {
  /// Parameter name.
  final String name;

  /// Parameter type.
  final TypeMetadata type;

  /// Whether required.
  final bool isRequired;

  /// Whether named (vs positional).
  final bool isNamed;

  /// Default value expression.
  final String? defaultValue;

  /// Annotations.
  final List<AnnotationMetadata> annotations;

  const ParameterMetadata({
    required this.name,
    required this.type,
    this.isRequired = true,
    this.isNamed = false,
    this.defaultValue,
    this.annotations = const [],
  });
}

// =============================================================================
// TYPE METADATA
// =============================================================================

/// Metadata for a type.
class TypeMetadata {
  /// Type name (without generics).
  final String name;

  /// Full type string (including generics).
  final String fullName;

  /// Whether nullable.
  final bool isNullable;

  /// Generic type arguments.
  final List<TypeMetadata> typeArguments;

  /// Import URI for this type (if external).
  final String? importUri;

  const TypeMetadata({
    required this.name,
    String? fullName,
    this.isNullable = false,
    this.typeArguments = const [],
    this.importUri,
  }) : fullName = fullName ?? name;

  /// Creates a dynamic type.
  static const dynamic_ = TypeMetadata(name: 'dynamic');

  /// Creates a void type.
  static const void_ = TypeMetadata(name: 'void');

  /// Creates an Object type.
  static const object = TypeMetadata(name: 'Object');

  /// Creates a nullable version of this type.
  TypeMetadata nullable() => TypeMetadata(
        name: name,
        fullName: '$fullName?',
        isNullable: true,
        typeArguments: typeArguments,
        importUri: importUri,
      );
}

/// Metadata for a type parameter.
class TypeParameterMetadata {
  /// Parameter name (e.g., 'T', 'E').
  final String name;

  /// Bound type (e.g., 'Object', 'Comparable&lt;T&gt;').
  final TypeMetadata? bound;

  const TypeParameterMetadata({
    required this.name,
    this.bound,
  });
}

// =============================================================================
// ANNOTATION METADATA
// =============================================================================

/// Metadata for an annotation.
class AnnotationMetadata {
  /// Annotation name.
  final String name;

  /// Annotation arguments (as source strings).
  final List<String> arguments;

  /// Named arguments.
  final Map<String, String> namedArguments;

  const AnnotationMetadata({
    required this.name,
    this.arguments = const [],
    this.namedArguments = const {},
  });
}

// =============================================================================
// SOURCE LOCATION
// =============================================================================

/// Source location information.
class SourceLocation {
  final int line;
  final int column;
  final int offset;

  const SourceLocation({
    required this.line,
    required this.column,
    required this.offset,
  });
}

// =============================================================================
// METADATA COLLECTOR
// =============================================================================

/// Collects metadata from Dart source files.
class MetadataCollector {
  final GeneratorConfig config;
  final List<String> _warnings = [];

  MetadataCollector({required this.config});

  /// Collects metadata from source code.
  CollectedMetadata collectFromSource(String source) {
    _warnings.clear();

    try {
      final parseResult = parseString(content: source);
      final unit = parseResult.unit;

      final visitor = _CollectorVisitor(config, _warnings);
      unit.accept(visitor);

      return CollectedMetadata(
        classes: visitor.classes,
        enums: visitor.enums,
        functions: visitor.functions,
        variables: visitor.variables,
        imports: visitor.imports,
        warnings: List.unmodifiable(_warnings),
      );
    } catch (e) {
      _warnings.add('Parse error: $e');
      return CollectedMetadata.empty;
    }
  }
}

// =============================================================================
// COLLECTOR VISITOR
// =============================================================================

/// AST visitor that collects metadata.
class _CollectorVisitor extends RecursiveAstVisitor<void> {
  final GeneratorConfig config;
  final List<String> warnings;

  final List<ClassMetadata> classes = [];
  final List<EnumMetadata> enums = [];
  final List<FunctionMetadata> functions = [];
  final List<VariableMetadata> variables = [];
  final List<String> imports = [];

  ClassDeclaration? _currentClass;

  _CollectorVisitor(this.config, this.warnings);

  @override
  void visitImportDirective(ImportDirective node) {
    final uri = node.uri.stringValue;
    if (uri != null) {
      imports.add(uri);
    }
    super.visitImportDirective(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final name = node.name.lexeme;

    // Skip private classes unless configured
    if (name.startsWith('_') && !config.includePrivateMembers) {
      return;
    }

    // Skip abstract classes unless configured
    if (node.abstractKeyword != null && !config.includeAbstractClasses) {
      return;
    }

    // Check for bridge annotation filter
    if (config.bridgeAnnotation != null) {
      final hasAnnotation = node.metadata.any(
        (a) => a.name.name == config.bridgeAnnotation,
      );
      if (!hasAnnotation) return;
    }

    _currentClass = node;
    classes.add(_extractClassMetadata(node));
    _currentClass = null;
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    final name = node.name.lexeme;

    if (name.startsWith('_') && !config.includePrivateMembers) {
      return;
    }

    enums.add(_extractEnumMetadata(node));
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // Only top-level functions
    if (node.parent is! CompilationUnit) return;

    final name = node.name.lexeme;
    if (name.startsWith('_') && !config.includePrivateMembers) {
      return;
    }

    functions.add(_extractFunctionMetadata(node));
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    for (final variable in node.variables.variables) {
      final name = variable.name.lexeme;
      if (name.startsWith('_') && !config.includePrivateMembers) {
        continue;
      }
      variables.add(_extractVariableMetadata(variable, node));
    }
  }

  // -------------------------------------------------------------------------
  // EXTRACTION HELPERS
  // -------------------------------------------------------------------------

  ClassMetadata _extractClassMetadata(ClassDeclaration node) {
    final constructors = <ConstructorMetadata>[];
    final methods = <MethodMetadata>[];
    final getters = <GetterMetadata>[];
    final setters = <SetterMetadata>[];
    final staticMethods = <MethodMetadata>[];
    final staticGetters = <GetterMetadata>[];
    final staticSetters = <SetterMetadata>[];
    final fields = <FieldMetadata>[];
    final staticFields = <FieldMetadata>[];

    for (final member in node.members) {
      if (member is ConstructorDeclaration) {
        constructors.add(_extractConstructorMetadata(member));
      } else if (member is MethodDeclaration) {
        final memberName = member.name.lexeme;
        // Skip private members unless configured
        if (memberName.startsWith('_') && !config.includePrivateMembers) {
          continue;
        }

        final isStatic = member.isStatic;
        final isGetter = member.isGetter;
        final isSetter = member.isSetter;

        if (isGetter) {
          final getter = _extractGetterMetadata(member);
          if (isStatic) {
            staticGetters.add(getter);
          } else {
            getters.add(getter);
          }
        } else if (isSetter) {
          final setter = _extractSetterMetadata(member);
          if (isStatic) {
            staticSetters.add(setter);
          } else {
            setters.add(setter);
          }
        } else {
          final method = _extractMethodMetadata(member);
          if (isStatic) {
            staticMethods.add(method);
          } else {
            methods.add(method);
          }
        }
      } else if (member is FieldDeclaration) {
        for (final field in member.fields.variables) {
          final fieldName = field.name.lexeme;
          // Skip private fields unless configured
          if (fieldName.startsWith('_') && !config.includePrivateMembers) {
            continue;
          }
          final fieldMeta = _extractFieldMetadata(field, member);
          if (member.isStatic) {
            staticFields.add(fieldMeta);
          } else {
            fields.add(fieldMeta);
          }
        }
      }
    }

    return ClassMetadata(
      name: node.name.lexeme,
      documentation: _extractDocumentation(node.documentationComment),
      isAbstract: node.abstractKeyword != null,
      typeParameters: _extractTypeParameters(node.typeParameters),
      superclass: _getTypeName(node.extendsClause?.superclass),
      interfaces: node.implementsClause?.interfaces
              .map((i) => _getTypeName(i))
              .whereType<String>()
              .toList() ??
          [],
      mixins: node.withClause?.mixinTypes
              .map((m) => _getTypeName(m))
              .whereType<String>()
              .toList() ??
          [],
      constructors: constructors,
      methods: methods,
      getters: getters,
      setters: setters,
      staticMethods: config.includeStaticMembers ? staticMethods : [],
      staticGetters: config.includeStaticMembers ? staticGetters : [],
      staticSetters: config.includeStaticMembers ? staticSetters : [],
      fields: fields,
      staticFields: config.includeStaticMembers ? staticFields : [],
      annotations: _extractAnnotations(node.metadata),
      location: _extractLocation(node),
    );
  }

  EnumMetadata _extractEnumMetadata(EnumDeclaration node) {
    final values = <EnumValueMetadata>[];
    final methods = <MethodMetadata>[];
    final getters = <GetterMetadata>[];
    final setters = <SetterMetadata>[];

    for (final constant in node.constants) {
      values.add(EnumValueMetadata(
        name: constant.name.lexeme,
        documentation: _extractDocumentation(constant.documentationComment),
        arguments: constant.arguments?.argumentList.arguments
                .map((a) => a.toSource())
                .toList() ??
            [],
      ));
    }

    for (final member in node.members) {
      if (member is MethodDeclaration) {
        if (member.isGetter) {
          getters.add(_extractGetterMetadata(member));
        } else if (member.isSetter) {
          setters.add(_extractSetterMetadata(member));
        } else {
          methods.add(_extractMethodMetadata(member));
        }
      }
    }

    return EnumMetadata(
      name: node.name.lexeme,
      documentation: _extractDocumentation(node.documentationComment),
      values: values,
      methods: methods,
      getters: getters,
      setters: setters,
      annotations: _extractAnnotations(node.metadata),
      location: _extractLocation(node),
    );
  }

  FunctionMetadata _extractFunctionMetadata(FunctionDeclaration node) {
    final function = node.functionExpression;
    return FunctionMetadata(
      name: node.name.lexeme,
      documentation: _extractDocumentation(node.documentationComment),
      returnType: _extractType(node.returnType),
      parameters: _extractParameters(function.parameters),
      typeParameters: _extractTypeParameters(function.typeParameters),
      isAsync: function.body.isAsynchronous,
      isGenerator: function.body.isGenerator,
      annotations: _extractAnnotations(node.metadata),
      location: _extractLocation(node),
    );
  }

  ConstructorMetadata _extractConstructorMetadata(ConstructorDeclaration node) {
    return ConstructorMetadata(
      name: node.name?.lexeme ?? '',
      documentation: _extractDocumentation(node.documentationComment),
      parameters: _extractParameters(node.parameters),
      isFactory: node.factoryKeyword != null,
      isConst: node.constKeyword != null,
      annotations: _extractAnnotations(node.metadata),
      location: _extractLocation(node),
    );
  }

  MethodMetadata _extractMethodMetadata(MethodDeclaration node) {
    final isOperator = node.operatorKeyword != null;
    return MethodMetadata(
      name: node.name.lexeme,
      documentation: _extractDocumentation(node.documentationComment),
      returnType: _extractType(node.returnType),
      parameters: _extractParameters(node.parameters),
      typeParameters: _extractTypeParameters(node.typeParameters),
      isOperator: isOperator,
      operatorSymbol: isOperator ? node.name.lexeme : null,
      isAsync: node.body.isAsynchronous,
      isStatic: node.isStatic,
      annotations: _extractAnnotations(node.metadata),
      location: _extractLocation(node),
    );
  }

  GetterMetadata _extractGetterMetadata(MethodDeclaration node) {
    return GetterMetadata(
      name: node.name.lexeme,
      documentation: _extractDocumentation(node.documentationComment),
      returnType: _extractType(node.returnType),
      isStatic: node.isStatic,
      annotations: _extractAnnotations(node.metadata),
      location: _extractLocation(node),
    );
  }

  SetterMetadata _extractSetterMetadata(MethodDeclaration node) {
    final params = _extractParameters(node.parameters);
    final paramType =
        params.isNotEmpty ? params.first.type : TypeMetadata.dynamic_;
    return SetterMetadata(
      name: node.name.lexeme,
      documentation: _extractDocumentation(node.documentationComment),
      parameterType: paramType,
      isStatic: node.isStatic,
      annotations: _extractAnnotations(node.metadata),
      location: _extractLocation(node),
    );
  }

  FieldMetadata _extractFieldMetadata(
      VariableDeclaration node, FieldDeclaration field) {
    return FieldMetadata(
      name: node.name.lexeme,
      documentation: _extractDocumentation(field.documentationComment),
      type: _extractType(field.fields.type),
      isFinal: field.fields.isFinal,
      isConst: field.fields.isConst,
      isLate: field.fields.isLate,
      defaultValue: node.initializer?.toSource(),
      annotations: _extractAnnotations(field.metadata),
      location: _extractLocation(node),
    );
  }

  VariableMetadata _extractVariableMetadata(
      VariableDeclaration node, TopLevelVariableDeclaration decl) {
    return VariableMetadata(
      name: node.name.lexeme,
      documentation: _extractDocumentation(decl.documentationComment),
      type: _extractType(decl.variables.type),
      isFinal: decl.variables.isFinal,
      isConst: decl.variables.isConst,
      defaultValue: node.initializer?.toSource(),
      annotations: _extractAnnotations(decl.metadata),
      location: _extractLocation(node),
    );
  }

  List<ParameterMetadata> _extractParameters(FormalParameterList? params) {
    if (params == null) return [];

    return params.parameters.map((p) {
      String name;
      TypeMetadata type;
      bool isRequired = true;
      bool isNamed = false;
      String? defaultValue;

      if (p is SimpleFormalParameter) {
        name = p.name?.lexeme ?? '';
        type = _extractType(p.type);
        isRequired = p.isRequired;
      } else if (p is DefaultFormalParameter) {
        final inner = p.parameter;
        if (inner is SimpleFormalParameter) {
          name = inner.name?.lexeme ?? '';
          type = _extractType(inner.type);
        } else if (inner is FieldFormalParameter) {
          name = inner.name.lexeme;
          type = _extractType(inner.type);
        } else if (inner is SuperFormalParameter) {
          name = inner.name.lexeme;
          type = _extractType(inner.type);
          if (type.name == 'dynamic') {
            type = _tryInferParameterType(name, type, isSuper: true);
          }
        } else if (inner is FunctionTypedFormalParameter) {
          name = inner.name.lexeme;
          type = TypeMetadata(name: 'Function');
        } else {
          name = '';
          type = TypeMetadata.dynamic_;
        }
        isRequired = p.isRequired;
        isNamed = p.isNamed;
        defaultValue = p.defaultValue?.toSource();

        // Infer type if dynamic
        if (type.name == 'dynamic') {
          type = _tryInferParameterType(name, type);
        }
      } else if (p is FieldFormalParameter) {
        name = p.name.lexeme;
        type = _extractType(p.type);
        isRequired = p.isRequired;
        isNamed = p.isNamed;

        // Infer type if dynamic
        if (type.name == 'dynamic') {
          type = _tryInferParameterType(name, type);
        }
      } else if (p is SuperFormalParameter) {
        name = p.name.lexeme;
        type = _extractType(p.type);
        isRequired = p.isRequired;
        isNamed = p.isNamed;

        // Infer type if dynamic
        if (type.name == 'dynamic') {
          type = _tryInferParameterType(name, type, isSuper: true);
        }
      } else if (p is FunctionTypedFormalParameter) {
        name = p.name.lexeme;
        type = TypeMetadata(name: 'Function');
      } else {
        name = '';
        type = TypeMetadata.dynamic_;
      }

      return ParameterMetadata(
        name: name,
        type: type,
        isRequired: isRequired,
        isNamed: isNamed,
        defaultValue: defaultValue,
        annotations: _extractAnnotations(p.metadata),
      );
    }).toList();
  }

  TypeMetadata _extractType(TypeAnnotation? type) {
    if (type == null) return TypeMetadata.dynamic_;

    if (type is NamedType) {
      final name = _getTypeName(type) ?? 'dynamic';
      final isNullable = type.question != null;
      final typeArgs =
          type.typeArguments?.arguments.map((t) => _extractType(t)).toList() ??
              [];

      String fullName = name;
      if (typeArgs.isNotEmpty) {
        fullName = '$name<${typeArgs.map((t) => t.fullName).join(', ')}>';
      }
      if (isNullable) {
        fullName = '$fullName?';
      }

      return TypeMetadata(
        name: name,
        fullName: fullName,
        isNullable: isNullable,
        typeArguments: typeArgs,
      );
    } else if (type is GenericFunctionType) {
      return TypeMetadata(name: 'Function', fullName: type.toSource());
    }

    return TypeMetadata.dynamic_;
  }

  /// Tries to infer the type of a parameter from class fields or common Flutter patterns.
  TypeMetadata _tryInferParameterType(String name, TypeMetadata currentType,
      {bool isSuper = false}) {
    if (_currentClass == null) return currentType;

    if (!isSuper) {
      // Try to find a field with the same name in the current class
      for (final member in _currentClass!.members) {
        if (member is FieldDeclaration) {
          for (final variable in member.fields.variables) {
            if (variable.name.lexeme == name) {
              return _extractType(member.fields.type);
            }
          }
        }
      }
    }

    // Try to find in super class if it exists in the same file
    final extendsClause = _currentClass!.extendsClause;
    if (extendsClause != null) {
      final superClassName = _getTypeName(extendsClause.superclass);
      for (final cls in classes) {
        if (cls.name == superClassName) {
          // Search in fields of the super class metadata
          for (final field in cls.fields) {
            if (field.name == name) {
              return field.type;
            }
          }
          break; // Found the class, no need to keep searching
        }
      }
    }

    return currentType;
  }

  List<TypeParameterMetadata> _extractTypeParameters(
      TypeParameterList? params) {
    if (params == null) return [];

    return params.typeParameters.map((p) {
      return TypeParameterMetadata(
        name: p.name.lexeme,
        bound: p.bound != null ? _extractType(p.bound) : null,
      );
    }).toList();
  }

  List<AnnotationMetadata> _extractAnnotations(NodeList<Annotation> metadata) {
    return metadata.map((a) {
      final args = <String>[];
      final namedArgs = <String, String>{};

      if (a.arguments != null) {
        for (final arg in a.arguments!.arguments) {
          if (arg is NamedExpression) {
            namedArgs[arg.name.label.name] = arg.expression.toSource();
          } else {
            args.add(arg.toSource());
          }
        }
      }

      return AnnotationMetadata(
        name: a.name.name,
        arguments: args,
        namedArguments: namedArgs,
      );
    }).toList();
  }

  String? _extractDocumentation(Comment? comment) {
    if (comment == null) return null;
    return comment.tokens.map((t) => t.lexeme).join('\n');
  }

  SourceLocation? _extractLocation(AstNode node) {
    final root = node.root;
    if (root is! CompilationUnit) return null;
    final lineInfo = root.lineInfo;

    final location = lineInfo.getLocation(node.offset);
    return SourceLocation(
      line: location.lineNumber,
      column: location.columnNumber,
      offset: node.offset,
    );
  }

  /// Extracts the name from a NamedType node.
  String? _getTypeName(NamedType? type) {
    if (type == null) return null;
    // Use lexeme from the name token
    return type.name.lexeme;
  }
}
