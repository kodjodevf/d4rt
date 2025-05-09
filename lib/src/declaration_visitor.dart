import 'package:analyzer/dart/ast/ast.dart';
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
    // Does nothing for functions in this pass (handled by InterpreterVisitor)
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    // Does nothing for global variables in this pass (handled by InterpreterVisitor)
  }

  // Add other visit... if needed to ignore other declaration types
}
