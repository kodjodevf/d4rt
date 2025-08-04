import 'package:analyzer/dart/ast/ast.dart' hide TypeParameter;
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:d4rt/d4rt.dart';

/// Visitor for the first pass: Declares class and mixin placeholders.
///
/// This visitor traverses top-level declarations and creates empty
/// `InterpretedClass` instances (placeholders) in the global environment for
/// each class and mixin found. It does not resolve relationships (extends,
/// implements, with) nor does it process members.
class DeclarationVisitor extends GeneralizingAstVisitor<void> {
  final Environment environment;

  DeclarationVisitor(this.environment);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final className = node.name.lexeme;
    if (environment.isDefinedLocally(className)) {
      return;
    }

    // Extract type parameter information
    final typeParameters = node.typeParameters;
    Environment? tempEnvironment;

    if (typeParameters != null) {
      Logger.debug(
          "[DeclarationVisitor.visitClassDeclaration] Class '$className' has ${typeParameters.typeParameters.length} type parameters");

      // Create a temporary environment for type resolution
      tempEnvironment = Environment(enclosing: environment);

      // Create temporary type parameter placeholders
      for (final typeParam in typeParameters.typeParameters) {
        final paramName = typeParam.name.lexeme;
        final typeParamPlaceholder = TypeParameter(paramName);
        tempEnvironment.define(paramName, typeParamPlaceholder);

        Logger.debug(
            "[DeclarationVisitor.visitClassDeclaration]   Defined type parameter '$paramName' in temp environment");
      }
    }

    // Use the temp environment (if any) for type resolution
    final resolveEnvironment = tempEnvironment ?? environment;

    // Extract type parameter names and bounds
    final typeParameterNames =
        InterpretedClass.extractTypeParameterNames(typeParameters);
    final typeParameterBounds = InterpretedClass.extractTypeParameterBounds(
        typeParameters, resolveEnvironment);

    // Create a placeholder for the class with the required positional arguments
    final placeholder = InterpretedClass(
      className, // name
      null, // superclass (initialized to null)
      environment, // classDefinitionEnvironment
      <FieldDeclaration>[], // fieldDeclarations (initially empty)
      <String, InterpretedFunction>{}, // methods
      <String, InterpretedFunction>{}, // getters
      <String, InterpretedFunction>{}, // setters
      <String, InterpretedFunction>{}, // staticMethods
      <String, InterpretedFunction>{}, // staticGetters
      <String, InterpretedFunction>{}, // staticSetters
      <String, Object?>{}, // staticFields
      <String, InterpretedFunction>{}, // constructors
      <String, InterpretedFunction>{}, // operators
      // Named parameters
      isAbstract: node.abstractKeyword != null,
      isMixin:
          false, // Will potentially be corrected in pass 2 if 'class mixin'
      interfaces: [], // Initially empty
      onClauseTypes: [], // Initially empty
      mixins: [], // Initially empty
      // Read modifiers from AST node
      isFinal: node.finalKeyword != null,
      isInterface: node.interfaceKeyword != null,
      isBase: node.baseKeyword != null,
      isSealed: node.sealedKeyword != null,
      // Add type parameter information
      typeParameterNames: typeParameterNames,
      typeParameterBounds: typeParameterBounds,
    );
    environment.define(className, placeholder);
    Logger.debug(
        "[DeclarationVisitor] Defined placeholder for class '$className' in env: [38;5;244m${environment.hashCode}[0m");
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    final mixinName = node.name.lexeme;
    if (environment.isDefinedLocally(mixinName)) {
      return;
    }
    // Create a placeholder for the mixin with the required positional arguments
    final placeholder = InterpretedClass(
      mixinName, // name
      null, // superclass (null for pure mixins)
      environment, // classDefinitionEnvironment
      <FieldDeclaration>[], // fieldDeclarations (initially empty)
      <String, InterpretedFunction>{}, // methods
      <String, InterpretedFunction>{}, // getters
      <String, InterpretedFunction>{}, // setters
      <String, InterpretedFunction>{}, // staticMethods
      <String, InterpretedFunction>{}, // staticGetters
      <String, InterpretedFunction>{}, // staticSetters
      <String, Object?>{}, // staticFields
      <String, InterpretedFunction>{}, // constructors (empty for mixins)
      <String, InterpretedFunction>{}, // operators
      // Named parameters
      isAbstract: false, // Mixins are not abstract
      isMixin: true,
      interfaces: [], // Initially empty
      onClauseTypes: [], // Will be filled in pass 2
      mixins: [], // Initially empty (mixins cannot use 'with')
    );
    environment.define(mixinName, placeholder);
    Logger.debug(
        "[DeclarationVisitor] Defined placeholder for mixin '$mixinName' in env: [38;5;244m${environment.hashCode}[0m");
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    final enumName = node.name.lexeme;
    if (environment.isDefinedLocally(enumName)) {
      return;
    }

    // Extract constant names - needed for ordering later
    final valueNames = node.constants.map((c) => c.name.lexeme).toList();

    // Create the placeholder enum runtime object, storing only names for now
    final enumPlaceholder =
        InterpretedEnum.placeholder(enumName, environment, valueNames);

    // Define the enum type placeholder in the current environment
    environment.define(enumName, enumPlaceholder);
    Logger.debug(
        "[DeclarationVisitor] Defined placeholder for enum '$enumName' with value order [${valueNames.join(', ')}] in env: [38;5;244m${environment.hashCode}[0m");

    // Do NOT process members or constants here. That happens in Pass 2 (InterpreterVisitor).
  }

  // Ignore other declaration types in this pass
  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final functionName = node.name.lexeme;
    Logger.debug(
        "[DeclarationVisitor.visitFunctionDeclaration] Processing function: $functionName");

    if (environment.isDefinedLocally(functionName)) {
      return;
    }

    // Handle type parameters for generic functions
    Environment? tempEnvironment;
    final typeParameters = node.functionExpression.typeParameters;

    if (typeParameters != null) {
      Logger.debug(
          "[DeclarationVisitor.visitFunctionDeclaration] Function '$functionName' has ${typeParameters.typeParameters.length} type parameters");

      // Create a temporary environment for type resolution
      tempEnvironment = Environment(enclosing: environment);

      // Create temporary type parameter placeholders
      for (final typeParam in typeParameters.typeParameters) {
        final paramName = typeParam.name.lexeme;

        // Create a simple TypeParameter placeholder in the temp environment
        final typeParamPlaceholder = TypeParameter(paramName);
        tempEnvironment.define(paramName, typeParamPlaceholder);

        Logger.debug(
            "[DeclarationVisitor.visitFunctionDeclaration]   Defined type parameter '$paramName' in temp environment");
      }
    }

    // Use the temp environment (if any) for type resolution, otherwise use the normal environment
    final resolveEnvironment = tempEnvironment ?? environment;

    // Now resolve the return type (which might reference type parameters)
    final returnTypeNode = node.returnType;
    RuntimeType declaredReturnType;

    if (returnTypeNode is NamedType) {
      final typeName = returnTypeNode.name2.lexeme;
      Logger.debug(
          "[DeclarationVisitor.visitFunctionDeclaration]   Return type node name: $typeName");

      try {
        final resolvedType = resolveEnvironment.get(typeName);
        Logger.debug(
            "[DeclarationVisitor.visitFunctionDeclaration]     environment.get('$typeName') resolved to: ${resolvedType?.runtimeType} with name: ${(resolvedType is RuntimeType ? resolvedType.name : 'N/A')}");

        if (resolvedType is RuntimeType) {
          declaredReturnType = resolvedType;
        } else {
          Logger.warn(
              "[DeclarationVisitor.visitFunctionDeclaration]     Type '$typeName' resolved to non-RuntimeType: $resolvedType. Using placeholder.");
          declaredReturnType = BridgedClass(nativeType: Object, name: typeName);
        }
      } on RuntimeError catch (e) {
        Logger.warn(
            "[DeclarationVisitor.visitFunctionDeclaration]     Type '$typeName' not found in environment (RuntimeError: ${e.message}). Using placeholder.");
        declaredReturnType = BridgedClass(nativeType: Object, name: typeName);
      }
    } else if (returnTypeNode == null) {
      declaredReturnType = BridgedClass(nativeType: Object, name: 'dynamic');
    } else {
      // For other TypeAnnotation types, use a generic placeholder
      declaredReturnType =
          BridgedClass(nativeType: Object, name: 'unknown_type_placeholder');
    }

    bool isNullable = returnTypeNode?.question != null; // Check for 'A?'

    final function = InterpretedFunction.declaration(
        node,
        environment, // The function captures the environment it's declared in
        declaredReturnType,
        isNullable);
    Logger.debug(
        "[DeclarationVisitor.visitFunctionDeclaration]   Defining function '$functionName' with declaredReturnType: ${declaredReturnType.name} (Hash: ${declaredReturnType.hashCode})");
    environment.define(functionName, function);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    // Does nothing for global variables in this pass (handled by InterpreterVisitor)
    for (final variable in node.variables.variables) {
      if (variable.name.lexeme == '_') {
        // Ignore wildcard variables
        continue;
      }
      // For now, just define the variable name with null.
      // The actual initialization will happen in InterpreterVisitor.
      if (!environment.isDefinedLocally(variable.name.lexeme)) {
        environment.define(variable.name.lexeme, null);
        Logger.debug(
            "[DeclarationVisitor] Defined top-level variable placeholder '${variable.name.lexeme}' in env: ${environment.hashCode}");
      }
    }
  }

  // Add other visit... if needed to ignore other declaration types
}
