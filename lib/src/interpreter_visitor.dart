import 'dart:async';
import 'package:analyzer/dart/ast/ast.dart' hide TypeParameter;
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:d4rt/d4rt.dart';
import 'package:d4rt/src/utils/extensions/string.dart';
import 'package:d4rt/src/module_loader.dart';

/// Main visitor that walks the AST and interprets the code.
/// Uses a two-pass approach (DeclarationVisitor first).
class InterpreterVisitor extends GeneralizingAstVisitor<Object?> {
  Environment environment;
  final Environment globalEnvironment;
  final ModuleLoader moduleLoader; // Field for ModuleLoader
  InterpretedFunction? currentFunction; // Track the function being executed
  AsyncExecutionState? currentAsyncState;
  Set<String> _currentStatementLabels = {};

  InterpreterVisitor({
    required this.globalEnvironment,
    required this.moduleLoader, // Accept ModuleLoader in the constructor
    Uri? initiallibrary, // New: Optional URI for the initial source
  }) : environment = globalEnvironment {
    if (initiallibrary != null) {
      // Sets the base URI in the ModuleLoader for the initial source code.
      // This is crucial for resolving relative imports in this initial source code.
      moduleLoader.currentlibrary = initiallibrary;
      Logger.debug(
          "[InterpreterVisitor] Initial source URI set in ModuleLoader to: $initiallibrary");
    }
    // Initialize currentAsyncState if it's null and we are in an async context implicitly
    // This might be more complex depending on how top-level async calls are handled
  }

  @override
  Object? visitCompilationUnit(CompilationUnit node) {
    // Restore simple sequential processing
    Object? lastValue;
    for (final declaration in node.declarations) {
      lastValue = declaration.accept<Object?>(this);
    }
    return lastValue;
  }

  @override
  Object? visitBlock(Block node) {
    return executeBlock(node.statements, Environment(enclosing: environment));
  }

  Object? executeBlock(
      List<Statement> statements, Environment blockEnvironment) {
    final previousEnvironment = environment;
    Object? lastValue;
    try {
      environment = blockEnvironment;
      for (final statement in statements) {
        // Explicitly handle declarations within blocks
        if (statement is FunctionDeclaration ||
            statement is ClassDeclaration ||
            statement is MixinDeclaration ||
            statement
                is TopLevelVariableDeclaration || // Technically not a statement, but might appear?
            statement is VariableDeclarationStatement) {
          // This is a proper statement
          lastValue = statement.accept<Object?>(this);
          // Check for suspension after declaration execution
          if (lastValue is AsyncSuspensionRequest) {
            return lastValue; // Propagate suspension
          }
          lastValue = null; // Declarations don't produce a carry value
        } else {
          lastValue = statement.accept<Object?>(this);
          // if the execution of the statement returns an async suspension request,
          // we propagate it immediately upwards.
          if (lastValue is AsyncSuspensionRequest) {
            return lastValue;
          }
        }
        // Handle ReturnException, BreakException, ContinueException if needed (propagate or consume)
        // This simple version just propagates them implicitly by not catching them here.
      }
    } finally {
      environment = previousEnvironment;
    }
    return lastValue;
  }

  @override
  Object? visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    for (final variable in node.variables.variables) {
      if (variable.name.lexeme == '_') {
        // Evaluate initializer for potential side effects, but don't define
        variable.initializer?.accept<Object?>(this);
      } else {
        Object? value;
        if (variable.initializer != null) {
          value = variable.initializer!.accept<Object?>(this);
        }
        environment.define(variable.name.lexeme, value);
      }
    }
    return null;
  }

  @override
  Object? visitPatternVariableDeclarationStatement(
      PatternVariableDeclarationStatement node) {
    final patternDecl = node.declaration;
    final pattern = patternDecl.pattern;
    final initializer = patternDecl.expression;

    // Evaluate the right-hand side value
    final rhsValue = initializer.accept<Object?>(this);

    // Match and bind the pattern to the value
    try {
      _matchAndBind(pattern, rhsValue, environment);
    } on PatternMatchException catch (e) {
      // Convert pattern match failures to standard RuntimeError for now
      throw RuntimeError("Pattern match failed: ${e.message}");
    } catch (e, s) {
      // Add stack trace capture
      Logger.error(
          "during pattern binding: $e\nStack trace:\n$s"); // Display the stack trace
      // Catch other potential errors during binding
      throw RuntimeError("Error during pattern binding: $e");
    }
    return null;
  }

  @override
  Object? visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    // Simply visit the declaration list. The list visitor handles definition.
    return node.variables.accept<Object?>(this);
    // return null; // Statements usually return null unless they are Return/Throw/etc.
  }

  // Handles the list of variables in a single declaration statement.

  @override
  Object? visitExpressionStatement(ExpressionStatement node) {
    return node.expression.accept<Object?>(this);
  }

  @override
  Object? visitAsExpression(AsExpression node) {
    final value = node.expression.accept<Object?>(this);
    final typeNode = node.type;
    if (typeNode is NamedType) {
      final typeName = typeNode.name.lexeme;
      switch (typeName) {
        case 'int':
          if (value is int) return value;
          break;
        case 'double':
          if (value is double) return value;
          break;
        case 'num':
          if (value is num) return value;
          break;
        case 'String':
          if (value is String) return value;
          break;
        case 'bool':
          if (value is bool) return value;
          break;
        case 'List':
          if (value is List) return value;
          break;
        case 'Null':
          if (value == null) return value;
          break;
        case 'Object':
          if (value != null) return value;
          break;
        case 'dynamic':
          return value;
        default:
          // For custom/interpreted types, we can add logic here
          // For now, we accept all (permissive behavior)
          return value;
      }
    }
    throw RuntimeError(
        "Cast failed with 'as' : the value does not match the target type (${typeNode.toSource()})");
  }

  @override
  Object? visitIntegerLiteral(IntegerLiteral node) {
    return node.value;
  }

  @override
  Object? visitDoubleLiteral(DoubleLiteral node) {
    return node.value;
  }

  @override
  Object? visitBooleanLiteral(BooleanLiteral node) {
    return node.value;
  }

  @override
  Object? visitStringLiteral(StringLiteral node) {
    if (node is SimpleStringLiteral) {
      return node.value;
    } else if (node is AdjacentStrings) {
      // Handle adjacent strings like 'Hello ' 'World!'
      final buffer = StringBuffer();
      for (final stringLiteral in node.strings) {
        if (stringLiteral is SimpleStringLiteral) {
          buffer.write(stringLiteral.value);
        } else {
          // Recursively handle nested adjacent strings or other string types
          final value = visitStringLiteral(stringLiteral);
          buffer.write(value.toString());
        }
      }
      return buffer.toString();
    }
    throw UnimplementedError(
      'Type de StringLiteral non géré: ${node.runtimeType}',
    );
  }

  @override
  Object? visitNullLiteral(NullLiteral node) {
    return null;
  }

  @override
  Object? visitSimpleIdentifier(SimpleIdentifier node) {
    final name = node.name;

    Logger.debug(
        "[visitSimpleIdentifier] Looking for '$name'. Visitor env: ${environment.hashCode}");

    // Lexical search & Bridges
    try {
      // Use environment.get() which handles strings and bridges
      final value = environment.get(name);
      // If get() succeeds, the value is found (variable or bridge)
      Logger.debug(
          "[visitSimpleIdentifier] Found '$name' via environment.get() -> ${value?.runtimeType}");

      // Handle late variables
      if (value is LateVariable) {
        Logger.debug("[visitSimpleIdentifier] Accessing late variable '$name'");
        return value
            .value; // This will trigger lazy initialization or throw if uninitialized
      }

      if (name == 'initialValue') {
        Logger.debug(
            "[visitSimpleIdentifier] Returning '$name' = $value (from lexical/bridge)");
      }
      return value;
    } on RuntimeError catch (getErr) {
      // Ignore get() error for now, try 'this' then
      Logger.debug(
          "[visitSimpleIdentifier] '$name' not found lexically or as bridge. Trying implicit 'this'. Error: ${getErr.message}");
    }

    // Implicit attempt via 'this'
    // (Only if not found lexically/as bridge)
    Object? thisInstance;
    try {
      thisInstance = environment.get('this');
    } on RuntimeError {
      // 'this' does not exist in the current environment.
      // Before giving up, try searching static methods in the current class if we're in a static context
      if (currentFunction != null &&
          currentFunction!.ownerType is InterpretedClass) {
        final ownerClass = currentFunction!.ownerType as InterpretedClass;
        Logger.debug(
            "[visitSimpleIdentifier] 'this' not found, but we're in class '${ownerClass.name}'. Checking static members for '$name'.");

        // Check static methods
        final staticMethod = ownerClass.findStaticMethod(name);
        if (staticMethod != null) {
          Logger.debug(
              "[visitSimpleIdentifier] Found static method '$name' in current class '${ownerClass.name}'.");
          return staticMethod;
        }

        // Check static getters
        final staticGetter = ownerClass.findStaticGetter(name);
        if (staticGetter != null) {
          Logger.debug(
              "[visitSimpleIdentifier] Found static getter '$name' in current class '${ownerClass.name}'.");
          return staticGetter;
        }

        // Check static fields
        try {
          final staticField = ownerClass.getStaticField(name);
          Logger.debug(
              "[visitSimpleIdentifier] Found static field '$name' in current class '${ownerClass.name}'.");
          return staticField;
        } on RuntimeError {
          // Static field not found, continue to final error
        }
      }

      // This is the end of the search, the identifier is undefined.
      throw RuntimeError("Undefined variable: $name");
    }

    // 'this' was found, now we try to access the member.
    try {
      if (thisInstance is InterpretedInstance) {
        // Access the property on 'this'
        final member = thisInstance.get(name, visitor: this);
        Logger.debug(
            "[visitSimpleIdentifier] Found '$name' via implicit InterpretedInstance 'this'. Member: ${member?.runtimeType}");
        return member; // Return the field value or bound function (getter/method)
      } else if (toBridgedInstance(thisInstance).$2) {
        final bridgedInstance = toBridgedInstance(thisInstance).$1!;

        Logger.debug(
            "[visitSimpleIdentifier] Trying implicit 'this' access on BridgedInstance (${bridgedInstance.bridgedClass.name}) for member '$name'.");
        // Check instance getter FIRST
        final getterAdapter =
            bridgedInstance.bridgedClass.findInstanceGetterAdapter(name);
        if (getterAdapter != null) {
          Logger.debug(
              "[visitSimpleIdentifier] Found BRIDGED GETTER '$name' via implicit 'this'. Calling adapter...");
          final getterResult =
              getterAdapter(this, bridgedInstance.nativeObject);
          if (name == 'initialValue') {
            Logger.debug(
                "[visitSimpleIdentifier] Returning '$name' = $getterResult (from BridgedInstance getter this)");
          }
          return getterResult;
        }
        Logger.debug(
            "[visitSimpleIdentifier]   Bridged getter '$name' not found. Checking for method...");
        // Then check instance method
        final methodAdapter =
            bridgedInstance.bridgedClass.findInstanceMethodAdapter(name);
        if (methodAdapter != null) {
          Logger.debug(
              "[visitSimpleIdentifier] Found BRIDGED METHOD '$name' via implicit 'this'. Binding...");
          // Return a callable bound to the instance

          final boundCallable =
              BridgedMethodCallable(bridgedInstance, methodAdapter, name);
          if (name == 'initialValue') {
            Logger.debug(
                "[visitSimpleIdentifier] Returning '$name' = $boundCallable (bound method from BridgedInstance this)");
          }
          return boundCallable;
        }
        Logger.debug(
            "[visitSimpleIdentifier]   Bridged method '$name' not found either.");
        // If neither getter nor method, error
        throw RuntimeError(
            "Undefined property or method '$name' on bridged instance of '${bridgedInstance.bridgedClass.name}' accessed via implicit 'this'.");
      } // +++ NEW BLOCK +++
      else if (thisInstance is InterpretedEnumValue) {
        Logger.debug(
            "[visitSimpleIdentifier] Found '$name' via implicit InterpretedEnumValue 'this'.");
        // Delegate to the get method of the enum value, passing visitor
        // This will execute getters or return bound methods/fields.
        final enumMember = thisInstance.get(name, this);
        if (name == 'initialValue') {
          Logger.debug(
              "[visitSimpleIdentifier] Returning '$name' = $enumMember (from EnumValue this)");
        }
        return enumMember;
      }
      throw RuntimeError(
          "Undefined variable: $name (this exists as native type ${thisInstance?.runtimeType}");
    } on RuntimeError catch (thisErr) {
      // 'this' not found OR instance.get() failed
      // If get() failed with a specific error, propagate it if it is NOT "Undefined property".
      if (thisErr.message.contains("Undefined property '$name'")) {
        Logger.debug(
            "[SimpleIdentifier] Direct access failed for '$name' via implicit 'this'. Trying extension lookup on ${thisInstance?.runtimeType}.");
        if (thisInstance != null) {
          // Check that 'this' exists before searching
          try {
            final extensionMember =
                environment.findExtensionMember(thisInstance, name);

            if (extensionMember is InterpretedExtensionMethod) {
              if (extensionMember.isGetter) {
                Logger.debug(
                    "[SimpleIdentifier] Found extension getter '$name' via implicit 'this'. Calling...");
                // Extension getters are called with the instance as the only positional argument
                final extensionPositionalArgs = [thisInstance];
                try {
                  return extensionMember
                      .call(this, extensionPositionalArgs, {});
                } on ReturnException catch (e) {
                  return e.value;
                } catch (e) {
                  throw RuntimeError(
                      "Error executing extension getter '$name' via implicit 'this': $e");
                }
              } else if (!extensionMember.isOperator &&
                  !extensionMember.isSetter) {
                // Return the extension method itself (not bound)
                Logger.debug(
                    "[SimpleIdentifier] Found extension method '$name' via implicit 'this'. Returning callable.");
                // Return a bound instance instead of the raw method.
                return BoundExtensionMethodCallable(
                    thisInstance, extensionMember);
              }
              // Operators/setters are generally not accessible directly via a simple identifier
            }
            // No suitable extension member found, fall through to final error
            Logger.debug(
                "[SimpleIdentifier] No suitable extension member found for '$name' via implicit 'this'.");
          } on RuntimeError catch (findError) {
            // Error during extension lookup itself
            Logger.debug(
                "[SimpleIdentifier] Error during extension lookup for '$name' via implicit 'this': ${findError.message}");
            // Fall through to final error
          }
        } else {
          Logger.debug(
              "[SimpleIdentifier] Cannot search extension for '$name' because implicit 'this' is null.");
        }
      }
      // Relaunch the error if it was NOT "Undefined property" OR if extension lookup failed.
      else if (thisErr.message
          .contains("non implémenté pour BridgedInstance")) {
        // Relaunch the specific BridgeInstance errors
        rethrow;
      }

      // Before final error, try static method lookup in enclosing class
      final enclosingClass = _findEnclosingClass();
      if (enclosingClass != null) {
        Logger.debug(
            "[visitSimpleIdentifier] Final attempt: checking static members for '$name' in enclosing class '${enclosingClass.name}'.");

        // Check static methods
        final staticMethod = enclosingClass.findStaticMethod(name);
        if (staticMethod != null) {
          Logger.debug(
              "[visitSimpleIdentifier] Found static method '$name' in enclosing class '${enclosingClass.name}' (final attempt).");
          return staticMethod;
        }

        // Check static getters
        final staticGetter = enclosingClass.findStaticGetter(name);
        if (staticGetter != null) {
          Logger.debug(
              "[visitSimpleIdentifier] Found static getter '$name' in enclosing class '${enclosingClass.name}' (final attempt).");
          return staticGetter;
        }

        // Check static fields
        try {
          final staticField = enclosingClass.getStaticField(name);
          Logger.debug(
              "[visitSimpleIdentifier] Found static field '$name' in enclosing class '${enclosingClass.name}' (final attempt).");
          return staticField;
        } on RuntimeError {
          // Static field not found, continue to final error
        }
      }

      // If the initial error was 'Undefined property' AND that extension lookup failed,
      // or if the initial error was something else, raise the final "Undefined variable" error.
      throw RuntimeError(
          "Undefined variable: $name (Original error: ${thisErr.message})");
    }
  }

  @override
  Object? visitThisExpression(ThisExpression node) {
    try {
      return environment.get('this');
    } on RuntimeError {
      // This should ideally not happen if called within a valid method/constructor context
      throw RuntimeError("Keyword 'this' used outside of an instance context.");
    }
  }

  /// Helper method to find an enclosing class that might contain static members
  /// Searches through the environment chain and currentFunction hierarchy
  InterpretedClass? _findEnclosingClass() {
    // First, try the current function's owner
    if (currentFunction != null &&
        currentFunction!.ownerType is InterpretedClass) {
      return currentFunction!.ownerType as InterpretedClass;
    }

    // If that doesn't work, search the environment chain for class instances
    // This is a fallback approach - look for any classes defined in parent scopes
    Environment? current = environment;
    while (current != null) {
      for (final value in current.values.values) {
        if (value is InterpretedClass) {
          // Found a class in this environment - this might be our enclosing class
          // We need to check if we're inside a method of this class
          // This is a heuristic - in a proper implementation, we'd track the lexical scope better
          Logger.debug(
              "[_findEnclosingClass] Found class '${value.name}' in environment chain");
          return value;
        }
      }
      current = current.enclosing;
    }

    return null;
  }

  @override
  Object? visitPrefixedIdentifier(PrefixedIdentifier node) {
    final prefixValue = node.prefix.accept<Object?>(this);
    if (prefixValue is AsyncSuspensionRequest) {
      // Propagate the suspension so that the state machine resumes this node after resolution
      return prefixValue;
    }
    final memberName = node.identifier.name;

    // Handle the case where the prefix is an environment (prefixed import)
    if (prefixValue is Environment) {
      Logger.debug(
          "[PrefixedIdentifier] The prefix '${node.prefix.toSource()}' resolved to an Environment. Searching for '$memberName' in this environment.");
      try {
        // The call to get() on the prefixed environment could return a function (which must be called if it's a getter)
        // or a direct value.
        final member = prefixValue.get(memberName);
        // If it's an InterpretedFunction and a getter, it must be called.
        if (member is InterpretedFunction && member.isGetter) {
          Logger.debug(
              "[PrefixedIdentifier] Member '$memberName' is a getter. Calling...");
          return member.call(this, [],
              {}); // Call without 'this' because it's a prefixed import
        }
        Logger.debug(
            "[PrefixedIdentifier] Member '$memberName' found directly: $member");
        return member; // Return the value/function directly
      } on RuntimeError catch (e) {
        throw RuntimeError(
            "Erreur lors de la récupération du membre '$memberName' de l'import préfixé '${node.prefix.toSource()}': ${e.message}");
      }
    }

    if (prefixValue is InterpretedClass) {
      // Static access
      try {
        return prefixValue.getStaticField(memberName);
      } on RuntimeError catch (_) {
        InterpretedFunction? staticMember =
            prefixValue.findStaticGetter(memberName);
        staticMember ??= prefixValue.findStaticMethod(memberName);
        if (staticMember != null) {
          if (staticMember.isGetter) {
            return staticMember.call(this, [], {});
          } else {
            return staticMember;
          }
        } else {
          throw RuntimeError(
              "Undefined static member '$memberName' on class '${prefixValue.name}'.");
        }
      }
    } else if (prefixValue is InterpretedEnum) {
      if (memberName == 'values') {
        Logger.debug(
            "[PrefixedIdentifier] Accessing static getter 'values' on enum '${prefixValue.name}'.");
        return prefixValue.valuesList;
      }

      // Check enum values first
      final value = prefixValue.values[memberName];
      if (value != null) {
        Logger.debug(
            "[PrefixedIdentifier] Accessing enum value '$memberName' on enum '${prefixValue.name}'.");
        return value;
      }

      // Check static fields
      if (prefixValue.staticFields.containsKey(memberName)) {
        Logger.debug(
            "[PrefixedIdentifier] Accessing static field '$memberName' on enum '${prefixValue.name}'.");
        return prefixValue.staticFields[memberName];
      }

      // Check static getters
      final staticGetter = prefixValue.staticGetters[memberName];
      if (staticGetter != null) {
        Logger.debug(
            "[PrefixedIdentifier] Calling static getter '$memberName' on enum '${prefixValue.name}'.");
        return staticGetter.call(this, [], {});
      }

      // Check static methods
      final staticMethod = prefixValue.staticMethods[memberName];
      if (staticMethod != null) {
        Logger.debug(
            "[PrefixedIdentifier] Accessing static method '$memberName' on enum '${prefixValue.name}'.");
        return staticMethod;
      }

      // Check mixins for static members (reverse order)
      for (final mixin in prefixValue.mixins.reversed) {
        // Check static fields
        try {
          final mixinStaticField = mixin.getStaticField(memberName);
          Logger.debug(
              "[PrefixedIdentifier] Found static field '$memberName' from mixin '${mixin.name}' for enum '${prefixValue.name}'");
          return mixinStaticField;
        } on RuntimeError {
          // Continue to next check
        }

        // Check static getters
        final mixinStaticGetter = mixin.findStaticGetter(memberName);
        if (mixinStaticGetter != null) {
          Logger.debug(
              "[PrefixedIdentifier] Found static getter '$memberName' from mixin '${mixin.name}' for enum '${prefixValue.name}'");
          return mixinStaticGetter.call(this, [], {});
        }

        // Check static methods
        final mixinStaticMethod = mixin.findStaticMethod(memberName);
        if (mixinStaticMethod != null) {
          Logger.debug(
              "[PrefixedIdentifier] Found static method '$memberName' from mixin '${mixin.name}' for enum '${prefixValue.name}'");
          return mixinStaticMethod;
        }
      }

      // Not found
      throw RuntimeError(
          "Undefined static member '$memberName' on enum '${prefixValue.name}'. Available enum values: ${prefixValue.valueNames.join(', ')}");
    } else if (prefixValue is BridgedClass) {
      final bridgedClass = prefixValue;
      Logger.debug(
          "[PrefixedIdentifier] Static access on BridgedClass: ${bridgedClass.name}.$memberName");
      final staticGetter = bridgedClass.findStaticGetterAdapter(memberName);
      if (staticGetter != null) {
        return staticGetter(this);
      }
      final staticMethod = bridgedClass.findStaticMethodAdapter(memberName);
      if (staticMethod != null) {
        // Return the static method as a callable value
        Logger.debug(
            "[PrefixedIdentifier] Returning bridged static method '$memberName' as value from '${bridgedClass.name}'.");
        return BridgedStaticMethodCallable(
            bridgedClass, staticMethod, memberName);
      } else {
        throw RuntimeError(
            "Undefined static member '$memberName' on bridged class '${bridgedClass.name}'.");
      }
    } else if (prefixValue is InterpretedExtension) {
      // Handle static member access on extensions
      final extension = prefixValue;
      Logger.debug(
          "[PrefixedIdentifier] Static access on Extension: ${extension.name ?? '<unnamed>'}.$memberName");

      // Check static field
      if (extension.staticFields.containsKey(memberName)) {
        return extension.staticFields[memberName];
      }

      // Check static getter
      final staticGetter = extension.findStaticGetter(memberName);
      if (staticGetter != null) {
        return staticGetter.call(this, [], {});
      }

      // Check static method
      final staticMethod = extension.findStaticMethod(memberName);
      if (staticMethod != null) {
        return staticMethod;
      }

      throw RuntimeError(
          "Undefined static member '$memberName' on extension '${extension.name ?? '<unnamed>'}'.");
    } else if (prefixValue is InterpretedInstance) {
      try {
        final member = prefixValue.get(memberName);
        if (member is InterpretedFunction && member.isGetter) {
          return member.bind(prefixValue).call(this, [], {});
        } else {
          return member;
        }
      } on RuntimeError catch (e) {
        if (e.message.contains("Undefined property '$memberName'")) {
          final extensionMember =
              environment.findExtensionMember(prefixValue, memberName);
          if (extensionMember is InterpretedExtensionMethod) {
            if (extensionMember.isGetter) {
              return extensionMember.call(this, [prefixValue], {});
            } else if (!extensionMember.isOperator &&
                !extensionMember.isSetter) {
              return extensionMember;
            }
          }
        }
        throw RuntimeError(
            "${e.message} (accessing property via PrefixedIdentifier '$memberName')");
      }
    } else if (prefixValue is InterpretedEnumValue) {
      if (memberName == 'index') {
        Logger.debug(
            "[PrefixedIdentifier] Accessing getter 'index' on enum value '$prefixValue'.");
        return prefixValue.index;
      } else if (memberName == 'toString') {
        Logger.debug(
            "[PrefixedIdentifier] Accessing method 'toString' on enum value '$prefixValue'. Returning callable.");
        // Return directly the string for simplicity in prefixed access?
        // No, return a callable function to be consistent with methods.
        return NativeFunction((_, args, __, ___) {
          if (args.isNotEmpty) {
            throw RuntimeError("toString() takes no arguments.");
          }
          return prefixValue.toString();
        }, arity: 0, name: 'toString');
      } else if (memberName == 'name') {
        Logger.debug(
            "[PrefixedIdentifier] Explicitly accessing 'name' on enum value '$prefixValue'. Returning value.");
        return prefixValue.name; // Access directly the 'name' property
      } else {
        Logger.debug(
            "[PrefixedIdentifier] Accessing member '$memberName' on enum value '$prefixValue'. Calling get()...");
        try {
          // Pass 'this' (the visitor) to allow getter execution if needed.
          return prefixValue.get(memberName, this);
        } on ReturnException catch (e) {
          // If get() executes a getter that throws ReturnException
          return e.value;
        } catch (e) {
          // Propagate other errors from get()
          throw RuntimeError(
              "Error getting member '$memberName' from enum value '$prefixValue': $e");
        }
      }
    } else if (toBridgedInstance(prefixValue).$2) {
      final bridgedInstance = toBridgedInstance(prefixValue).$1!;
      final getterAdapter =
          bridgedInstance.bridgedClass.findInstanceGetterAdapter(memberName);
      if (getterAdapter != null) {
        return getterAdapter(this, bridgedInstance.nativeObject);
      }
      final methodAdapter =
          bridgedInstance.bridgedClass.findInstanceMethodAdapter(memberName);
      if (methodAdapter != null) {
        return BridgedMethodCallable(bridgedInstance, methodAdapter, memberName)
            .call(this, [], {});
      }

      // No adapter found, try extension methods/getters
      try {
        final extensionMember =
            environment.findExtensionMember(bridgedInstance, memberName);
        if (extensionMember is InterpretedExtensionMethod) {
          if (extensionMember.isGetter) {
            Logger.debug(
                "[PrefixedIdentifier] Found extension getter '$memberName' for ${bridgedInstance.bridgedClass.name}. Calling...");
            final extensionArgs = <Object?>[bridgedInstance];
            return extensionMember.call(this, extensionArgs, {});
          } else if (!extensionMember.isOperator && !extensionMember.isSetter) {
            Logger.debug(
                "[PrefixedIdentifier] Found extension method '$memberName' for ${bridgedInstance.bridgedClass.name}. Returning callable.");
            return BoundExtensionMethodCallable(
                bridgedInstance, extensionMember);
          }
        }
      } on RuntimeError catch (findError) {
        Logger.debug(
            "[PrefixedIdentifier] Error finding extension '$memberName' for ${bridgedInstance.bridgedClass.name}: ${findError.message}");
      }

      throw RuntimeError(
          "Undefined property or method '$memberName' on bridged instance of '${bridgedInstance.bridgedClass.name}'.");
    } else if (prefixValue is InterpretedRecord) {
      // Accessing field of a record
      final record = prefixValue;
      Logger.debug(
          "[PrefixedIdentifier] Access on InterpretedRecord: .$memberName");
      // Check if it's a positional field access ($1, $2, ...)
      if (memberName.startsWith('\$') && memberName.length > 1) {
        try {
          final index = int.parse(memberName.substring(1)) - 1;
          if (index >= 0 && index < record.positionalFields.length) {
            return record.positionalFields[index];
          } else {
            throw RuntimeError(
                "Record positional field index \$$index out of bounds (0..${record.positionalFields.length - 1}).");
          }
        } catch (e) {
          // Handle parse errors or other issues
          throw RuntimeError(
              "Invalid positional record field accessor '$memberName'.");
        }
      } else {
        // Check if it's a named field access
        if (record.namedFields.containsKey(memberName)) {
          return record.namedFields[memberName];
        } else {
          throw RuntimeError(
              "Record has no field named '$memberName'. Available fields: ${record.namedFields.keys.join(', ')}");
        }
      }
    } else if (prefixValue is BridgedEnum) {
      Logger.debug(
          "[PrefixedIdentifier] Accessing value/member on BridgedEnum: ${prefixValue.name}.$memberName");
      // 1. Try to get enum value
      final enumValue = prefixValue.getValue(memberName);
      if (enumValue != null) {
        return enumValue; // Return the BridgedEnumValue
      }

      // 2. Try static getter
      final staticGetter = prefixValue.staticGetters[memberName];
      if (staticGetter != null) {
        try {
          return staticGetter(this);
        } catch (e, s) {
          Logger.error(
              "Native error during bridged enum static getter '$memberName': $e\n$s");
          throw RuntimeError(
              "Native error during bridged enum static getter '$memberName': $e");
        }
      }

      // 3. Static methods as tear-offs
      final staticMethod = prefixValue.staticMethods[memberName];
      if (staticMethod != null) {
        return BridgedEnumStaticMethodCallable(
            prefixValue, staticMethod, memberName);
      }

      throw RuntimeError(
          "Undefined member '$memberName' on bridged enum '${prefixValue.name}'.");
    } else if (prefixValue is BridgedEnumValue) {
      final bridgedEnumValue = prefixValue;
      Logger.debug(
          "[PrefixedIdentifier] Accessing property '$memberName' on BridgedEnumValue (within InterpretedEnumValue block): $bridgedEnumValue");
      try {
        // Use the get() method of BridgedEnumValue
        return bridgedEnumValue.get(memberName);
      } on ReturnException catch (e) {
        return e.value;
      } on RuntimeError {
        // Relaunch the RuntimeErrors directly
        rethrow;
      } catch (e, s) {
        // Catch other potential errors (ex: from the adapter)
        Logger.error(
            "[PrefixedIdentifier] Native exception during bridged enum property get '$bridgedEnumValue.$memberName': $e\n$s");
        throw RuntimeError(
            "Native error during bridged enum property get '$memberName' on $bridgedEnumValue: $e");
      }
    } else {
      try {
        final extensionMember =
            environment.findExtensionMember(prefixValue, memberName);

        if (extensionMember is InterpretedExtensionMethod) {
          // Handle extension getter call immediately
          if (extensionMember.isGetter) {
            Logger.debug(
                "[PrefixedIdentifier] Found extension getter '$memberName' (fallback). Calling...");
            final extensionPositionalArgs = [
              prefixValue
            ]; // Getter takes receiver
            return extensionMember.call(this, extensionPositionalArgs, {});
          } else if (!extensionMember.isOperator && !extensionMember.isSetter) {
            // Return extension method itself if it's not a getter/setter/operator
            Logger.debug(
                "[PrefixedIdentifier] Found extension method '$memberName' (fallback). Returning callable.");
            return extensionMember;
          }
          // If it's an operator or setter, we probably shouldn't reach here via PrefixedIdentifier
          // Fall through to Stdlib if it wasn't a getter or regular method.
        }
        // If no suitable extension found, proceed to Stdlib call
        Logger.debug(
            "[PrefixedIdentifier] No suitable extension found for '$memberName' (fallback). Trying Stdlib...");
      } on RuntimeError catch (findError) {
        // If findExtensionMember itself threw (e.g., type not found), proceed to Stdlib
        Logger.debug(
            "[PrefixedIdentifier] Error finding extension '$memberName' (fallback): ${findError.message}. Trying Stdlib...");
      }

      throw RuntimeError(
          "Cannot access property '$memberName' on target of type ${prefixValue?.runtimeType}.");
    }
  }

  @override
  Object? visitBinaryExpression(BinaryExpression node) {
    final operator = node.operator.type;
    final leftOperandValue = node.leftOperand.accept<Object?>(this);
    final rightOperandValue = node.rightOperand.accept<Object?>(this);

    Logger.debug("[BinaryExpression DEBUG] Operator: ${operator.lexeme}");
    Logger.debug("  Left operand type: ${leftOperandValue?.runtimeType}");
    Logger.debug("  Left operand value: $leftOperandValue");
    Logger.debug("  Right operand type: ${rightOperandValue?.runtimeType}");
    Logger.debug("  Right operand value: $rightOperandValue");

    if (leftOperandValue is AsyncSuspensionRequest) {
      return leftOperandValue;
    }
    if (rightOperandValue is AsyncSuspensionRequest) {
      return rightOperandValue;
    }
    // Handle logical OR (||) with short-circuiting FIRST
    if (operator == TokenType.BAR_BAR) {
      // Evaluate left operand FIRST
      final leftValue = leftOperandValue;
      if (leftValue is! bool) {
        throw RuntimeError(
            "Left operand of '||' must be bool, got ${leftValue?.runtimeType}.");
      }
      // If left is true, return true without evaluating right
      if (leftValue) return true;
      // Left is false, evaluate right operand
      final rightValue = rightOperandValue;
      if (rightValue is! bool) {
        throw RuntimeError(
            "Right operand of '||' must be bool, got ${rightValue?.runtimeType}.");
      }
      return rightValue;
    }

    // Handle logical AND (&&) with short-circuiting SECOND
    if (operator == TokenType.AMPERSAND_AMPERSAND) {
      // Evaluate left operand FIRST
      final leftValue = leftOperandValue;
      if (leftValue is! bool) {
        throw RuntimeError(
            "Left operand of '&&' must be bool, got ${leftValue?.runtimeType}.");
      }
      // If left is false, return false without evaluating right
      if (!leftValue) return false;
      // Left is true, evaluate right operand
      final rightValue = rightOperandValue;
      if (rightValue is! bool) {
        throw RuntimeError(
            "Right operand of '&&' must be bool, got ${rightValue?.runtimeType}.");
      }
      return rightValue;
    }
    if (operator == TokenType.QUESTION_QUESTION) {
      final leftValue = leftOperandValue;
      final rightValue = rightOperandValue;
      return leftValue ?? rightValue;
    }

    final leftBridgedInstance = toBridgedInstance(leftOperandValue);
    final left = leftBridgedInstance.$2
        ? leftBridgedInstance.$1!.nativeObject
        : (leftOperandValue is InterpretedFunction)
            ? leftOperandValue.call(this, [])
            : leftOperandValue;
    final rightBridgedInstance = toBridgedInstance(rightOperandValue);
    final right = rightBridgedInstance.$2
        ? rightBridgedInstance.$1!.nativeObject
        : (rightOperandValue is InterpretedFunction)
            ? rightOperandValue.call(this, [])
            : rightOperandValue;

    if (left is num && right is num) {
      switch (operator) {
        case TokenType.PLUS:
          return left + right;
        case TokenType.MINUS:
          return left - right;
        case TokenType.STAR:
          return left * right;
        case TokenType.SLASH:
          if (right == 0) throw RuntimeError("Division par zéro.");
          return left.toDouble() / right.toDouble();
        case TokenType.GT:
          return left > right;
        case TokenType.LT:
          return left < right;
        case TokenType.GT_EQ:
          return left >= right;
        case TokenType.LT_EQ:
          return left <= right;
        case TokenType.PERCENT:
          if (right == 0) throw RuntimeError("Modulo par zéro.");
          return left % right;
        case TokenType.TILDE_SLASH:
          if (right == 0) throw RuntimeError("Division entière par zéro.");
          return left ~/ right;
        default:
          break;
      }
    }

    // Moved this block BEFORE standard ==, !=, <, <=, >, >= checks
    final operatorName = operator.lexeme;

    // Check for class operator methods FIRST (before extensions and built-in operators)
    if (leftOperandValue is InterpretedInstance) {
      final operatorMethod = leftOperandValue.findOperator(operatorName);
      if (operatorMethod != null) {
        Logger.debug(
            "[BinaryExpression] Found class operator '$operatorName' on ${leftOperandValue.klass.name}. Calling...");
        try {
          return operatorMethod
              .bind(leftOperandValue)
              .call(this, [rightOperandValue], {});
        } on ReturnException catch (e) {
          return e.value;
        } catch (e) {
          throw RuntimeError(
              "Error executing class operator '$operatorName': $e");
        }
      }
    }

    // Only try extension immediately for operators where standard checks might bypass it
    // (e.g., ==, !=, <, >, <=, >= which have generic fallbacks)
    bool checkExtensionEarly = [
      '==',
      '!=',
      '<',
      '<=',
      '>',
      '>=',
      '|', // Also check early for missing operators like |
      '&', // and &
      '^' // and ^ if BigInt support was incomplete
      // Add other operators here if needed
    ].contains(operatorName);

    if (checkExtensionEarly) {
      try {
        final extensionOperator =
            environment.findExtensionMember(leftOperandValue, operatorName);

        if (extensionOperator is InterpretedExtensionMethod &&
            extensionOperator.isOperator) {
          Logger.debug(
              "[BinaryExpression] Found extension operator '$operatorName' (early check) for type ${leftOperandValue?.runtimeType}. Calling...");
          final extensionPositionalArgs = [leftOperandValue, rightOperandValue];
          try {
            return extensionOperator.call(this, extensionPositionalArgs, {});
          } on ReturnException catch (e) {
            return e.value;
          } catch (e) {
            throw RuntimeError(
                "Error executing extension operator '$operatorName': $e");
          }
        }
        // If no suitable extension operator found early, continue to standard checks
        Logger.debug(
            "[BinaryExpression] No suitable extension operator '$operatorName' found (early check) for type ${leftOperandValue?.runtimeType}. Continuing...");
      } on RuntimeError catch (findError) {
        // findExtensionMember throws if no member is found at all.
        Logger.debug(
            "[BinaryExpression] No extension member '$operatorName' found (early check) for type ${leftOperandValue?.runtimeType}. Error: ${findError.message}");
        // Continue to standard checks even if lookup failed early
      }
    }

    switch (operator.lexeme) {
      case '+':
        if (left is String && right is String) return left + right;
        if (left is BigInt && right is BigInt) return left + right;
        if (left is Duration && right is Duration) return left + right;
        if (left is List && right is List) return left + right;
      case '-':
        if (left is BigInt && right is BigInt) return left - right;
        if (left is Duration && right is Duration) return left - right;
      case '*':
        if (left is String && right is int) return left * right;
        if (left is BigInt && right is BigInt) return left * right;
        if (left is Duration && right is num) return left * right;
      case '/':
        if (left is BigInt && right is BigInt) return left / right;
      case '~/':
        if (left is BigInt && right is BigInt) return left ~/ right;
        if (left is Duration && right is int) return left ~/ right;
      case '%':
        if (left is BigInt && right is BigInt) return left % right;
      case '==':
        // Special handling for BridgedEnumValue comparison
        if (leftOperandValue is BridgedEnumValue &&
            rightOperandValue is BridgedEnumValue) {
          final result = leftOperandValue == rightOperandValue;
          return result;
        }

        // Special handling for mixed native enum and BridgedEnumValue comparison
        if ((leftOperandValue is BridgedEnumValue &&
                rightOperandValue is Enum) ||
            (leftOperandValue is Enum &&
                rightOperandValue is BridgedEnumValue)) {
          // Convert both to their native enum values for comparison
          final leftNative = leftOperandValue is BridgedEnumValue
              ? leftOperandValue.nativeValue
              : leftOperandValue;
          final rightNative = rightOperandValue is BridgedEnumValue
              ? rightOperandValue.nativeValue
              : rightOperandValue;

          final result = leftNative == rightNative;
          return result;
        }

        return left == right;
      case '!=':
        return left != right;
      case '<':
        return left as dynamic < right;
      case '<=':
        return left as dynamic <= right;
      case '>':
        return left as dynamic > right;
      case '>=':
        return left as dynamic >= right;
      case '^':
        if (left is int && right is int) return left ^ right;
        if (left is BigInt && right is BigInt) return left ^ right;
        throw RuntimeError('Unsupported binary operator "$operator"');
      case '&':
        if (left is int && right is int) return left & right;
        if (left is BigInt && right is BigInt) return left & right;
        throw RuntimeError('Unsupported binary operator "$operator"');
      case '|':
        if (left is int && right is int) return left | right;
        if (left is BigInt && right is BigInt) return left | right;
        throw RuntimeError('Unsupported binary operator "$operator"');
      case '>>':
        if (left is int && right is int) return left >> right;
        if (left is BigInt && right is int) return left >> right;
        throw RuntimeError('Unsupported binary operator "$operator"');
      case '<<':
        if (left is int && right is int) return left << right;
        if (left is BigInt && right is int) return left << right;
        throw RuntimeError('Unsupported binary operator "$operator"');
      case '>>>':
        if (left is int && right is int) return left >>> right;
        // Note: BigInt doesn't support >>> operator in Dart
        throw RuntimeError('Unsupported binary operator "$operator"');
      default:
        break;
    }

    if (operator == TokenType.PLUS && (left is String || right is String)) {
      return '${stringify(left)}${stringify(right)}'; // stringify already handles BridgedInstance indirectly via toString
    }

    if (!checkExtensionEarly) {
      // Only run this if we didn't already check (and potentially succeed/fail) earlier
      try {
        final extensionOperator =
            environment.findExtensionMember(leftOperandValue, operatorName);

        if (extensionOperator is InterpretedExtensionMethod &&
            extensionOperator.isOperator) {
          Logger.debug(
              "[BinaryExpression] Found extension operator '$operatorName' (late check) for type ${leftOperandValue?.runtimeType}. Calling...");
          final extensionPositionalArgs = [leftOperandValue, rightOperandValue];
          try {
            return extensionOperator.call(this, extensionPositionalArgs, {});
          } on ReturnException catch (e) {
            return e.value; // Should not happen for operators, but handle
          } catch (e) {
            throw RuntimeError(
                "Error executing extension operator '$operatorName': $e");
          }
        }
        Logger.debug(
            "[BinaryExpression] No suitable extension operator '$operatorName' found (late check) for type ${leftOperandValue?.runtimeType}.");
      } on RuntimeError catch (findError) {
        Logger.debug(
            "[BinaryExpression] No extension member '$operatorName' found (late check) for type ${leftOperandValue?.runtimeType}. Error: ${findError.message}");
        // Fall through to the final standard error below.
      }
    }

    throw RuntimeError(
        'Unsupported operator ($operator) for types ${leftOperandValue?.runtimeType} and ${rightOperandValue?.runtimeType}');
  }

  @override
  Object? visitIndexExpression(IndexExpression node) {
    final target = node.target;
    final index = node.index;
    final targetValue = target?.accept<Object?>(this);
    final indexValue = index.accept<Object?>(this);

    if (targetValue is AsyncSuspensionRequest) return targetValue;
    if (indexValue is AsyncSuspensionRequest) return indexValue;

    if (targetValue is Map) {
      return targetValue[indexValue];
    }
    if (targetValue is String && indexValue is int) {
      return targetValue[indexValue];
    } else if (targetValue is List) {
      if (indexValue is int) {
        if (indexValue < 0 || indexValue >= targetValue.length) {
          throw RuntimeError('Index out of range: $indexValue');
        }
        return targetValue[indexValue];
      } else {
        throw RuntimeError('List index must be an integer');
      }
    } else if (targetValue is InterpretedInstance) {
      // Check for class operator [] method
      final operatorMethod = targetValue.findOperator('[]');
      if (operatorMethod != null) {
        Logger.debug(
            "[visitIndexExpression] Found class operator '[]' on ${targetValue.klass.name}. Calling...");
        try {
          return operatorMethod.bind(targetValue).call(this, [indexValue], {});
        } on ReturnException catch (e) {
          return e.value;
        } catch (e) {
          throw RuntimeError("Error executing class operator '[]': $e");
        }
      }
    } else if (toBridgedInstance(targetValue).$2) {
      final bridgedInstance = toBridgedInstance(targetValue).$1!;
      final bridgedClass = bridgedInstance.bridgedClass;
      final operatorName = '[]';

      final methodAdapter =
          bridgedClass.findInstanceMethodAdapter(operatorName);

      if (methodAdapter != null) {
        Logger.debug(
            "[visitIndexExpression] Found bridged operator '$operatorName' for ${bridgedClass.name}. Calling adapter...");
        try {
          return methodAdapter(
              this, bridgedInstance.nativeObject, [indexValue], {});
        } catch (e, s) {
          Logger.error(
              "[visitIndexExpression] Native exception during bridged operator '$operatorName' on ${bridgedClass.name}: $e\\n$s");
          throw RuntimeError(
              "Native error during bridged operator '$operatorName' on ${bridgedClass.name}: $e");
        }
      }
      Logger.debug(
          "[visitIndexExpression] Bridged operator '$operatorName' not found directly for ${bridgedClass.name}. Trying extensions.");
    }

    const operatorNameForExtension = '[]';
    try {
      final extensionOperator = environment.findExtensionMember(
          targetValue, operatorNameForExtension);

      if (extensionOperator is InterpretedExtensionMethod &&
          extensionOperator.isOperator) {
        Logger.debug(
            "[IndexExpression] Found extension operator '[]' for type ${targetValue?.runtimeType}. Calling...");
        final extensionPositionalArgs = [targetValue, indexValue];
        try {
          return extensionOperator.call(this, extensionPositionalArgs, {});
        } on ReturnException catch (e) {
          return e.value;
        } catch (e) {
          throw RuntimeError("Error executing extension operator '[]': $e");
        }
      }
      Logger.debug(
          "[IndexExpression] No suitable extension operator '[]' found for type ${targetValue?.runtimeType}.");
    } on RuntimeError catch (findError) {
      Logger.debug(
          "[IndexExpression] No extension member '[]' found for type ${targetValue?.runtimeType}. Error: ${findError.message}");
    }

    throw RuntimeError(
        'Unsupported target for indexing: ${targetValue?.runtimeType}');
  }

  @override
  Object? visitAssignmentExpression(AssignmentExpression node) {
    final lhs = node.leftHandSide;
    // Evaluate RHS once, used by multiple branches below
    Object? rhsValue = node.rightHandSide.accept<Object?>(this);

    // Handle suspension on the right-hand side
    if (rhsValue is AsyncSuspensionRequest) {
      Logger.debug(
          "[visitAssignmentExpression] RHS suspended. Propagating suspension.");
      // The state machine (_determineNextNodeAfterAwait) will handle resumption.
      // It needs to know this AssignmentExpression was the context.
      return rhsValue;
    }
    // END NEW

    final operatorType = node.operator.type;

    // Case 1: Simple variable assignment (lexical or implicit this)
    if (lhs is SimpleIdentifier) {
      final variableName = lhs.name;

      Environment? definingEnv =
          environment.findDefiningEnvironment(variableName);

      if (definingEnv != null) {
        // Check if the variable is a LateVariable
        final variableValue = definingEnv.get(variableName);
        if (variableValue is LateVariable) {
          if (operatorType == TokenType.EQ) {
            // Simple assignment to late variable
            variableValue.assign(rhsValue);
            return rhsValue;
          } else {
            // Compound assignment to late variable
            final currentValue =
                variableValue.value; // May throw if not initialized
            Object? newValue =
                computeCompoundValue(currentValue, rhsValue, operatorType);
            variableValue.assign(newValue);
            return newValue;
          }
        } else {
          // Regular variable handling
          if (operatorType == TokenType.EQ) {
            return environment.assign(
                variableName, rhsValue); // Use original assign for lexical
          } else {
            // Handle compound assignments on lexical variables
            final currentValue =
                environment.get(variableName); // Get from lexical scope
            Object? newValue =
                computeCompoundValue(currentValue, rhsValue, operatorType);
            return environment.assign(
                variableName, newValue); // Assign back to lexical scope
          }
        }
      } else {
        try {
          final thisInstance = environment.get('this');
          if (thisInstance is InterpretedInstance) {
            if (operatorType == TokenType.EQ) {
              Logger.debug(
                  "[Assignment - implicit this] Checking for direct setter '$variableName' on ${thisInstance.runtimeType}");
              final setter =
                  thisInstance.klass.findInstanceSetter(variableName);
              if (setter != null) {
                Logger.debug(
                    "[Assignment - implicit this] Found direct setter. Calling...");
                // Call setter on 'this'
                setter.bind(thisInstance).call(this, [rhsValue], {});
                return rhsValue; // Assignment expression returns RHS value
              } else {
                Logger.debug(
                    "[Assignment - implicit this] No direct setter found. Trying extension setter for '$variableName' on ${thisInstance.runtimeType}");
                final extensionSetter =
                    environment.findExtensionMember(thisInstance, variableName);
                if (extensionSetter is InterpretedExtensionMethod &&
                    extensionSetter.isSetter) {
                  Logger.debug(
                      "[Assignment - implicit this] Found extension setter '$variableName'. Calling...");
                  final extensionPositionalArgs = [
                    thisInstance, // Target is 'this'
                    rhsValue // Value to assign
                  ];
                  try {
                    extensionSetter.call(this, extensionPositionalArgs, {});
                    Logger.debug(
                        "[Assignment - implicit this] Extension setter call finished.");
                    return rhsValue; // Simple assignment returns RHS
                  } catch (e) {
                    throw RuntimeError(
                        "Error executing extension setter '$variableName' via implicit 'this': $e");
                  }
                } else {
                  Logger.debug(
                      "[Assignment - implicit this] No extension setter found for '$variableName'. Falling back to direct field set.");
                  // Assign directly to field on 'this' (original fallback)
                  // WARNING: This might be incorrect if the intent was purely extension based.
                  // Dart would typically throw if no setter (direct or extension) exists and no field exists.
                  // Consider throwing here if direct field assignment isn't desired.
                  try {
                    thisInstance.set(variableName, rhsValue, this);
                    Logger.debug(
                        "[Assignment - implicit this] Direct field set successful (?).");
                    return rhsValue; // Assignment expression returns RHS value
                  } on RuntimeError catch (fieldSetError) {
                    Logger.debug(
                        "[Assignment - implicit this] Direct field set failed: ${fieldSetError.message}");
                    // If both direct setter, extension setter, and direct field set fail, THEN throw.
                    throw RuntimeError(
                        "Cannot assign to '$variableName' on implicit 'this': No setter (direct or extension) or assignable field found.");
                  }
                }
              }
            } else {
              // 1. Get current value from 'this' (field or getter)
              final currentValue = thisInstance
                  .get(variableName); // May throw if undefined on instance

              // 2. Calculate new value
              Object? newValue =
                  computeCompoundValue(currentValue, rhsValue, operatorType);

              // 3. Set new value on 'this' (field or setter)
              final setter =
                  thisInstance.klass.findInstanceSetter(variableName);
              if (setter != null) {
                setter.bind(thisInstance).call(this, [newValue], {});
              } else {
                thisInstance.set(variableName, newValue, this);
              }
              // Compound assignment returns the NEW value
              return newValue;
            }
          } else if (toBridgedInstance(thisInstance).$2) {
            if (rhsValue is BridgedEnumValue) {
              rhsValue = rhsValue.nativeValue;
            }
            final bridgedInstance = toBridgedInstance(thisInstance).$1!;
            final bridgedClass = bridgedInstance.bridgedClass;
            final setterAdapter =
                bridgedClass.findInstanceSetterAdapter(variableName);

            if (setterAdapter != null) {
              if (operatorType == TokenType.EQ) {
                // Simple assignment: this.bridgedProp = value
                Logger.debug(
                    "[Assignment] Assigning to bridged 'this'.$variableName via setter adapter.");
                setterAdapter(this, thisInstance.nativeObject, rhsValue);
                return rhsValue; // Simple assignment returns RHS value
              } else {
                // Compound assignment: this.bridgedProp op= value
                // 1. Get current value (requires a getter adapter)
                final getterAdapter =
                    bridgedClass.findInstanceGetterAdapter(variableName);
                if (getterAdapter == null) {
                  throw RuntimeError(
                      "Cannot perform compound assignment on '${bridgedClass.name}.$variableName' via implicit 'this': No getter found.");
                }
                final currentValue =
                    getterAdapter(this, thisInstance.nativeObject);
                // 2. Calculate new value
                Object? newValue =
                    computeCompoundValue(currentValue, rhsValue, operatorType);
                // 3. Set new value via setter adapter
                Logger.debug(
                    "[Assignment] Compound assigning to bridged 'this'.$variableName via setter adapter.");
                setterAdapter(this, thisInstance.nativeObject, newValue);
                return newValue; // Compound assignment returns new value
              }
            } else {
              // No setter adapter found
              throw RuntimeError(
                  "Cannot assign to property '$variableName' on bridged instance of '${bridgedClass.name}' accessed via implicit 'this': No setter found.");
            }
          } else {
            // 'this' exists but is not an InterpretedInstance or BridgedInstance
            throw RuntimeError(
                "Assigning to undefined variable '$variableName'.");
          }
        } on RuntimeError catch (e) {
          // If 'this' doesn't exist or getting/setting on 'this' failed
          // Use the original error if it came from get/set, otherwise standard undefined.
          if (e.message.contains("Undefined property '$variableName'") ||
              e.message.contains("Undefined static member")) {
            rethrow; // Propagate specific error from get/set
          }
          throw RuntimeError(
              "Assigning to undefined variable '$variableName'.");
        }
      }
    }

    // Case 2: PropertyAccess assignment (target.property op= value)
    else if (lhs is PropertyAccess) {
      final targetExpression = lhs.target; // Keep expression for check below
      final targetValue = targetExpression?.accept<Object?>(this);
      final propertyName = lhs.propertyName.name;
      // rhsValue and operatorType already available from the top

      if (targetValue is BoundSuper) {
        // This handles cases like: super.value = expression; or super.value += expression;
        final instance = targetValue.instance;
        final startClass = targetValue.startLookupClass;
        InterpretedClass? currentClass = startClass;
        InterpretedFunction? superSetter;
        InterpretedFunction? superGetter;

        // Look for the setter in the superclass hierarchy starting from startClass
        BridgedClass? bridgedSetter;
        while (currentClass != null) {
          final setter = currentClass.findInstanceSetter(propertyName);
          if (setter != null) {
            superSetter = setter;
            break;
          }
          // Check bridged superclass
          if (currentClass.bridgedSuperclass != null) {
            final bridged = currentClass.bridgedSuperclass!;
            if (bridged.setters.containsKey(propertyName)) {
              bridgedSetter = bridged;
              break;
            }
          }
          currentClass = currentClass.superclass;
        }

        // For compound operators, we also need to get the current value
        Object? currentValue;
        BridgedClass? bridgedGetter;
        if (operatorType != TokenType.EQ) {
          // First try to find a getter
          currentClass = startClass;
          while (currentClass != null) {
            final getter = currentClass.findInstanceGetter(propertyName);
            if (getter != null) {
              superGetter = getter;
              break;
            }
            // Check bridged superclass
            if (currentClass.bridgedSuperclass != null) {
              final bridged = currentClass.bridgedSuperclass!;
              if (bridged.getters.containsKey(propertyName)) {
                bridgedGetter = bridged;
                break;
              }
            }
            currentClass = currentClass.superclass;
          }

          // Get the current value using getter or bridged getter
          if (superGetter != null) {
            currentValue = superGetter.bind(instance).call(this, [], {});
          } else if (bridgedGetter != null) {
            final bridgedTarget = instance.bridgedSuperObject;
            if (bridgedTarget == null) {
              throw RuntimeError(
                  "Cannot access bridged property '$propertyName': bridgedSuperObject is null");
            }
            currentValue =
                bridgedGetter.getters[propertyName]!(this, bridgedTarget);
          } else {
            // Try to get field value directly
            try {
              currentValue = instance.get(propertyName);
            } catch (e) {
              throw RuntimeError(
                  "Cannot read '$propertyName' from superclass chain of '${instance.klass.name}' for compound 'super' assignment: $e");
            }
          }
        }

        if (operatorType == TokenType.EQ) {
          // Simple assignment: super.value = rhsValue
          if (superSetter != null) {
            superSetter.bind(instance).call(this, [rhsValue], {});
            return rhsValue;
          } else if (bridgedSetter != null) {
            final bridgedTarget = instance.bridgedSuperObject;
            if (bridgedTarget == null) {
              throw RuntimeError(
                  "Cannot set bridged property '$propertyName': bridgedSuperObject is null");
            }
            bridgedSetter.setters[propertyName]!(this, bridgedTarget, rhsValue);
            return rhsValue;
          } else {
            // Try direct field assignment
            try {
              instance.set(propertyName, rhsValue);
              return rhsValue;
            } catch (e) {
              throw RuntimeError(
                  "Setter for '$propertyName' not found in superclass chain of '${instance.klass.name}' for 'super' assignment: $e");
            }
          }
        } else {
          // Compound assignment: super.value += rhsValue, etc.
          // Compute new value
          final newValue =
              computeCompoundValue(currentValue, rhsValue, operatorType);

          // Set new value
          if (superSetter != null) {
            superSetter.bind(instance).call(this, [newValue], {});
          } else if (bridgedSetter != null) {
            final bridgedTarget = instance.bridgedSuperObject;
            if (bridgedTarget == null) {
              throw RuntimeError(
                  "Cannot set bridged property '$propertyName': bridgedSuperObject is null");
            }
            bridgedSetter.setters[propertyName]!(this, bridgedTarget, newValue);
          } else {
            // Try direct field assignment
            try {
              instance.set(propertyName, newValue);
            } catch (e) {
              throw RuntimeError(
                  "Cannot set '$propertyName' in superclass chain of '${instance.klass.name}' for compound 'super' assignment: $e");
            }
          }

          return newValue;
        }
      } else if (targetValue is InterpretedInstance) {
        // This code block was accidentally removed or modified, restore it.
        if (operatorType == TokenType.EQ) {
          // Simple assignment: target.property = rhsValue
          final setter = targetValue.klass.findInstanceSetter(propertyName);
          if (setter != null) {
            setter.bind(targetValue).call(this, [rhsValue], {});
            Logger.debug(
                "[Assignment] Assigned via direct setter for '$propertyName'");
            return rhsValue;
          }
          // No direct setter, try extension setter
          final extensionSetter =
              environment.findExtensionMember(targetValue, propertyName);
          if (extensionSetter is InterpretedExtensionMethod &&
              extensionSetter.isSetter) {
            Logger.debug(
                "[Assignment] Assigning via extension setter for '$propertyName'");
            final extensionPositionalArgs = [
              targetValue,
              rhsValue
            ]; // Target + value
            try {
              extensionSetter.call(this, extensionPositionalArgs, {});
              return rhsValue;
            } catch (e) {
              throw RuntimeError(
                  "Error executing extension setter '$propertyName': $e");
            }
          }
          // No direct or extension setter, assign to field
          Logger.debug(
              "[Assignment] No direct or extension setter found for '$propertyName', assigning to field.");
          targetValue.set(propertyName, rhsValue, this);
          return rhsValue; // Simple Assignment returns RHS value
        } else {
          // Compound assignment: target.property op= rhsValue
          // 1. Get current value
          final currentValue = targetValue
              .get(propertyName); // Use instance.get (handles field/getter)
          // 2. Calculate new value
          Object? newValue =
              computeCompoundValue(currentValue, rhsValue, operatorType);
          // 3. Set new value (via setter or direct field access)
          final setter = targetValue.klass.findInstanceSetter(propertyName);
          if (setter != null) {
            setter.bind(targetValue).call(this, [newValue], {});
          } else {
            // Assign directly to field if no setter (using the instance's set method)
            targetValue.set(propertyName, newValue, this);
          }
          return newValue; // Compound returns new value
        }
      }
      // Handle assignment to static property (targetValue is InterpretedClass)
      else if (targetValue is InterpretedClass) {
        if (operatorType == TokenType.EQ) {
          // Simple assignment: Class.property = rhsValue
          final staticSetter = targetValue.findStaticSetter(propertyName);
          if (staticSetter != null) {
            staticSetter.call(this, [rhsValue], {});
          } else {
            // Assign directly to static field if no setter
            targetValue.setStaticField(propertyName, rhsValue);
          }
          return rhsValue; // Simple Assignment returns RHS value
        } else {
          // Compound assignment: Class.property op= rhsValue
          // 1. Get current value (static field or getter)
          Object? currentValue;
          final staticGetter = targetValue.findStaticGetter(propertyName);
          if (staticGetter != null) {
            currentValue = staticGetter.call(this, [], {});
          } else {
            // If no getter, try getting the field directly
            try {
              currentValue = targetValue.getStaticField(propertyName);
            } catch (_) {
              throw RuntimeError(
                  "Cannot get value for compound assignment on static member '$propertyName'. No getter or field found.");
            }
          }

          // 2. Calculate new value
          Object? newValue =
              computeCompoundValue(currentValue, rhsValue, operatorType);

          // 3. Set new value (static setter or direct field access)
          final staticSetter = targetValue.findStaticSetter(propertyName);
          if (staticSetter != null) {
            staticSetter.call(this, [newValue], {});
          } else {
            targetValue.setStaticField(propertyName, newValue);
          }
          return newValue; // Compound returns new value
        }
      } else if (toBridgedInstance(targetValue).$2) {
        if (rhsValue is BridgedEnumValue) {
          rhsValue = rhsValue.nativeValue;
        }
        final bridgedInstance = toBridgedInstance(targetValue).$1!;
        final setterAdapter = bridgedInstance.bridgedClass
            .findInstanceSetterAdapter(propertyName);

        if (setterAdapter != null) {
          if (operatorType == TokenType.EQ) {
            // Simple assignment: bridgedInstance.property = value
            Logger.debug(
                "[Assignment] Assigning to bridged instance property '${bridgedInstance.bridgedClass.name}.$propertyName' via setter adapter.");
            setterAdapter(this, bridgedInstance.nativeObject, rhsValue);
            return rhsValue; // Simple assignment returns RHS value
          } else {
            // Compound assignment: bridgedInstance.property op= value
            // 1. Get current value (requires a getter adapter)
            final getterAdapter = bridgedInstance.bridgedClass
                .findInstanceGetterAdapter(propertyName);
            if (getterAdapter == null) {
              throw RuntimeError(
                  "Cannot perform compound assignment on '${bridgedInstance.bridgedClass.name}.$propertyName': No getter adapter found.");
            }
            final currentValue =
                getterAdapter(this, bridgedInstance.nativeObject);
            // 2. Calculate new value
            Object? newValue =
                computeCompoundValue(currentValue, rhsValue, operatorType);
            // 3. Set new value via setter adapter
            Logger.debug(
                "[Assignment] Compound assigning to bridged instance property '${bridgedInstance.bridgedClass.name}.$propertyName' via setter adapter.");
            setterAdapter(this, bridgedInstance.nativeObject, newValue);
            return newValue; // Compound assignment returns new value
          }
        } else {
          // No setter adapter found
          throw RuntimeError(
              "Cannot assign to property '$propertyName' on bridged instance of '${bridgedInstance.bridgedClass.name}': No setter adapter found.");
        }
      } else if (targetValue is BoundBridgedSuper) {
        if (rhsValue is BridgedEnumValue) {
          rhsValue = rhsValue.nativeValue;
        }
        // This handles: super.property = rhsValue; or super.property += rhsValue;
        final instance = targetValue.instance; // Instance 'this'
        final bridgedSuper = targetValue.startLookupClass;
        final nativeSuperObject = instance.bridgedSuperObject;

        if (nativeSuperObject == null) {
          throw RuntimeError(
              "Internal error: Cannot assign to super property '$propertyName' on bridged superclass '${bridgedSuper.name}' because the native super object is missing.");
        }

        // Find the bridged setter adapter
        final setterAdapter =
            bridgedSuper.findInstanceSetterAdapter(propertyName);

        if (operatorType == TokenType.EQ) {
          // Simple assignment
          if (setterAdapter != null) {
            try {
              // Call the setter adapter with the native object and the new value
              setterAdapter(this, nativeSuperObject, rhsValue);
              return rhsValue; // Assignment returns the right value
            } catch (e, s) {
              Logger.error(
                  "Native exception during super assignment to bridged setter '${bridgedSuper.name}.$propertyName': $e\\n$s");
              throw RuntimeError(
                  "Native error during super assignment to bridged setter '$propertyName': $e");
            }
          } else {
            // No setter found
            throw RuntimeError(
                "Setter for '$propertyName' not found in bridged superclass '${bridgedSuper.name}' for 'super' assignment.");
          }
        } else {
          // Compound assignment: super.property += rhsValue, etc.
          // Need both getter and setter
          final getterAdapter =
              bridgedSuper.findInstanceGetterAdapter(propertyName);
          if (getterAdapter == null) {
            throw RuntimeError(
                "Cannot perform compound assignment on bridged super property '${bridgedSuper.name}.$propertyName': No getter adapter found.");
          }
          if (setterAdapter == null) {
            throw RuntimeError(
                "Cannot perform compound assignment on bridged super property '${bridgedSuper.name}.$propertyName': No setter adapter found.");
          }

          try {
            // Get current value
            final currentValue = getterAdapter(this, nativeSuperObject);

            // Compute new value
            final newValue =
                computeCompoundValue(currentValue, rhsValue, operatorType);

            // Set new value
            setterAdapter(this, nativeSuperObject, newValue);

            return newValue;
          } catch (e, s) {
            Logger.error(
                "Native exception during compound super assignment to bridged property '${bridgedSuper.name}.$propertyName': $e\\n$s");
            throw RuntimeError(
                "Native error during compound super assignment to bridged property '$propertyName': $e");
          }
        }
      } else if (targetValue is BridgedEnum) {
        if (operatorType == TokenType.EQ) {
          // Simple assignment: Enum.property = rhsValue
          final staticSetter = targetValue.staticSetters[propertyName];
          if (staticSetter != null) {
            staticSetter(this, rhsValue);
            return rhsValue;
          } else {
            throw RuntimeError(
                "Bridged enum '${targetValue.name}' has no static setter named '$propertyName'.");
          }
        } else {
          // Compound assignment: Enum.property op= rhsValue
          final staticGetter = targetValue.staticGetters[propertyName];
          if (staticGetter == null) {
            throw RuntimeError(
                "Cannot perform compound assignment on bridged enum '${targetValue.name}.$propertyName': No static getter found.");
          }
          final currentValue = staticGetter(this);
          Object? newValue =
              computeCompoundValue(currentValue, rhsValue, operatorType);
          final staticSetter = targetValue.staticSetters[propertyName];
          if (staticSetter != null) {
            staticSetter(this, newValue);
            return newValue;
          } else {
            throw RuntimeError(
                "Bridged enum '${targetValue.name}' has no static setter named '$propertyName'.");
          }
        }
      } else if (targetValue is BridgedClass) {
        // Static assignment on bridged class via PropertyAccess
        if (operatorType == TokenType.EQ) {
          final staticSetter =
              targetValue.findStaticSetterAdapter(propertyName);
          if (staticSetter != null) {
            staticSetter(this, rhsValue);
            return rhsValue;
          } else {
            throw RuntimeError(
                "Bridged class '${targetValue.name}' has no static setter named '$propertyName'.");
          }
        } else {
          final staticGetter =
              targetValue.findStaticGetterAdapter(propertyName);
          if (staticGetter == null) {
            throw RuntimeError(
                "Cannot perform compound assignment on static member '${targetValue.name}.$propertyName': No static getter found.");
          }
          final currentValue = staticGetter(this);
          Object? newValue =
              computeCompoundValue(currentValue, rhsValue, operatorType);
          final staticSetter =
              targetValue.findStaticSetterAdapter(propertyName);
          if (staticSetter != null) {
            staticSetter(this, newValue);
            return newValue;
          } else {
            throw RuntimeError(
                "Bridged class '${targetValue.name}' has no static setter named '$propertyName'.");
          }
        }
      } else {
        throw RuntimeError(
            "Assignment target must be an instance, class, or super property, got ${targetValue?.runtimeType}.");
      }
    }
    // Case 3: PrefixedIdentifier assignment (prefix.identifier op= value)
    else if (lhs is PrefixedIdentifier) {
      final target = lhs.prefix.accept<Object?>(this);
      final propertyName = lhs.identifier.name;
      // rhsValue and operatorType already available from the top

      if (target is InterpretedInstance) {
        if (operatorType == TokenType.EQ) {
          // Simple assignment: target.property = rhsValue
          final setter = target.klass.findInstanceSetter(propertyName);
          if (setter != null) {
            setter.bind(target).call(this, [rhsValue], {});
            Logger.debug(
                "[Assignment] Assigned via direct setter for PrefixedIdentifier '$propertyName'");
            return rhsValue;
          }

          final extensionSetter =
              environment.findExtensionMember(target, propertyName);
          if (extensionSetter is InterpretedExtensionMethod &&
              extensionSetter.isSetter) {
            Logger.debug(
                "[Assignment] Assigning via extension setter for PrefixedIdentifier '$propertyName'");
            final extensionPositionalArgs = [
              target,
              rhsValue
            ]; // Target + value
            try {
              extensionSetter.call(this, extensionPositionalArgs, {});
              return rhsValue;
            } catch (e) {
              throw RuntimeError(
                  "Error executing extension setter '$propertyName': $e");
            }
          }

          Logger.debug(
              "[Assignment] No direct or extension setter found for PrefixedIdentifier '$propertyName', assigning to field.");
          target.set(propertyName, rhsValue, this);
          return rhsValue; // Simple Assignment returns RHS value
        } else {
          // Compound assignment: target.property op= rhsValue
          final currentValue = target.get(propertyName);
          Object? newValue =
              computeCompoundValue(currentValue, rhsValue, operatorType);
          final setter = target.klass.findInstanceSetter(propertyName);
          if (setter != null) {
            setter.bind(target).call(this, [newValue], {});
          } else {
            target.set(propertyName, newValue, this);
          }
          return newValue; // Compound returns new value
        }
      } else if (target is InterpretedClass) {
        if (operatorType == TokenType.EQ) {
          // Simple assignment: Class.property = rhsValue
          final staticSetter = target.findStaticSetter(propertyName);
          if (staticSetter != null) {
            staticSetter.call(this, [rhsValue], {});
          } else {
            // Assign directly to static field if no setter
            target.setStaticField(propertyName, rhsValue);
          }
          return rhsValue; // Simple Assignment returns RHS value
        } else {
          // Compound assignment: Class.property op= rhsValue
          Object? currentValue;
          final staticGetter = target.findStaticGetter(propertyName);
          if (staticGetter != null) {
            currentValue = staticGetter.call(this, [], {});
          } else {
            try {
              currentValue = target.getStaticField(propertyName);
            } catch (_) {
              throw RuntimeError(
                  "Cannot get value for compound assignment on static member '$propertyName'. No getter or field found.");
            }
          }
          Object? newValue =
              computeCompoundValue(currentValue, rhsValue, operatorType);
          final staticSetter = target.findStaticSetter(propertyName);
          if (staticSetter != null) {
            staticSetter.call(this, [newValue], {});
          } else {
            target.setStaticField(propertyName, newValue);
          }
          return newValue; // Compound returns new value
        }
      } else if (target is BridgedClass) {
        final bridgedClass = target;
        if (operatorType == TokenType.EQ) {
          // Simple assignment: BridgedClass.property = rhsValue
          final staticSetter =
              bridgedClass.findStaticSetterAdapter(propertyName);
          if (staticSetter == null) {
            throw RuntimeError(
                "Bridged class '${bridgedClass.name}' has no static setter named '$propertyName'.");
          }
          Logger.debug(
              "[Assignment] Assigning to static bridged property '${bridgedClass.name}.$propertyName' via setter adapter.");
          staticSetter(this, rhsValue);
          return rhsValue; // Simple Assignment returns RHS value
        } else {
          // Compound assignment: BridgedClass.property op= rhsValue
          // 1. Get current static value
          final staticGetter =
              bridgedClass.findStaticGetterAdapter(propertyName);
          if (staticGetter == null) {
            throw RuntimeError(
                "Cannot perform compound assignment on static '${bridgedClass.name}.$propertyName': No static getter found.");
          }
          final currentValue = staticGetter(this);
          // 2. Calculate new value
          Object? newValue =
              computeCompoundValue(currentValue, rhsValue, operatorType);
          // 3. Set new static value
          final staticSetter =
              bridgedClass.findStaticSetterAdapter(propertyName);
          if (staticSetter == null) {
            // Should have been caught by getter check, but defensive programming
            throw RuntimeError(
                "Cannot perform compound assignment on static '${bridgedClass.name}.$propertyName': No static setter found after getter.");
          }
          Logger.debug(
              "[Assignment] Compound assigning to static bridged property '${bridgedClass.name}.$propertyName' via setter adapter.");
          staticSetter(this, newValue);
          return newValue; // Compound returns new value
        }
      } else if (target is BridgedEnum) {
        if (operatorType == TokenType.EQ) {
          // Simple assignment: BridgedEnum.property = rhsValue
          final staticSetter = target.staticSetters[propertyName];
          if (staticSetter == null) {
            throw RuntimeError(
                "Bridged enum '${target.name}' has no static setter named '$propertyName'.");
          }
          Logger.debug(
              "[Assignment] Assigning to static bridged property '${target.name}.$propertyName' via setter adapter.");
          staticSetter(this, rhsValue);
          return rhsValue; // Simple Assignment returns RHS value
        } else {
          // Compound assignment: BridgedEnum.property op= rhsValue
          // 1. Get current static value
          final staticGetter = target.staticGetters[propertyName];
          if (staticGetter == null) {
            throw RuntimeError(
                "Cannot perform compound assignment on static '${target.name}.$propertyName': No static getter found.");
          }
          final currentValue = staticGetter(this);
          // 2. Calculate new value
          Object? newValue =
              computeCompoundValue(currentValue, rhsValue, operatorType);
          // 3. Set new static value
          final staticSetter = target.staticSetters[propertyName];
          if (staticSetter == null) {
            throw RuntimeError(
                "Cannot perform compound assignment on static '${target.name}.$propertyName': No static setter found after getter.");
          }
          Logger.debug(
              "[Assignment] Compound assigning to static bridged property '${target.name}.$propertyName' via setter adapter.");
          staticSetter(this, newValue);
          return newValue; // Compound returns new value
        }
      } else if (target is InterpretedExtension) {
        final extension = target;
        if (operatorType == TokenType.EQ) {
          // Simple assignment: Extension.staticField = rhsValue
          final staticSetter = extension.findStaticSetter(propertyName);
          if (staticSetter != null) {
            staticSetter.call(this, [rhsValue], {});
            Logger.debug(
                "[Assignment] Assigned to static extension property '${extension.name ?? '<unnamed>'}.$propertyName' via setter.");
          } else if (extension.staticFields.containsKey(propertyName)) {
            extension.setStaticField(propertyName, rhsValue);
            Logger.debug(
                "[Assignment] Assigned to static extension field '${extension.name ?? '<unnamed>'}.$propertyName'.");
          } else {
            throw RuntimeError(
                "Extension '${extension.name ?? '<unnamed>'}' has no static setter or field named '$propertyName'.");
          }
          return rhsValue;
        } else {
          // Compound assignment: Extension.property op= rhsValue
          // 1. Get current value
          Object? currentValue;
          final staticGetter = extension.findStaticGetter(propertyName);
          if (staticGetter != null) {
            currentValue = staticGetter.call(this, [], {});
          } else if (extension.staticFields.containsKey(propertyName)) {
            currentValue = extension.getStaticField(propertyName);
          } else {
            throw RuntimeError(
                "Cannot get value for compound assignment on static extension member '$propertyName'. No getter or field found.");
          }
          // 2. Calculate new value
          Object? newValue =
              computeCompoundValue(currentValue, rhsValue, operatorType);
          // 3. Set new value
          final staticSetter = extension.findStaticSetter(propertyName);
          if (staticSetter != null) {
            staticSetter.call(this, [newValue], {});
          } else if (extension.staticFields.containsKey(propertyName)) {
            extension.setStaticField(propertyName, newValue);
          } else {
            throw RuntimeError(
                "Cannot set value for compound assignment on static extension member '$propertyName'. No setter or field found.");
          }
          return newValue;
        }
      } else if (toBridgedInstance(target).$2) {
        if (rhsValue is BridgedEnumValue) {
          rhsValue = rhsValue.nativeValue;
        }
        final bridgedInstance = toBridgedInstance(target).$1!;

        final setterAdapter = bridgedInstance.bridgedClass
            .findInstanceSetterAdapter(propertyName);

        if (setterAdapter != null) {
          if (operatorType == TokenType.EQ) {
            // Simple assignment: bridgedInstance.property = value
            Logger.debug(
                "[Assignment - PropertyAccess] Assigning to bridged instance property '${bridgedInstance.bridgedClass.name}.$propertyName' via setter adapter.");
            setterAdapter(this, bridgedInstance.nativeObject, rhsValue);
            return rhsValue; // Simple assignment returns RHS value
          } else {
            // Compound assignment: bridgedInstance.property op= value
            // 1. Get current value (requires a getter adapter)
            final getterAdapter = bridgedInstance.bridgedClass
                .findInstanceGetterAdapter(propertyName);
            if (getterAdapter == null) {
              throw RuntimeError(
                  "Cannot perform compound assignment on '${bridgedInstance.bridgedClass.name}.$propertyName': No getter adapter found.");
            }
            final currentValue =
                getterAdapter(this, bridgedInstance.nativeObject);
            // 2. Calculate new value
            Object? newValue =
                computeCompoundValue(currentValue, rhsValue, operatorType);
            // 3. Set new value via setter adapter
            Logger.debug(
                "[Assignment - PropertyAccess] Compound assigning to bridged instance property '${bridgedInstance.bridgedClass.name}.$propertyName' via setter adapter.");
            setterAdapter(this, bridgedInstance.nativeObject, newValue);
            return newValue; // Compound assignment returns new value
          }
        } else {
          // No setter adapter found
          throw RuntimeError(
              "Cannot assign to property '$propertyName' on bridged instance of '${bridgedInstance.bridgedClass.name}': No setter adapter found.");
        }
      } else {
        throw RuntimeError(
            "Assignment target must be an instance or class for PrefixedIdentifier, got ${target?.runtimeType}.");
      }
    } else {
      if (lhs is IndexExpression) {
        final targetValue = lhs.target?.accept<Object?>(this);
        final indexValue = lhs.index.accept<Object?>(this);

        // Determine the value to actually assign
        Object? finalValueToAssign;
        if (operatorType == TokenType.EQ) {
          finalValueToAssign = rhsValue; // Simple assignment
        } else {
          // Compound assignment (e.g., list[i] += 10)
          // 1. Get current value using index operator []
          Object? currentValue;
          if (targetValue is Map) {
            currentValue = targetValue[indexValue];
          } else if (targetValue is List && indexValue is int) {
            if (indexValue < 0 || indexValue >= targetValue.length) {
              throw RuntimeError(
                  'Index out of range for compound assignment read: $indexValue');
            }
            currentValue = targetValue[indexValue];
          } else if (targetValue is InterpretedInstance) {
            // Check for class operator [] method for reading current value
            final operatorMethod = targetValue.findOperator('[]');
            if (operatorMethod != null) {
              try {
                currentValue = operatorMethod
                    .bind(targetValue)
                    .call(this, [indexValue], {});
              } on ReturnException catch (e) {
                currentValue = e.value;
              } catch (e) {
                throw RuntimeError(
                    "Error executing class operator '[]' for compound read: $e");
              }
            } else {
              // No class operator found, try extensions
              try {
                final extensionGetter =
                    environment.findExtensionMember(targetValue, '[]');
                if (extensionGetter is InterpretedExtensionMethod &&
                    extensionGetter.isOperator) {
                  final extensionPositionalArgs = [targetValue, indexValue];
                  try {
                    currentValue =
                        extensionGetter.call(this, extensionPositionalArgs, {});
                  } on ReturnException catch (e) {
                    currentValue = e.value;
                  } catch (e) {
                    throw RuntimeError(
                        "Error executing extension operator '[]' for compound read: $e");
                  }
                } else {
                  throw RuntimeError(
                      'Cannot read current value for compound index assignment on ${targetValue.klass.name}: No operator [] found (class or extension).');
                }
              } on RuntimeError catch (e) {
                throw RuntimeError(
                    'Cannot read current value for compound index assignment on ${targetValue.klass.name}: ${e.message}');
              }
            }
          } else if (toBridgedInstance(targetValue).$2) {
            // Handle BridgedInstance for reading current value via [] operator
            final bridgedInstance = toBridgedInstance(targetValue).$1!;
            final bridgedClass = bridgedInstance.bridgedClass;
            final operatorName = '[]';

            final methodAdapter =
                bridgedClass.findInstanceMethodAdapter(operatorName);
            if (methodAdapter != null) {
              Logger.debug(
                  "[visitAssignmentExpression-Index] Found bridged operator '$operatorName' for ${bridgedClass.name}. Calling adapter for compound read...");
              try {
                currentValue = methodAdapter(
                    this, bridgedInstance.nativeObject, [indexValue], {});
              } catch (e, s) {
                Logger.error(
                    "[visitAssignmentExpression-Index] Native exception during bridged operator '$operatorName' read on ${bridgedClass.name}: $e\\n$s");
                throw RuntimeError(
                    "Native error during bridged operator '$operatorName' read on ${bridgedClass.name}: $e");
              }
            } else {
              throw RuntimeError(
                  'Cannot read current value for compound index assignment on ${bridgedClass.name}: No bridged operator [] found.');
            }
          } else {
            try {
              final extensionGetter =
                  environment.findExtensionMember(targetValue, '[]');
              if (extensionGetter is InterpretedExtensionMethod &&
                  extensionGetter.isOperator) {
                final extensionPositionalArgs = [targetValue, indexValue];
                try {
                  currentValue =
                      extensionGetter.call(this, extensionPositionalArgs, {});
                } on ReturnException catch (e) {
                  currentValue = e.value;
                } // Handle potential returns
                catch (e) {
                  throw RuntimeError(
                      "Error executing extension operator '[]' for compound read: $e");
                }
              } else {
                throw RuntimeError(
                    'Cannot read current value for compound index assignment on type ${targetValue?.runtimeType}: No standard or extension operator [] found.');
              }
            } on RuntimeError catch (e) {
              throw RuntimeError(
                  'Cannot read current value for compound index assignment on type ${targetValue?.runtimeType}: ${e.message}');
            }
          }

          // 2. Calculate the new value
          finalValueToAssign =
              computeCompoundValue(currentValue, rhsValue, operatorType);
        }

        // Now, perform the assignment with finalValueToAssign
        if (targetValue is Map) {
          targetValue[indexValue] = finalValueToAssign;
          return finalValueToAssign;
        } else if (targetValue is List && indexValue is int) {
          if (indexValue < 0 || indexValue >= targetValue.length) {
            throw RuntimeError(
                'Index out of range for assignment: $indexValue');
          }
          targetValue[indexValue] = finalValueToAssign;
          return finalValueToAssign;
        } else if (targetValue is InterpretedInstance) {
          // Check for class operator []= method
          final operatorMethod = targetValue.findOperator('[]=');
          if (operatorMethod != null) {
            Logger.debug(
                "[visitAssignmentExpression-Index] Found class operator '[]=' on ${targetValue.klass.name}. Calling...");
            try {
              operatorMethod
                  .bind(targetValue)
                  .call(this, [indexValue, finalValueToAssign], {});
              return finalValueToAssign;
            } on ReturnException catch (_) {
              return finalValueToAssign; // []= should not return a value, but assignment expression returns assigned value
            } catch (e) {
              throw RuntimeError("Error executing class operator '[]=': $e");
            }
          } else {
            // No class operator found, try extensions
            const operatorName = '[]=';
            try {
              final extensionSetter =
                  environment.findExtensionMember(targetValue, operatorName);
              if (extensionSetter is InterpretedExtensionMethod &&
                  extensionSetter.isOperator) {
                Logger.debug(
                    "[Assignment] Found extension operator '[]=' for ${targetValue.klass.name}. Calling...");
                // Args: receiver (targetValue), index (indexValue), value (finalValueToAssign)
                final extensionPositionalArgs = [
                  targetValue,
                  indexValue,
                  finalValueToAssign
                ];
                try {
                  extensionSetter.call(this, extensionPositionalArgs, {});
                  // '[]=' operator should not return a meaningful value, but the assignment expression returns the assigned value
                  return finalValueToAssign;
                } catch (e) {
                  throw RuntimeError(
                      "Error executing extension operator '[]=': $e");
                }
              } else {
                throw RuntimeError(
                    'Cannot assign to index on ${targetValue.klass.name}: No operator []= found (class or extension).');
              }
            } on RuntimeError catch (findError) {
              throw RuntimeError(
                  'Cannot assign to index on ${targetValue.klass.name}: ${findError.message}');
            }
          }
        } else if (toBridgedInstance(targetValue).$2) {
          final bridgedInstance = toBridgedInstance(targetValue).$1!;
          final bridgedClass = bridgedInstance.bridgedClass;
          final operatorName = '[]=';

          final methodAdapter =
              bridgedClass.findInstanceMethodAdapter(operatorName);
          if (methodAdapter != null) {
            Logger.debug(
                "[visitAssignmentExpression-Index] Found bridged operator '$operatorName' for ${bridgedClass.name}. Calling adapter...");
            try {
              methodAdapter(this, bridgedInstance.nativeObject,
                  [indexValue, finalValueToAssign], {});
              return finalValueToAssign;
            } catch (e, s) {
              Logger.error(
                  "[visitAssignmentExpression-Index] Native exception during bridged operator '$operatorName' on ${bridgedClass.name}: $e\\n$s");
              throw RuntimeError(
                  "Native error during bridged operator '$operatorName' on ${bridgedClass.name}: $e");
            }
          }
          throw RuntimeError(
              "[Bridged operator '$operatorName' not found directly for ${bridgedClass.name}. Trying extensions.");
        } else {
          const operatorName = '[]=';
          try {
            final extensionSetter =
                environment.findExtensionMember(targetValue, operatorName);
            if (extensionSetter is InterpretedExtensionMethod &&
                extensionSetter.isOperator) {
              Logger.debug(
                  "[Assignment] Found extension operator '[]=' for type ${targetValue?.runtimeType}. Calling...");
              // Args: receiver (targetValue), index (indexValue), value (finalValueToAssign)
              final extensionPositionalArgs = [
                targetValue,
                indexValue,
                finalValueToAssign
              ];
              try {
                extensionSetter.call(this, extensionPositionalArgs, {});
                // '[]=' operator should not return a meaningful value, but the assignment expression returns the assigned value
                return finalValueToAssign;
              } catch (e) {
                throw RuntimeError(
                    "Error executing extension operator '[]=': $e");
              }
            } // else: No suitable extension operator found, fall through
            Logger.debug(
                "[Assignment] No suitable extension operator '[]=' found for type ${targetValue?.runtimeType}.");
          } on RuntimeError catch (findError) {
            Logger.debug(
                "[Assignment] No extension member '[]=' found for type ${targetValue?.runtimeType}. Error: ${findError.message}");
            // Fall through to the final error
          }

          // If neither standard nor extension assignment worked
          throw RuntimeError(
              'Unsupported target for index assignment: ${targetValue?.runtimeType}');
        }
      } else {
        throw UnimplementedError(
            'Assignation à une cible non gérée: ${lhs.runtimeType}');
      }
    }
  }

  @override
  Object? visitMethodInvocation(MethodInvocation node) {
    Object? calleeValue;
    Object? targetValue; // Keep track of the target object/class
    // Argument lists - declared here, evaluated later if needed

    // Determine if this is a conditional call by inspecting the source
    final isNullAware = node.toSource().contains('?.');

    if (node.target == null) {
      // Simple function call (or class constructor call)
      calleeValue = node.methodName.accept<Object?>(this);
      targetValue = null; // No target
    } else {
      // Property/Method call on a target (instance or class)
      targetValue = node.target!.accept<Object?>(this);
      final methodName = node.methodName.name;

      // Null safety support: if the target is null and the call is null-aware, return null
      if (targetValue == null) {
        if (isNullAware) {
          return null;
        }
        throw RuntimeError(
            "Cannot invoke method '$methodName' on null. Use '?.' for null-aware method invocation.");
      }

      // BLOCK FOR HANDLING PREFIXED IMPORTS
      if (targetValue is Environment) {
        Logger.debug(
            "[MethodInvocation] Target is an Environment (prefixed import '${node.target!.toSource()}'). Looking for method '$methodName' in this environment.");
        try {
          calleeValue = targetValue.get(methodName);
          // The 'targetValue' for the call will be null because this is not an instance method on the environment itself,
          // but a function retrieved from this environment.
          // Functions obtained in this way are already "autonomous" or correctly bound if they come from classes.
        } on RuntimeError catch (e) {
          throw RuntimeError(
              "Method '$methodName' not found in imported module '${node.target!.toSource()}'. Error: ${e.message}");
        }
        // calleeValue is now the function/method of the imported module.
        // The call logic will be handled in the final visitMethodInvocation.
      } else if (targetValue is InterpretedInstance) {
        // Instance method call
        try {
          // Get should return the BOUND method
          calleeValue = targetValue.get(methodName);
          Logger.debug(
              "[MethodInvocation] Found direct instance member '$methodName' on ${targetValue.klass.name}. Type: ${calleeValue?.runtimeType}");
        } on RuntimeError catch (e) {
          if (e.message.contains("Undefined property '$methodName'")) {
            Logger.debug(
                "[MethodInvocation] Direct instance method '$methodName' failed/not found on ${targetValue.klass.name}. Error: ${e.message}. Trying extension method...");
            try {
              final extensionCallable =
                  environment.findExtensionMember(targetValue, methodName);

              if (extensionCallable is InterpretedExtensionMethod &&
                  !extensionCallable
                      .isOperator && // Ensure it's a regular method
                  !extensionCallable.isGetter &&
                  !extensionCallable.isSetter) {
                Logger.debug(
                    "[MethodInvocation] Found extension method '$methodName'. Evaluating args and calling...");

                // Evaluate arguments (must be done here as direct call failed)
                final evaluationResult =
                    _evaluateArgumentsAsync(node.argumentList);
                if (evaluationResult is AsyncSuspensionRequest) {
                  return evaluationResult; // Propagate suspension
                }
                final (positionalArgs, namedArgs) =
                    evaluationResult as (List<Object?>, Map<String, Object?>);
                List<RuntimeType>? evaluatedTypeArguments;
                final typeArgsNode = node.typeArguments;
                if (typeArgsNode != null) {
                  evaluatedTypeArguments = typeArgsNode.arguments
                      .map((typeNode) => _resolveTypeAnnotation(typeNode))
                      .toList();
                }

                // Prepare arguments for extension method:
                // First arg is the receiver (the target instance)
                final extensionPositionalArgs = [
                  targetValue,
                  ...positionalArgs
                ];

                // Call the extension method
                try {
                  // Return the result of the extension call directly
                  return extensionCallable.call(this, extensionPositionalArgs,
                      namedArgs, evaluatedTypeArguments);
                } on ReturnException catch (returnExc) {
                  return returnExc.value;
                } catch (execError) {
                  throw RuntimeError(
                      "Error executing extension method '$methodName': $execError");
                }
              } else {
                // No suitable extension found, rethrow the original error from direct lookup
                Logger.debug(
                    "[MethodInvocation] Extension method '$methodName' not found or not applicable. Rethrowing original error.");
                throw RuntimeError(
                    "Instance of '${targetValue.klass.name}' has no method named '$methodName' and no suitable extension method found. Original error: (${e.message})");
              }
            } on RuntimeError catch (findError) {
              // Error during the findExtensionMember call itself
              Logger.debug(
                  "[MethodInvocation] Error during extension lookup for '$methodName': ${findError.message}. Rethrowing original error.");
              throw RuntimeError(
                  "Instance of '${targetValue.klass.name}' has no method named '$methodName'. Error during extension lookup: ${findError.message}. Original error: (${e.message})");
            }
          } else {
            // The error during direct get() wasn't "Undefined property", rethrow it
            rethrow;
          }
        }
        // We check if it's callable later (if direct lookup succeeded)
      } else if (targetValue is InterpretedEnumValue) {
        try {
          // Get should return the BOUND method (or execute getter)
          // Pass the visitor to potentially execute getters
          calleeValue = targetValue.get(methodName, this);
          Logger.debug(
              "[MethodInvocation] Found enum instance member '$methodName' on $targetValue. Type: ${calleeValue?.runtimeType}");
        } on RuntimeError catch (e) {
          // Try Extension Method if Direct Fails (similar to InterpretedInstance)
          if (e.message.contains("Undefined property '$methodName'")) {
            Logger.debug(
                "[MethodInvocation] Direct enum method '$methodName' failed/not found on $targetValue. Error: ${e.message}. Trying extension method...");
            try {
              final extensionCallable =
                  environment.findExtensionMember(targetValue, methodName);
              if (extensionCallable is InterpretedExtensionMethod &&
                  !extensionCallable.isOperator &&
                  !extensionCallable.isGetter &&
                  !extensionCallable.isSetter) {
                Logger.debug(
                    "[MethodInvocation] Found extension method '$methodName' for enum value. Evaluating args and calling...");
                final evaluationResult =
                    _evaluateArgumentsAsync(node.argumentList);
                if (evaluationResult is AsyncSuspensionRequest) {
                  return evaluationResult; // Propagate suspension
                }
                final (positionalArgs, namedArgs) =
                    evaluationResult as (List<Object?>, Map<String, Object?>);
                List<RuntimeType>?
                    evaluatedTypeArguments; // Handle type args if needed

                final extensionPositionalArgs = [
                  targetValue,
                  ...positionalArgs
                ];
                try {
                  return extensionCallable.call(this, extensionPositionalArgs,
                      namedArgs, evaluatedTypeArguments);
                } on ReturnException catch (returnExc) {
                  return returnExc.value;
                } catch (execError) {
                  throw RuntimeError(
                      "Error executing extension method '$methodName' on enum value: $execError");
                }
              } else {
                if (methodName == 'toString') {
                  return targetValue.toString();
                } else if (methodName == 'runtimeType') {
                  return targetValue.runtimeType;
                }
                Logger.debug(
                    "[MethodInvocation] Extension method '$methodName' for enum value not found or not applicable. Rethrowing original error.");
                throw RuntimeError(
                    "Enum value '$targetValue' has no method named '$methodName' and no suitable extension method found. Original error: (${e.message})");
              }
            } on RuntimeError catch (findError) {
              Logger.debug(
                  "[MethodInvocation] Error during extension lookup for '$methodName' on enum value: ${findError.message}. Rethrowing original error.");
              throw RuntimeError(
                  "Enum value '$targetValue' has no method named '$methodName'. Error during extension lookup: ${findError.message}. Original error: (${e.message})");
            }
          } else {
            rethrow; // Rethrow other errors from get()
          }
        }
      } else if (toBridgedInstance(targetValue).$2) {
        final bridgedInstance = toBridgedInstance(targetValue).$1!;
        final bridgedClass = bridgedInstance.bridgedClass;
        switch (methodName) {
          case 'toString':
            return targetValue.toString();
          default:
        }
        // Use directly methods because we need the BridgedMethodCallable
        final adapter = bridgedClass.methods[methodName];

        if (adapter != null) {
          final evaluationResult = _evaluateArgumentsAsync(node.argumentList);
          if (evaluationResult is AsyncSuspensionRequest) {
            return evaluationResult; // Propagate suspension
          }
          final (positionalArgs, namedArgs) =
              evaluationResult as (List<Object?>, Map<String, Object?>);

          try {
            // Call the adapter with the native object
            return adapter(
                this, bridgedInstance.nativeObject, positionalArgs, namedArgs);
          } on ReturnException catch (e) {
            // Native calls shouldn't throw ReturnException directly, but handle defensively
            return e.value;
          } catch (e, s) {
            // Add the stack trace for debugging
            Logger.log("Native Error Stack Trace: $s"); // Print stack trace
            // Catch potential errors from the native code/adapter
            throw RuntimeError(
                "Native error during bridged method call '$methodName' on ${bridgedClass.name}: $e");
          }
        } else {
          // No adapter found for this method name, try extension methods
          Logger.debug(
              "[visitMethodInvocation] Bridged method '$methodName' not found directly for ${bridgedClass.name}. Trying extensions.");
          try {
            final extensionMethod =
                environment.findExtensionMember(targetValue, methodName);
            if (extensionMethod is InterpretedExtensionMethod) {
              Logger.debug(
                  "[visitMethodInvocation] Found extension method '$methodName' for ${bridgedClass.name}. Calling...");
              final evaluationResult =
                  _evaluateArgumentsAsync(node.argumentList);
              if (evaluationResult is AsyncSuspensionRequest) {
                return evaluationResult; // Propagate suspension
              }
              final (positionalArgs, namedArgs) =
                  evaluationResult as (List<Object?>, Map<String, Object?>);

              final extensionArgs = <Object?>[targetValue];
              extensionArgs.addAll(positionalArgs);
              return extensionMethod.call(this, extensionArgs, namedArgs);
            } else {
              throw RuntimeError(
                  "Bridged class '${bridgedClass.name}' has no instance method named '$methodName'.");
            }
          } on RuntimeError catch (findError) {
            throw RuntimeError(
                "Bridged class '${bridgedClass.name}' has no instance method named '$methodName'. Error during extension lookup: ${findError.message}");
          }
        }
        // Note: This block returns directly or throws, it does not set calleeValue.
      }
      // Handle static method call OR NAMED CONSTRUCTOR call
      else if (targetValue is InterpretedClass) {
        // Check for NAMED CONSTRUCTOR first
        final namedConstructor = targetValue.findConstructor(methodName);
        if (namedConstructor != null) {
          // It's a named constructor call
          if (targetValue.isAbstract) {
            throw RuntimeError(
                "Cannot instantiate abstract class '${targetValue.name}'.");
          }

          final evaluationResult = _evaluateArgumentsAsync(node.argumentList);
          if (evaluationResult is AsyncSuspensionRequest) {
            return evaluationResult; // Propagate suspension
          }
          final (positionalArgs, namedArgs) =
              evaluationResult as (List<Object?>, Map<String, Object?>);

          try {
            // Handle factory constructors differently from regular constructors
            if (namedConstructor.isFactory) {
              // Factory constructors should create and return their own instance
              // Do NOT create an instance beforehand
              Logger.debug(
                  "[MethodInvocation] Calling factory constructor '$methodName' directly");
              final result =
                  namedConstructor.call(this, positionalArgs, namedArgs);
              return result;
            } else {
              // Regular constructor: create instance first, then call constructor
              // 1. Create and initialize instance fields (using the class's public helper)
              // Pass null for type arguments as they aren't applicable to named constructor resolution here
              final instance =
                  targetValue.createAndInitializeInstance(this, null);
              // 2. Bind 'this' and call the named constructor logic
              final boundConstructor = namedConstructor.bind(instance);
              boundConstructor.call(
                  this, positionalArgs, namedArgs); // Pass evaluated args
              // Constructor call implicitly returns the bound instance.
              return instance; // Return the created and potentially modified instance
            }
          } on ReturnException catch (e) {
            return e.value;
          } on RuntimeError catch (e) {
            throw RuntimeError(
                "Error during named constructor '$methodName' for class '${targetValue.name}': ${e.message}");
          }
        } else {
          // Not a named constructor, check for STATIC METHOD
          final staticMethod = targetValue.findStaticMethod(methodName);
          if (staticMethod != null) {
            calleeValue =
                staticMethod; // It's already the function, no binding needed
          } else {
            throw RuntimeError(
                "Class '${targetValue.name}' has no static method or named constructor named '$methodName'.");
          }
        }
      } else if (targetValue is InterpretedEnum) {
        final staticMethod = targetValue.staticMethods[methodName];
        if (staticMethod != null) {
          calleeValue = staticMethod; // Static method, no binding needed
        } else {
          // Check mixins for static methods (reverse order)
          bool found = false;
          for (final mixin in targetValue.mixins.reversed) {
            final mixinStaticMethod = mixin.findStaticMethod(methodName);
            if (mixinStaticMethod != null) {
              calleeValue = mixinStaticMethod;
              found = true;
              Logger.debug(
                  "[MethodInvocation] Found static method '$methodName' from mixin '${mixin.name}' for enum '${targetValue.name}'");
              break;
            }
          }

          if (!found) {
            // Before throwing, let's check if it's a built-in method call like 'values'
            // This could potentially be handled by the stdlib call later, but maybe check here?
            // For now, assume only user-defined static methods are intended.
            throw RuntimeError(
                "Enum '${targetValue.name}' has no static method named '$methodName'.");
          }
        }
      } else if (targetValue is InterpretedExtension) {
        // Static method call on extension
        final extension = targetValue;
        final staticMethod = extension.findStaticMethod(methodName);
        if (staticMethod != null) {
          calleeValue = staticMethod;
          Logger.debug(
              "[MethodInvocation] Found static method '$methodName' on extension '${extension.name ?? '<unnamed>'}'");
        } else {
          throw RuntimeError(
              "Extension '${extension.name ?? '<unnamed>'}' has no static method named '$methodName'.");
        }
      } else if (targetValue is BridgedEnumValue) {
        // This is a method call on a bridged enum value.
        // It must use the invoke() method of BridgedEnumValue.
        final evaluationResult = _evaluateArgumentsAsync(node.argumentList);
        if (evaluationResult is AsyncSuspensionRequest) {
          return evaluationResult; // Propagate suspension
        }
        final (positionalArgs, namedArgs) =
            evaluationResult as (List<Object?>, Map<String, Object?>);
        try {
          return targetValue.invoke(
              this, methodName, positionalArgs, namedArgs);
        } on RuntimeError {
          // Relaunch the RuntimeErrors directly
          rethrow;
        } catch (e, s) {
          // Catch other potential errors (ex: from the adapter)
          Logger.error(
              "[visitMethodInvocation] Native exception during bridged enum method call '$targetValue.$methodName': $e\n$s");
          throw RuntimeError(
              "Native error during bridged enum method call '$methodName' on $targetValue: $e");
        }
      } else if (targetValue is BridgedEnum) {
        // Static method call on bridged enum
        final bridgedEnum = targetValue;
        final staticMethodAdapter = bridgedEnum.staticMethods[methodName];
        if (staticMethodAdapter != null) {
          final evaluationResult = _evaluateArgumentsAsync(node.argumentList);
          if (evaluationResult is AsyncSuspensionRequest) {
            return evaluationResult; // Propagate suspension
          }
          final (positionalArgs, namedArgs) =
              evaluationResult as (List<Object?>, Map<String, Object?>);

          try {
            return staticMethodAdapter(this, positionalArgs, namedArgs);
          } on ReturnException catch (e) {
            return e.value;
          } on RuntimeError {
            rethrow;
          } catch (e, s) {
            Logger.error(
                "[visitMethodInvocation] Native exception during static bridged enum method call '${bridgedEnum.name}.$methodName': $e\n$s");
            throw RuntimeError(
                "Native error during static bridged enum method call '$methodName' on ${bridgedEnum.name}: $e");
          }
        } else {
          throw RuntimeError(
              "Bridged enum '${bridgedEnum.name}' has no static method named '$methodName'.");
        }
      } else if (targetValue is BridgedClass) {
        // This is a method call on a bridged class (bridged constructor or static method)
        final bridgedClass = targetValue;
        final methodName = node.methodName.name;
        Logger.debug(
            "[visitMethodInvocation] Target is BridgedClass: '$methodName' on '${bridgedClass.name}'");

        // 1. Try to find a constructor adapter
        final constructorAdapter =
            bridgedClass.findConstructorAdapter(methodName);

        if (constructorAdapter != null) {
          Logger.debug(
              "[visitMethodInvocation] Found Bridged CONSTRUCTOR adapter for '$methodName'");
          final evaluationResult = _evaluateArgumentsAsync(node.argumentList);
          if (evaluationResult is AsyncSuspensionRequest) {
            return evaluationResult; // Propagate suspension
          }
          final (positionalArgs, namedArgs) =
              evaluationResult as (List<Object?>, Map<String, Object?>);

          try {
            final nativeObject =
                constructorAdapter(this, positionalArgs, namedArgs);

            if (nativeObject == null) {
              throw RuntimeError(
                  "Bridged constructor adapter for '${bridgedClass.name}.$methodName' returned null unexpectedly.");
            }
            final bridgedInstance = BridgedInstance(bridgedClass, nativeObject);
            Logger.debug(
                "[visitMethodInvocation]   Created BridgedInstance wrapping native: ${nativeObject.runtimeType}");
            return bridgedInstance; // Retourner l'instance pontée créée
          } on RuntimeError catch (e) {
            // Relaunch the adapter error
            throw RuntimeError(
                "Error during bridged constructor '$methodName' for class '${bridgedClass.name}': ${e.message}");
          } catch (e, s) {
            // Catch native errors from the adapter/native constructor
            Logger.error(
                "[visitMethodInvocation] Native exception during bridged constructor '${bridgedClass.name}.$methodName': $e\n$s");
            throw RuntimeError(
                "Native error during bridged constructor '$methodName' for class '${bridgedClass.name}': $e");
          }
        } else {
          final staticMethodAdapter =
              bridgedClass.findStaticMethodAdapter(methodName);

          if (staticMethodAdapter != null) {
            Logger.debug(
                "[visitMethodInvocation] Found Bridged STATIC METHOD adapter for '$methodName'");
            final evaluationResult = _evaluateArgumentsAsync(node.argumentList);
            if (evaluationResult is AsyncSuspensionRequest) {
              return evaluationResult; // Propagate suspension
            }
            final (positionalArgs, namedArgs) =
                evaluationResult as (List<Object?>, Map<String, Object?>);

            try {
              final result =
                  staticMethodAdapter(this, positionalArgs, namedArgs);

              return result;
            } on RuntimeError catch (e) {
              throw RuntimeError(
                  "Error during static bridged method call '$methodName' on ${bridgedClass.name}: ${e.message}");
            } catch (e, s) {
              Logger.warn(
                  "[visitMethodInvocation] Native exception during static bridged method call '${bridgedClass.name}.$methodName': $e\n$s");
              throw RuntimeError(
                  "Native error during static bridged method call '$methodName' on ${bridgedClass.name}: $e");
            }
          } else {
            throw RuntimeError(
                "Bridged class '${bridgedClass.name}' has no constructor or static method named '$methodName'.");
          }
        }
      } else if (targetValue is BoundSuper) {
        final instance = targetValue.instance;
        final startClass = targetValue.startLookupClass;
        InterpretedClass? currentClass = startClass;
        InterpretedFunction? superMethod;

        // Look for the method in the superclass hierarchy
        while (currentClass != null) {
          final method = currentClass.findInstanceMethod(methodName);
          if (method != null) {
            superMethod = method;
            break;
          }
          currentClass = currentClass.superclass;
        }

        if (superMethod != null) {
          // Bind the found super method to the original instance ('this')
          calleeValue = superMethod.bind(instance);
        } else {
          throw RuntimeError(
              "Method '$methodName' not found in superclass chain of '${instance.klass.name}'.");
        }
        // Arguments are evaluated below, calleeValue is now the bound super method
      } else if (targetValue is BoundBridgedSuper) {
        final instance = targetValue.instance; // L'instance 'this' interprétée
        final bridgedSuper = targetValue.startLookupClass;
        final nativeSuperObject =
            instance.bridgedSuperObject; // Retrieve the native object

        if (nativeSuperObject == null) {
          throw RuntimeError(
              "Internal error: Cannot call super method '$methodName' on bridged superclass '${bridgedSuper.name}' because the native super object is missing.");
        }

        // Find the method adapter in the bridged class
        final methodAdapter =
            bridgedSuper.findInstanceMethodAdapter(methodName);

        if (methodAdapter != null) {
          // Evaluate the arguments
          final evaluationResult = _evaluateArgumentsAsync(node.argumentList);
          if (evaluationResult is AsyncSuspensionRequest) {
            return evaluationResult; // Propagate suspension
          }
          final (positionalArgs, namedArgs) =
              evaluationResult as (List<Object?>, Map<String, Object?>);

          // Call the adapter with the native object as target
          try {
            return methodAdapter(
                this, nativeSuperObject, positionalArgs, namedArgs);
          } catch (e, s) {
            Logger.error(
                "Native exception during super call to bridged method '${bridgedSuper.name}.$methodName': $e\n$s");
            throw RuntimeError(
                "Native error during super call to bridged method '$methodName': $e");
          }
        } else {
          throw RuntimeError(
              "Method '$methodName' not found in bridged superclass '${bridgedSuper.name}'.");
        }
        // This block returns directly or throws an exception
      }

      //
      else {
        final evaluationResult = _evaluateArgumentsAsync(node.argumentList);
        if (evaluationResult is AsyncSuspensionRequest) {
          return evaluationResult; // Propagate suspension
        }
        final (positionalArgs, namedArgs) =
            evaluationResult as (List<Object?>, Map<String, Object?>);
        List<RuntimeType>? evaluatedTypeArguments;
        final typeArgsNode = node.typeArguments;
        if (typeArgsNode != null) {
          evaluatedTypeArguments = typeArgsNode.arguments
              .map((typeNode) => _resolveTypeAnnotation(typeNode))
              .toList();
        }

        final extensionCallable =
            environment.findExtensionMember(targetValue, methodName);

        if (extensionCallable is InterpretedExtensionMethod) {
          Logger.debug(
              "[MethodInvocation] Found extension method '$methodName'. Calling...");
          // Prepend the target instance to the positional arguments for the extension call
          final extensionPositionalArgs = [targetValue, ...positionalArgs];
          try {
            // Call the extension method
            return extensionCallable.call(this, extensionPositionalArgs,
                namedArgs, evaluatedTypeArguments);
          } on ReturnException catch (e) {
            return e.value;
          } catch (e) {
            throw RuntimeError(
                "Error executing extension method '$methodName': $e");
          }
        } else {
          // No extension method found either, rethrow the original stdlib error
          Logger.debug(
              "[MethodInvocation] Extension method '$methodName' not found. Rethrowing original error.");
          throw RuntimeError(
              "Undefined property or method '$methodName' on ${targetValue.runtimeType}.");
        }
      }
    }

    // Check if the resolved value is callable
    if (calleeValue is Callable) {
      final evaluationResult = _evaluateArgumentsAsync(node.argumentList);
      if (evaluationResult is AsyncSuspensionRequest) {
        return evaluationResult; // Propagate suspension
      }
      final (positionalArgs, namedArgs) =
          evaluationResult as (List<Object?>, Map<String, Object?>);

      // Evaluate Type Arguments for Method Invocation
      List<RuntimeType>? evaluatedTypeArguments;
      final typeArgsNode = node.typeArguments;
      if (typeArgsNode != null) {
        evaluatedTypeArguments = typeArgsNode.arguments
            .map((typeNode) => _resolveTypeAnnotation(typeNode))
            .toList();
        Logger.debug(
            "[MethodInvocation] Evaluated type arguments: $evaluatedTypeArguments");
      }

      // Perform the call
      try {
        // The call logic now works for functions, bound instance methods,
        // static methods, and constructors (which are handled by InterpretedClass.call)
        // Pass the evaluated type arguments
        return calleeValue.call(
            this, positionalArgs, namedArgs, evaluatedTypeArguments);
      } on ReturnException catch (e) {
        return e.value;
      }
      // Catch other potential runtime errors from the call itself
    } else if (calleeValue is BridgedClass && node.target == null) {
      // Call of a bridged default constructor (ex: StringBuffer())
      final bridgedClass = calleeValue;
      final constructorAdapter = bridgedClass
          .findConstructorAdapter(''); // Search for the default constructor ''

      if (constructorAdapter != null) {
        Logger.debug(
            "[visitMethodInvocation] Calling default bridged constructor for '${bridgedClass.name}'");

        final evaluationResult = _evaluateArgumentsAsync(node.argumentList);
        if (evaluationResult is AsyncSuspensionRequest) {
          return evaluationResult; // Propagate suspension
        }
        final (positionalArgs, namedArgs) =
            evaluationResult as (List<Object?>, Map<String, Object?>);

        try {
          final nativeObject =
              constructorAdapter(this, positionalArgs, namedArgs);
          if (nativeObject == null) {
            throw RuntimeError(
                "Default bridged constructor adapter for '${bridgedClass.name}' returned null.");
          }
          final bridgedInstance = BridgedInstance(bridgedClass, nativeObject);
          Logger.debug(
              "[visitMethodInvocation]   Created BridgedInstance wrapping native: ${nativeObject.runtimeType}");
          return bridgedInstance;
        } on RuntimeError catch (e) {
          throw RuntimeError(
              "Error during default bridged constructor for '${bridgedClass.name}': ${e.message}");
        } catch (e, s) {
          Logger.error(
              "[visitMethodInvocation] Native exception during default bridged constructor '${bridgedClass.name}': $e\n$s");
          throw RuntimeError(
              "Native error during default bridged constructor for '${bridgedClass.name}': $e");
        }
      } else {
        // If we have a BridgedClass but no default constructor ''
        throw RuntimeError(
            "'${bridgedClass.name}' is not callable (no default constructor bridge found).");
      }
    } else {
      // Callee is NOT a standard Callable or a BridgedClass constructor
      // Try Extension 'call' Method
      const methodName = 'call';
      try {
        final extensionMethod =
            environment.findExtensionMember(calleeValue, methodName);

        if (extensionMethod is InterpretedExtensionMethod &&
            !extensionMethod
                .isOperator && // Ensure it's a regular method named 'call'
            !extensionMethod.isGetter &&
            !extensionMethod.isSetter) {
          Logger.debug(
              "[MethodInvoke] Found extension method 'call' for non-callable type ${calleeValue?.runtimeType}. Calling...");

          // Need to re-evaluate args here as they weren't necessarily evaluated
          // if calleeValue wasn't Callable earlier.
          final (positionalArgs, namedArgs) =
              _evaluateArguments(node.argumentList);
          List<RuntimeType>? evaluatedTypeArguments;
          final typeArgsNode = node.typeArguments;
          if (typeArgsNode != null) {
            evaluatedTypeArguments = typeArgsNode.arguments
                .map((typeNode) => _resolveTypeAnnotation(typeNode))
                .toList();
          }

          // Prepare arguments for extension method:
          // First arg is the receiver (the object being called)
          final extensionPositionalArgs = [calleeValue, ...positionalArgs];

          try {
            // Call the extension method
            return extensionMethod.call(this, extensionPositionalArgs,
                namedArgs, evaluatedTypeArguments);
          } on ReturnException catch (e) {
            return e.value;
          } catch (e) {
            throw RuntimeError("Error executing extension method 'call': $e");
          }
        }
        Logger.debug(
            "[MethodInvoke] No suitable extension method 'call' found for non-callable type ${calleeValue?.runtimeType}.");
      } on RuntimeError catch (findError) {
        Logger.debug(
            "[MethodInvoke] No extension member 'call' found for non-callable type ${calleeValue?.runtimeType}. Error: ${findError.message}");
        // Fall through to the final standard error below.
      }

      // Original Error: The expression evaluated did not yield a callable function or an object with a callable 'call' extension.
      String nameForError = "<unknown>";
      if (node.target == null) {
        nameForError = node.methodName.name;
      } else {
        nameForError = node.toString(); // Approximate representation
      }
      if (calleeValue != null) {
        return calleeValue;
      }
      throw RuntimeError(
          "'$nameForError' (type: ${calleeValue?.runtimeType}) is not callable and has no 'call' extension method.");
    }
  }

  // Update PropertyAccess to call getters AND handle 'super'
  @override
  Object? visitPropertyAccess(PropertyAccess node) {
    final target = node.target?.accept<Object?>(this);
    if (target is AsyncSuspensionRequest) {
      // Propagate suspension so the state machine resumes this node after resolution
      return target;
    }

    // Determine if this is a conditional access by inspecting the source
    final isNullAware = node.toSource().contains('?.');
    final propertyName = node.propertyName.name;

    // Null safety support: if the target is null and the access is null-aware, return null
    if (target == null) {
      if (isNullAware) {
        return null;
      }
      throw RuntimeError(
          "Cannot access property '$propertyName' on null. Use '?.' for null-aware access.");
    }

    Logger.debug(
        "[PropertyAccess: ${node.toSource()}] Target type: ${target.runtimeType}, Target value: ${target.toString()}");

    if (target is InterpretedInstance) {
      // Standard Instance Access: Try direct first, then extension
      try {
        final member = target.get(propertyName,
            visitor: this); // .get() handles inheritance
        if (member is InterpretedFunction && member.isGetter) {
          return member
              .call(this, [], {}); // .get already returned bound getter
        } else {
          return member; // field value or bound method
        }
      } on RuntimeError catch (e) {
        // Try Extension Lookup Before Error
        if (e.message.contains("Undefined property '$propertyName'")) {
          Logger.debug(
              "[PropertyAccess] Direct access failed for '$propertyName'. Trying extension lookup on ${target.runtimeType}.");
          try {
            final extensionMember =
                environment.findExtensionMember(target, propertyName);

            if (extensionMember is InterpretedExtensionMethod) {
              if (extensionMember.isGetter) {
                Logger.debug(
                    "[PropertyAccess] Found extension getter '$propertyName'. Calling...");
                // Getters are called with the instance as the first (and only) positional argument
                final extensionPositionalArgs = [target];
                return extensionMember.call(this, extensionPositionalArgs, {});
              } else if (!extensionMember.isOperator &&
                  !extensionMember.isSetter) {
                // Return the extension method itself (it's not bound yet)
                Logger.debug(
                    "[PropertyAccess] Found extension method '$propertyName'. Returning callable.");
                return extensionMember;
              }
            }
            // No suitable extension found, fall through to rethrow original error
            Logger.debug(
                "[PropertyAccess] No suitable extension member found for '$propertyName'.");
          } on RuntimeError catch (findError) {
            // Error during extension lookup itself
            Logger.debug(
                "[PropertyAccess] Error during extension lookup for '$propertyName': ${findError.message}");
            // Fall through to rethrow original error
          }
        }
        // Rethrow original error if it wasn't "Undefined property"or if extension lookup failed
        throw RuntimeError(
            "${e.message} (accessing property via PropertyAccess '$propertyName')");
      }
    } else if (target is InterpretedEnumValue) {
      try {
        // Get should execute the getter or return the field/bound method
        // Pass the visitor to potentially execute getters
        final member = target.get(propertyName, this);

        // Check if the result from get was already the final value (field or executed getter)
        // or if it's a bound method that shouldn't be called here.
        if (member is Callable) {
          // Property access should generally not return a raw callable method.
          // If get() returned a bound method, it means the propertyName matched a method name,
          // which is not what property access typically expects.
          // However, Dart allows accessing methods like properties to get a tear-off.
          // So, we return the bound method (Callable) here.
          Logger.debug(
              "[PropertyAccess] Accessed enum method '$propertyName' on $target as tear-off. Returning bound method.");
          return member;
        } else {
          // Must be a field value or the result of an executed getter.
          Logger.debug(
              "[PropertyAccess] Accessed enum field/getter '$propertyName' on $target. Value: $member");
          return member;
        }
      } on RuntimeError catch (e) {
        // Try Extension Getter if Direct Fails (similar to InterpretedInstance)
        if (e.message.contains("Undefined property '$propertyName'")) {
          Logger.debug(
              "[PropertyAccess] Direct access failed for '$propertyName' on enum $target. Trying extension lookup...");
          try {
            final extensionMember =
                environment.findExtensionMember(target, propertyName);
            if (extensionMember is InterpretedExtensionMethod) {
              if (extensionMember.isGetter) {
                Logger.debug(
                    "[PropertyAccess] Found extension getter '$propertyName' for enum. Calling...");
                final extensionPositionalArgs = [target];
                return extensionMember.call(this, extensionPositionalArgs, {});
              } else if (!extensionMember.isOperator &&
                  !extensionMember.isSetter) {
                Logger.debug(
                    "[PropertyAccess] Found extension method '$propertyName' for enum. Returning tear-off.");
                return extensionMember;
              }
            }
            Logger.debug(
                "[PropertyAccess] No suitable extension member found for '$propertyName' on enum.");
          } on RuntimeError catch (findError) {
            Logger.debug(
                "[PropertyAccess] Error during extension lookup for '$propertyName' on enum: ${findError.message}");
          }
        }
        // Rethrow original error or error from extension lookup
        throw RuntimeError(
            "${e.message} (accessing property via PropertyAccess '$propertyName' on enum value '$target')");
      }
    } else if (target is InterpretedEnum) {
      // Accessing static member on the enum itself
      InterpretedFunction? staticGetter = target.staticGetters[propertyName];
      if (staticGetter != null) {
        // Call the static getter
        return staticGetter.call(this, [], {});
      }
      Object? staticField = target.staticFields[propertyName];
      if (target.staticFields.containsKey(propertyName)) {
        // Return static field value (could be null)
        return staticField;
      }
      InterpretedFunction? staticMethod = target.staticMethods[propertyName];
      if (staticMethod != null) {
        // Return the static method itself (tear-off)
        return staticMethod;
      }

      // Check mixins for static members (reverse order)
      for (final mixin in target.mixins.reversed) {
        final mixinStaticGetter = mixin.findStaticGetter(propertyName);
        if (mixinStaticGetter != null) {
          Logger.debug(
              "[PropertyAccess] Found static getter '$propertyName' from mixin '${mixin.name}' for enum '${target.name}'");
          return mixinStaticGetter.call(this, [], {});
        }

        final mixinStaticMethod = mixin.findStaticMethod(propertyName);
        if (mixinStaticMethod != null) {
          Logger.debug(
              "[PropertyAccess] Found static method '$propertyName' from mixin '${mixin.name}' for enum '${target.name}'");
          return mixinStaticMethod;
        }

        // Check static fields - use try/catch since getStaticField throws if not found
        try {
          final mixinStaticField = mixin.getStaticField(propertyName);
          Logger.debug(
              "[PropertyAccess] Found static field '$propertyName' from mixin '${mixin.name}' for enum '${target.name}'");
          return mixinStaticField;
        } on RuntimeError {
          // Continue to next mixin
        }
      }

      // Check for built-in 'values'
      if (propertyName == 'values') {
        return target.valuesList;
      }

      // Not found
      throw RuntimeError(
          "Undefined static property '$propertyName' on enum '${target.name}'.");
    } else if (target is InterpretedClass) {
      // Static Access (no change)
      try {
        // Check static fields first (no inheritance for static fields in Dart)
        return target.getStaticField(propertyName);
      } on RuntimeError catch (_) {
        // If not a field, check static methods/getters
        InterpretedFunction? staticMember =
            target.findStaticGetter(propertyName);
        staticMember ??= target.findStaticMethod(propertyName);

        if (staticMember != null) {
          if (staticMember.isGetter) {
            return staticMember.call(this, [], {}); // Call static getter
          } else {
            // Return static method function itself (not bound)
            return staticMember;
          }
        } else {
          throw RuntimeError(
              "Undefined static member '$propertyName' on class '${target.name}'.");
        }
      }
    } else if (target is BoundSuper) {
      // Super Property Access
      final instance = target.instance;
      final startClass = target.startLookupClass;
      InterpretedClass? currentClass =
          startClass; // Start search from superclass

      while (currentClass != null) {
        // Check instance field in the bound instance's fields
        // Use the new public getter on the instance to access the field value
        try {
          final fieldValue = instance.getField(propertyName);
          // Field found on the instance, return its value regardless of where we are in the super hierarchy lookup
          return fieldValue;
        } on RuntimeError {
          // Field doesn't exist directly on the instance, continue searching for getters/methods
        }

        // Check instance getter in the current class in hierarchy
        final getter = currentClass.findInstanceGetter(propertyName);
        if (getter != null) {
          // Bind getter to the original instance and call
          return getter.bind(instance).call(this, [], {});
        }
        // Check instance method (less common for property access, but possible)
        final method = currentClass.findInstanceMethod(propertyName);
        if (method != null) {
          // Bind method to the original instance and return the bound method
          return method.bind(instance);
        }
        // Move up the hierarchy
        currentClass = currentClass.superclass;
      }
      // Not found in superclass hierarchy
      throw RuntimeError(
          "Undefined property '$propertyName' accessed via 'super' on instance of '${instance.klass.name}'.");
    } else if (target is BridgedEnum) {
      Logger.debug(
          "[PropertyAccess] Accessing value/member on BridgedEnum: ${target.name}.$propertyName");
      // 1. Try to get enum value
      final enumValue = target.getValue(propertyName);
      if (enumValue != null) return enumValue;

      // 2. Try static getter
      final staticGetter = target.staticGetters[propertyName];
      if (staticGetter != null) {
        try {
          return staticGetter(this);
        } catch (e, s) {
          Logger.error(
              "Native error during bridged enum static getter '$propertyName': $e\n$s");
          throw RuntimeError(
              "Native error during bridged enum static getter '$propertyName': $e");
        }
      }

      // 3. Static methods as tear-offs
      final staticMethod = target.staticMethods[propertyName];
      if (staticMethod != null) {
        return BridgedEnumStaticMethodCallable(
            target, staticMethod, propertyName);
      }

      throw RuntimeError(
          "Undefined member '$propertyName' on bridged enum '${target.name}'.");
    } else if (target is BridgedEnumValue) {
      Logger.debug(
          "[PropertyAccess] Accessing property '$propertyName' on BridgedEnumValue: $target");
      try {
        return target.get(propertyName, this);
      } on ReturnException catch (e) {
        return e.value;
      } on RuntimeError {
        rethrow;
      } catch (e, s) {
        Logger.error(
            "Native error during bridged enum property get '$target.$propertyName': $e\n$s");
        throw RuntimeError(
            "Native error during bridged enum property get '$propertyName' on $target: $e");
      }
    } else if (target is BridgedClass) {
      final bridgedClass = target;
      Logger.debug(
          "[PropertyAccess] Static access on BridgedClass: ${bridgedClass.name}.$propertyName");

      final staticGetter = bridgedClass.findStaticGetterAdapter(propertyName);
      if (staticGetter != null) {
        Logger.debug("[PropertyAccess]   Found static getter adapter.");
        return staticGetter(this); // Call static getter adapter
      }

      final staticMethod = bridgedClass.findStaticMethodAdapter(propertyName);
      if (staticMethod != null) {
        Logger.debug("[PropertyAccess]   Found static method adapter.");
        return BridgedStaticMethodCallable(
            bridgedClass, staticMethod, propertyName);
      } else {
        throw RuntimeError(
            "Undefined static member '$propertyName' on bridged class '${bridgedClass.name}'.");
      }
    } else if (toBridgedInstance(target).$2) {
      final bridgedInstance = toBridgedInstance(target).$1!;
      Logger.debug(
          "[PropertyAccess] Access on BridgedInstance: ${bridgedInstance.bridgedClass.name}.$propertyName");
      switch (propertyName) {
        case 'runtimeType':
          return target.runtimeType;
        case 'hashCode':
          return target.hashCode;
        default:
      }
      final getterAdapter =
          bridgedInstance.bridgedClass.findInstanceGetterAdapter(propertyName);
      if (getterAdapter != null) {
        Logger.debug("[PropertyAccess]   Found instance getter adapter.");
        return getterAdapter(
            this, bridgedInstance.nativeObject); // Call instance getter adapter
      }

      final methodAdapter =
          bridgedInstance.bridgedClass.findInstanceMethodAdapter(propertyName);
      if (methodAdapter != null) {
        Logger.debug(
            "[PropertyAccess]   Found instance method adapter. Binding...");
        // Return a callable bound to the instance
        return BridgedMethodCallable(
            bridgedInstance, methodAdapter, propertyName);
      }

      throw RuntimeError(
          "Undefined property or method '$propertyName' on bridged instance of '${bridgedInstance.bridgedClass.name}'.");
    } else if (target is InterpretedRecord) {
      // Accessing field of a record
      final record = target;
      Logger.debug(
          "[PropertyAccess] Access on InterpretedRecord: .$propertyName");
      // Check if it's a positional field access (\$1, \$2, ...)
      if (propertyName.startsWith('\$') && propertyName.length > 1) {
        try {
          final index = int.parse(propertyName.substring(1)) - 1;
          if (index >= 0 && index < record.positionalFields.length) {
            return record.positionalFields[index];
          } else {
            throw RuntimeError(
                "Record positional field index \$$index out of bounds (0..${record.positionalFields.length - 1}).");
          }
        } catch (e) {
          // Handle parse errors or other issues
          throw RuntimeError(
              "Invalid positional record field accessor '$propertyName'.");
        }
      } else {
        // Check if it's a named field access
        if (record.namedFields.containsKey(propertyName)) {
          return record.namedFields[propertyName];
        } else {
          throw RuntimeError(
              "Record has no field named '$propertyName'. Available fields: ${record.namedFields.keys.join(', ')}");
        }
      }
    } else if (target is BridgedEnumValue) {
      return target.get(propertyName);
    } else if (target is BridgedEnum) {
      Logger.debug(
          "[PropertyAccess] Accessing value on BridgedEnum: ${target.name}.$propertyName");
      final enumValue = target.getValue(propertyName);
      if (enumValue != null) {
        return enumValue; // Return the BridgedEnumValue
      } else {
        throw RuntimeError(
            "Undefined enum value '$propertyName' on bridged enum '${target.name}'.");
      }
    } else if (target is BoundBridgedSuper) {
      final instance = target.instance; // The interpreted 'this' instance
      final bridgedSuper = target.startLookupClass;
      final nativeSuperObject =
          instance.bridgedSuperObject; // Retrieve the native object

      if (nativeSuperObject == null) {
        throw RuntimeError(
            "Internal error: Cannot access super property '$propertyName' on bridged superclass '${bridgedSuper.name}' because the native super object is missing.");
      }

      // Try the bridged getter
      final getterAdapter =
          bridgedSuper.findInstanceGetterAdapter(propertyName);
      if (getterAdapter != null) {
        try {
          return getterAdapter(this, nativeSuperObject);
        } catch (e, s) {
          Logger.error(
              "Native exception during super access to bridged getter '${bridgedSuper.name}.$propertyName': $e\n$s");
          throw RuntimeError(
              "Native error during super access to bridged getter '$propertyName': $e");
        }
      }

      // Try the bridged method (for tear-off)
      final methodAdapter =
          bridgedSuper.findInstanceMethodAdapter(propertyName);
      if (methodAdapter != null) {
        // Return a callable bound to the native object
        return BridgedSuperMethodCallable(
            nativeSuperObject, methodAdapter, propertyName, bridgedSuper.name);
      }

      // Not found
      throw RuntimeError(
          "Undefined property or method '$propertyName' accessed via 'super' on bridged superclass '${bridgedSuper.name}'.");
    } else {
      // Check if target is a native enum that has been bridged
      final bridgedEnumValue = environment.getBridgedEnumValue(target);
      if (bridgedEnumValue != null) {
        Logger.debug(
            "[PropertyAccess] Found bridged enum value for native enum ${target.runtimeType}");
        try {
          return bridgedEnumValue.get(propertyName);
        } catch (e) {
          throw RuntimeError(
              "Undefined property '$propertyName' on bridged enum value '${bridgedEnumValue.name}'.");
        }
      }

      Logger.debug(
          "[PropertyAccess] Looking for extension getter '$propertyName' for target type ${target.runtimeType}.");
      final extensionCallable =
          environment.findExtensionMember(target, propertyName);

      if (extensionCallable is InterpretedExtensionMethod &&
          extensionCallable.isGetter) {
        Logger.debug(
            "[PropertyAccess] Found extension getter '$propertyName'. Calling...");
        // Prepend the target instance to the positional arguments for the extension call
        final extensionPositionalArgs = [
          target
        ]; // Getters take no explicit args
        try {
          // Call the extension getter
          return extensionCallable.call(this, extensionPositionalArgs, {});
        } on ReturnException catch (e) {
          return e.value;
        } catch (e) {
          throw RuntimeError(
              "Error executing extension getter '$propertyName': $e");
        }
      } else {
        // No extension getter found either, rethrow the original stdlib error
        Logger.debug(
            "[PropertyAccess] Extension getter '$propertyName' not found. Rethrowing original error.");
        throw RuntimeError(
            "Undefined property or method '$propertyName' on ${target.runtimeType}.");
      }
    }
  }

  String stringify(Object? value) {
    if (value == null) return 'null';
    if (value is bool) return value.toString();
    return value.toString();
  }

  @override
  Object? visitIfStatement(IfStatement node) {
    Object? conditionValue; // Try to evaluate the condition
    conditionValue = node.expression.accept<Object?>(this);

    // If the evaluation returns an AsyncSuspensionRequest, return it immediately
    if (conditionValue is AsyncSuspensionRequest) {
      Logger.debug(
          "[IfStatement] Condition suspended (AsyncSuspensionRequest). Propagating.");
      return conditionValue;
    }

    // Synchronous logic (if no suspension occurred)
    bool conditionResult;
    final bridgedInstance = toBridgedInstance(conditionValue);
    if (conditionValue is bool) {
      conditionResult = conditionValue;
    } else if (bridgedInstance.$2 && bridgedInstance.$1?.nativeObject is bool) {
      conditionResult = bridgedInstance.$1!.nativeObject as bool;
    } else {
      throw RuntimeError(
          "The condition of an 'if' must be a boolean, but was ${conditionValue?.runtimeType}.");
    }

    if (conditionResult) {
      node.thenStatement.accept<Object?>(this);
    } else if (node.elseStatement != null) {
      node.elseStatement!.accept<Object?>(this);
    }

    return null; // The If instruction normally ends with null
  }

  @override
  Object? visitWhileStatement(WhileStatement node) {
    while (true) {
      // Handle condition being BridgedInstance<bool>
      final conditionValue = node.condition.accept<Object?>(this);
      bool conditionResult;
      final bridgedInstance = toBridgedInstance(conditionValue);
      if (conditionValue is bool) {
        conditionResult = conditionValue;
      } else if (bridgedInstance.$2 &&
          bridgedInstance.$1?.nativeObject is bool) {
        conditionResult = bridgedInstance.$1!.nativeObject as bool;
      } else {
        throw RuntimeError(
            "The condition of a 'while' loop must be a boolean, but was ${conditionValue?.runtimeType}.");
      }

      if (!conditionResult) {
        break;
      }

      try {
        // Condition is true, execute the body
        node.body.accept<Object?>(this);
      } on BreakException catch (e) {
        Logger.debug(
            "[While] Caught BreakException (label: ${e.label}) with current labels: $_currentStatementLabels");
        if (e.label == null || _currentStatementLabels.contains(e.label)) {
          // Unlabeled break OR labeled break targeting this loop.
          Logger.debug("[While] Breaking loop.");
          break; // Exit the while loop
        } else {
          // Labeled break targeting an outer construct.
          Logger.debug("[While] Rethrowing outer break...");
          rethrow;
        }
      } on ContinueException catch (e) {
        Logger.debug(
            "[While] Caught ContinueException (label: ${e.label}) with current labels: $_currentStatementLabels");
        if (e.label == null || _currentStatementLabels.contains(e.label)) {
          // Unlabeled continue OR labeled continue targeting this loop.
          Logger.debug("[While] Continuing loop.");
          continue; // Skip to the next iteration
        } else {
          // Labeled continue targeting an outer loop.
          Logger.debug("[While] Rethrowing outer continue...");
          rethrow;
        }
      }
      // Other exceptions will propagate up
    }
    return null;
  }

  @override
  Object? visitDoStatement(DoStatement node) {
    do {
      try {
        // Execute the body first
        node.body.accept<Object?>(this);
      } on BreakException catch (e) {
        Logger.debug(
            "[DoWhile] Caught BreakException (label: ${e.label}) with current labels: $_currentStatementLabels");
        if (e.label == null || _currentStatementLabels.contains(e.label)) {
          Logger.debug("[DoWhile] Breaking loop.");
          break; // Exit the do-while loop
        } else {
          Logger.debug("[DoWhile] Rethrowing outer break...");
          rethrow;
        }
      } on ContinueException catch (e) {
        Logger.debug(
            "[DoWhile] Caught ContinueException (label: ${e.label}) with current labels: $_currentStatementLabels");
        if (e.label == null || _currentStatementLabels.contains(e.label)) {
          Logger.debug("[DoWhile] Continuing loop condition check.");
          // For do-while, continue still needs to check the condition
          // So we fall through to the condition check below
        } else {
          Logger.debug("[DoWhile] Rethrowing outer continue...");
          rethrow;
        }
      }

      // Then evaluate the condition
      // Handle condition being BridgedInstance<bool>
      final conditionValue = node.condition.accept<Object?>(this);
      Logger.debug("[DoWhile] Condition value: $conditionValue");
      bool conditionResult;
      final bridgedInstance = toBridgedInstance(conditionValue);
      Logger.debug("[DoWhile] Bridged instance: $bridgedInstance");
      if (conditionValue is bool) {
        conditionResult = conditionValue;
      } else if (bridgedInstance.$2 &&
          bridgedInstance.$1?.nativeObject is bool) {
        conditionResult = bridgedInstance.$1!.nativeObject as bool;
      } else {
        throw RuntimeError(
            "The condition of a 'do-while' loop must be a boolean, but was ${conditionValue?.runtimeType}.");
      }

      if (!conditionResult) {
        break;
      }
    } while (true);

    return null;
  }

  @override
  Object? visitForStatement(ForStatement node) {
    final loopParts = node.forLoopParts;

    if (loopParts is ForPartsWithDeclarations) {
      // Classic for loop: for (var i = 0; ... ; ...)
      _executeClassicFor(loopParts.variables, loopParts.condition,
          loopParts.updaters, node.body);
    } else if (loopParts is ForPartsWithExpression) {
      // Classic for loop: for (i = 0; ... ; ...)
      _executeClassicFor(loopParts.initialization, loopParts.condition,
          loopParts.updaters, node.body);
    } else if (loopParts is ForEachPartsWithDeclaration) {
      // For-in loop: for (var item in list) or await for (var item in stream)
      if (node.awaitKeyword != null) {
        // await for loop - expect Stream
        return _executeAwaitForIn(
            loopParts.loopVariable, loopParts.iterable, node.body);
      } else {
        // Regular for-in loop - expect Iterable
        _executeForIn(loopParts.loopVariable, loopParts.iterable, node.body);
      }
    } else if (loopParts is ForEachPartsWithIdentifier) {
      // For-in loop: for (item in list) or await for (item in stream)
      if (node.awaitKeyword != null) {
        // await for loop - expect Stream
        return _executeAwaitForIn(
            loopParts.identifier, loopParts.iterable, node.body);
      } else {
        // Regular for-in loop - expect Iterable
        _executeForIn(loopParts.identifier, loopParts.iterable, node.body);
      }
    } else {
      // Should not happen with valid Dart code
      throw StateError('Unknown ForLoopParts type: ${loopParts.runtimeType}');
    }

    return null; // For loops don't produce a value
  }

  // Helper method to execute the logic of a classic for loop
  void _executeClassicFor(AstNode? initialization, Expression? condition,
      List<Expression>? updaters, Statement body) {
    // 1. Create loop environment
    final loopEnvironment = Environment(enclosing: environment);
    final previousEnvironment = environment;
    environment = loopEnvironment;

    try {
      // 2. Execute initialization (if it exists)
      if (initialization != null) {
        // If initialization is a VariableDeclarationList, visit it directly.
        // If it's an Expression (like in ForPartsWithExpression), visit it.
        initialization.accept<Object?>(this);
      }

      // 3. Loop execution
      while (true) {
        // 3.a Evaluate condition
        bool conditionResult = true; // Default to true if no condition
        if (condition != null) {
          final evalResult = condition.accept<Object?>(this);
          final bridgedInstance = toBridgedInstance(evalResult);
          if (evalResult is bool) {
            conditionResult = evalResult;
          } else if (bridgedInstance.$2 &&
              bridgedInstance.$1?.nativeObject is bool) {
            conditionResult = bridgedInstance.$1!.nativeObject as bool;
          } else {
            throw RuntimeError(
                "The condition of a 'for' loop must be a boolean, but was ${evalResult?.runtimeType}.");
          }
        }

        if (!conditionResult) {
          break;
        }

        // 3.b Execute body
        try {
          body.accept<Object?>(this);
        } on BreakException catch (e) {
          Logger.debug(
              "[For] Caught BreakException (label: ${e.label}) with current labels: $_currentStatementLabels");
          if (e.label == null || _currentStatementLabels.contains(e.label)) {
            Logger.debug("[For] Breaking loop.");
            break; // Exit the for loop entirely
          } else {
            Logger.debug("[For] Rethrowing outer break...");
            rethrow;
          }
        } on ContinueException catch (e) {
          Logger.debug(
              "[For] Caught ContinueException (label: ${e.label}) with current labels: $_currentStatementLabels");
          if (e.label == null || _currentStatementLabels.contains(e.label)) {
            Logger.debug("[For] Continuing to updaters.");
            // Skip directly to updaters for this iteration
            // The `continue` below will handle jumping to the next iteration
          } else {
            Logger.debug("[For] Rethrowing outer continue...");
            rethrow;
          }
        }

        // 3.c Execute updaters (if they exist)
        try {
          if (updaters != null) {
            for (final updater in updaters) {
              updater.accept<Object?>(this);
            }
          }
        } on BreakException {
          // This should technically not happen if break is only thrown from the body,
          // but handle defensively.
          break;
        }
        // Continue exception in updaters should just proceed to the next iteration check

        // `continue` effectively happens here by looping back
      }
    } finally {
      // 4. Restore previous environment
      environment = previousEnvironment;
    }
  }

  // Helper method to execute the logic of a for-in loop (simplified)
  void _executeForIn(AstNode loopVariableOrIdentifier,
      Expression iterableExpression, Statement body) {
    final expressionValue = iterableExpression.accept<Object?>(this);

    // Handle iterable being BridgedInstance<Iterable>
    Object? iterableValue;
    if (toBridgedInstance(expressionValue).$2) {
      final bridgedInstance = toBridgedInstance(expressionValue).$1!;
      if (bridgedInstance.nativeObject is Iterable) {
        iterableValue = bridgedInstance.nativeObject;
      } else {
        throw RuntimeError(
            'Value used in for-in loop must be an Iterable, but got BridgedInstance containing ${bridgedInstance.nativeObject.runtimeType}');
      }
    } else if (expressionValue is Iterable) {
      iterableValue = expressionValue;
    } else {
      throw RuntimeError(
          'Value used in for-in loop must be an Iterable, but got ${expressionValue?.runtimeType}');
    }

    if (iterableValue is Iterable) {
      // Check the unwrapped iterableValue
      final loopEnvironment = Environment(enclosing: environment);
      final previousEnvironment = environment;
      environment = loopEnvironment;

      try {
        String variableName;
        if (loopVariableOrIdentifier is DeclaredIdentifier) {
          variableName = loopVariableOrIdentifier.name.lexeme;
          environment.define(variableName, null); // Define before loop
        } else if (loopVariableOrIdentifier is SimpleIdentifier) {
          variableName = loopVariableOrIdentifier.name;
          try {
            environment.get(variableName); // Check existence
          } catch (e) {
            throw RuntimeError(
                "Variable '$variableName' for for-in loop is not defined.");
          }
        } else {
          throw StateError(
              'Unexpected for-in loop variable type: ${loopVariableOrIdentifier.runtimeType}');
        }

        // Iterate over the native list
        for (final element in iterableValue) {
          // Assign current element to the loop variable
          environment.assign(variableName, element);

          // Execute the body
          try {
            body.accept<Object?>(this);
          } on BreakException catch (e) {
            Logger.debug(
                "[ForIn] Caught BreakException (label: ${e.label}) with current labels: $_currentStatementLabels");
            if (e.label == null || _currentStatementLabels.contains(e.label)) {
              Logger.debug("[ForIn] Breaking loop.");
              break; // Exit the for-in loop
            } else {
              Logger.debug("[ForIn] Rethrowing outer break...");
              rethrow;
            }
          } on ContinueException catch (e) {
            Logger.debug(
                "[ForIn] Caught ContinueException (label: ${e.label}) with current labels: $_currentStatementLabels");
            if (e.label == null || _currentStatementLabels.contains(e.label)) {
              Logger.debug("[ForIn] Continuing loop.");
              continue; // Go to the next element
            } else {
              Logger.debug("[ForIn] Rethrowing outer continue...");
              rethrow;
            }
          }
        }
      } finally {
        // Restore previous environment
        environment = previousEnvironment;
      }
    } else {
      // Should not happen after the check above
      throw StateError(
          'Internal error: Expected Iterable but got ${iterableValue.runtimeType}');
    }
  }

  // Helper method to execute the logic of an await for-in loop (for streams)
  Object? _executeAwaitForIn(AstNode loopVariableOrIdentifier,
      Expression iterableExpression, Statement body) {
    final expressionValue = iterableExpression.accept<Object?>(this);

    // Handle stream being BridgedInstance<Stream>
    Object? streamValue;
    if (toBridgedInstance(expressionValue).$2) {
      final bridgedInstance = toBridgedInstance(expressionValue).$1!;
      if (bridgedInstance.nativeObject is Stream) {
        streamValue = bridgedInstance.nativeObject;
      } else {
        throw RuntimeError(
            'Value used in await for-in loop must be a Stream, but got BridgedInstance containing ${bridgedInstance.nativeObject.runtimeType}');
      }
    } else if (expressionValue is Stream) {
      streamValue = expressionValue;
    } else {
      throw RuntimeError(
          'Value used in await for-in loop must be a Stream, but got ${expressionValue?.runtimeType}');
    }

    if (streamValue is Stream) {
      // Create a suspension request for converting the stream to a list first
      if (currentAsyncState == null) {
        throw RuntimeError(
            "await for statement can only be used inside async functions");
      }

      // Convert the stream to a list first, then process it as a regular for-in loop
      return AsyncSuspensionRequest(
        _convertStreamAndProcessForIn(
            loopVariableOrIdentifier, streamValue, body),
        currentAsyncState!,
      );
    } else {
      // Should not happen after the check above
      throw StateError(
          'Internal error: Expected Stream but got ${streamValue.runtimeType}');
    }
  }

  // Convert stream to list and then process as regular for-in loop
  Future<Object?> _convertStreamAndProcessForIn(
      AstNode loopVariableOrIdentifier,
      Stream<Object?> stream,
      Statement body) async {
    // Convert stream to list
    final List<Object?> items = await stream.toList();

    // Now process as a regular for-in loop with the list
    _executeForInWithItems(loopVariableOrIdentifier, items, body);

    return null; // await for loops don't produce a value
  }

  // Execute for-in loop with a list of items (reused logic from _executeForIn)
  void _executeForInWithItems(
      AstNode loopVariableOrIdentifier, List<Object?> items, Statement body) {
    // Don't create a new environment - use the current one to preserve access to local variables
    String variableName;
    if (loopVariableOrIdentifier is DeclaredIdentifier) {
      variableName = loopVariableOrIdentifier.name.lexeme;
      // Define the loop variable in the current environment
      environment.define(variableName, null);
    } else if (loopVariableOrIdentifier is SimpleIdentifier) {
      variableName = loopVariableOrIdentifier.name;
      try {
        environment.get(variableName); // Check existence
      } catch (e) {
        throw RuntimeError(
            "Variable '$variableName' for for-in loop is not defined.");
      }
    } else {
      throw StateError(
          'Unexpected for-in loop variable type: ${loopVariableOrIdentifier.runtimeType}');
    }

    // Iterate over the items
    for (final element in items) {
      // Assign current element to the loop variable
      environment.assign(variableName, element);

      // Execute the body
      try {
        body.accept<Object?>(this);
      } on BreakException catch (e) {
        Logger.debug(
            "[AwaitForIn] Caught BreakException (label: ${e.label}) with current labels: $_currentStatementLabels");
        if (e.label == null || _currentStatementLabels.contains(e.label)) {
          Logger.debug("[AwaitForIn] Breaking loop.");
          break; // Exit the for-in loop
        } else {
          Logger.debug("[AwaitForIn] Rethrowing outer break...");
          rethrow;
        }
      } on ContinueException catch (e) {
        Logger.debug(
            "[AwaitForIn] Caught ContinueException (label: ${e.label}) with current labels: $_currentStatementLabels");
        if (e.label == null || _currentStatementLabels.contains(e.label)) {
          Logger.debug("[AwaitForIn] Continuing loop.");
          continue; // Go to the next element
        } else {
          Logger.debug("[AwaitForIn] Rethrowing outer continue...");
          rethrow;
        }
      }
    }
  }

  // Add handler for VariableDeclarationList used in ForPartsWithDeclarations
  @override
  Object? visitVariableDeclarationList(VariableDeclarationList node) {
    // We need to ensure variables are defined in the current environment.
    // visitVariableDeclaration is NOT automatically called for node.variables
    // by the generalizing visitor when visiting the list itself.
    for (final variable in node.variables) {
      if (variable.name.lexeme == '_') {
        // Evaluate initializer for potential side effects, but don't define
        variable.initializer?.accept<Object?>(this);
      } else {
        // Check if this is a late variable
        final isLate = node.lateKeyword != null;
        final isFinal = node.keyword?.lexeme == 'final';
        final variableName = variable.name.lexeme;

        if (isLate) {
          // Handle late variable
          if (variable.initializer != null) {
            // Late variable with lazy initializer
            final lateVar = LateVariable(variableName, () {
              // Create a closure that will evaluate the initializer when accessed
              return variable.initializer!.accept<Object?>(this);
            }, isFinal: isFinal);
            environment.define(variableName, lateVar);
            Logger.debug(
                "[VariableDeclList] Defined late variable '$variableName' with lazy initializer.");
          } else {
            // Late variable without initializer
            final lateVar = LateVariable(variableName, null, isFinal: isFinal);
            environment.define(variableName, lateVar);
            Logger.debug(
                "[VariableDeclList] Defined late variable '$variableName' without initializer.");
          }
        } else {
          // Regular (non-late) variable handling
          Object? initValue;
          Object? result; // Value returned by accept() (could be suspension)

          if (variable.initializer != null) {
            result = variable.initializer!.accept<Object?>(this);
            if (result is AsyncSuspensionRequest) {
              // Async initializer: Define as null for now, result holds suspension
              Logger.debug(
                  "[VariableDeclList] Async init for '$variableName'. Defined as null.");
              environment.define(variableName, null);
              // Propagate the suspension request.
              // If there are multiple async inits, the LAST suspension request wins.
            } else {
              // Sync initializer: Use the computed value
              initValue = result;
              Logger.debug(
                  "[VariableDeclList] Sync init for '$variableName'. Defined as $initValue.");
              environment.define(variableName, initValue);
            }
          } else {
            // No initializer: Define as null
            Logger.debug(
                "[VariableDeclList] No init for '$variableName'. Defined as null.");
            environment.define(variableName, null);
            result = null; // No suspension
          }

          // If the result of the variable's init was a suspension, we need to return it
          // to signal the state machine.
          if (result is AsyncSuspensionRequest) {
            // If any variable initialization caused suspension, return that suspension immediately.
            // The state machine needs to handle this before processing subsequent variables.
            Logger.debug(
                "[VariableDeclList] Propagating suspension from initializer of '$variableName'.");
            return result;
          }
        }
      }
    }
    // If no suspension occurred (or only sync initializers for all variables)
    return null; // Original behavior
  }

  @override
  Object? visitBreakStatement(BreakStatement node) {
    final label = node.label?.name;
    Logger.debug(
        "[BreakStatement] BREAKING: About to throw BreakException (label: $label). Current async state: ${currentAsyncState?.hashCode}");
    Logger.debug(
        "[BreakStatement] Stack trace for break: ${StackTrace.current}");
    throw BreakException(label);
  }

  @override
  Object? visitContinueStatement(ContinueStatement node) {
    final label = node.label?.name;
    Logger.debug(
        "[ContinueStatement] Throwing ContinueException (label: $label)");
    throw ContinueException(label);
  }

  @override
  Object? visitYieldStatement(YieldStatement node) {
    final value = node.expression.accept<Object?>(this);
    Logger.debug(
        "[YieldStatement] Yielding value: $value (star: ${node.star != null})");

    // If we're in an async* generator (with real async state), create a suspension
    if (currentAsyncState?.isGenerator == true) {
      final controller = currentAsyncState!.generatorStreamController!;

      if (node.star != null) {
        // yield* - handle asynchronously
        return AsyncSuspensionRequest(
            _handleYieldStarAsync(value, controller), currentAsyncState!,
            isYieldSuspension: true);
      } else {
        // regular yield - send to stream and create minimal suspension
        controller.add(value);
        // Create a completed future suspension to continue execution
        return AsyncSuspensionRequest(Future.value(null), currentAsyncState!,
            isYieldSuspension: true);
      }
    }

    // Fallback for sync* generators or other contexts
    return YieldValue(value, isYieldStar: node.star != null);
  }

  // Handle yield* in async generator context asynchronously
  Future<Object?> _handleYieldStarAsync(
      Object? value, StreamController<Object?> controller) async {
    if (value is Stream) {
      await for (final item in value) {
        controller.add(item);
      }
    } else if (value is Iterable) {
      for (final item in value) {
        controller.add(item);
      }
    } else {
      controller.addError(RuntimeError(
          "yield* expression must be a Stream or Iterable, got ${value.runtimeType}"));
    }
    return null;
  }

  @override
  Object? visitListLiteral(ListLiteral node) {
    final List<Object?> list = [];
    for (final element in node.elements) {
      _processCollectionElement(element, list, isMap: false);
    }

    // If this is a const list, return an unmodifiable version
    if (node.constKeyword != null) {
      return List.unmodifiable(list);
    }

    return list;
  }

  @override
  Object? visitParenthesizedExpression(ParenthesizedExpression node) {
    return node.expression.accept<Object?>(this);
  }

  @override
  Object? visitCascadeExpression(CascadeExpression node) {
    // 1. Evaluate the target expression ONCE.
    final targetValue = node.target.accept<Object?>(this);

    // 2. Execute each cascade section ON THE ORIGINAL targetValue.
    for (final section in node.cascadeSections) {
      // We need to manually handle each section type, forcing the target.
      if (section is MethodInvocation) {
        _executeCascadeMethodInvocation(targetValue, section);
      } else if (section is PropertyAccess) {
        // Evaluate property access for potential side effects (getters), but discard result.
        _executeCascadePropertyAccess(targetValue, section);
      } else if (section is AssignmentExpression) {
        _executeCascadeAssignment(targetValue, section);
      } else if (section is IndexExpression) {
        // Evaluate index expression for potential side effects (getters?), but discard result.
        _executeCascadeIndexAccess(targetValue, section);
      } else {
        // Should not happen with valid cascade sections
        throw UnimplementedError(
            'Cascade section type not handled: ${section.runtimeType}');
      }
    }

    // 3. The cascade expression evaluates to the original target value.
    return targetValue;
  }

  void _executeCascadeMethodInvocation(
      Object? targetValue, MethodInvocation node) {
    if (targetValue == null) {
      // Dart's .. operator throws on null, ?.. does nothing.
      // Since we can't easily distinguish here, we mimic ?.. and do nothing.
      Logger.debug(
          "[Cascade] Target is null, skipping method invocation section.");
      return;
    }

    final methodName = node.methodName.name;
    final (positionalArgs, namedArgs) = _evaluateArguments(node.argumentList);
    List<RuntimeType>? evaluatedTypeArguments;
    final typeArgsNode = node.typeArguments;
    if (typeArgsNode != null) {
      evaluatedTypeArguments = typeArgsNode.arguments
          .map((typeNode) => _resolveTypeAnnotation(typeNode))
          .toList();
    }

    // Resolve and call method ON targetValue
    if (targetValue is InterpretedInstance) {
      final callee = targetValue.get(methodName); // Gets bound method
      if (callee is Callable) {
        callee.call(this, positionalArgs, namedArgs, evaluatedTypeArguments);
      } else {
        throw RuntimeError(
            "Member '$methodName' on interpreted instance is not callable in cascade.");
      }
    } else if (toBridgedInstance(targetValue).$2) {
      final bridgedInstance = toBridgedInstance(targetValue).$1!;
      final adapter =
          bridgedInstance.bridgedClass.findInstanceMethodAdapter(methodName);
      if (adapter != null) {
        adapter(this, bridgedInstance.nativeObject, positionalArgs, namedArgs);
      } else {
        throw RuntimeError(
            "Bridged instance method '$methodName' not found in cascade.");
      }
    }
    // Ignore the return value of the method call in a cascade
  }

  Object? _executeCascadePropertyAccess(
      Object? targetValue, PropertyAccess node) {
    if (targetValue == null) {
      Logger.debug(
          "[Cascade] Target is null, skipping property access section.");
      return null;
    }

    final propertyName = node.propertyName.name;
    // Resolve property/getter ON targetValue
    if (targetValue is InterpretedInstance) {
      final member = targetValue.get(propertyName);
      if (member is InterpretedFunction && member.isGetter) {
        return member.call(this, [],
            {}); // Call getter, return its value (needed for assignment LHS)
      } else {
        return member; // Return field value (needed for assignment LHS)
      }
    } else if (toBridgedInstance(targetValue).$2) {
      final bridgedInstance = toBridgedInstance(targetValue).$1!;
      final getter =
          bridgedInstance.bridgedClass.findInstanceGetterAdapter(propertyName);
      if (getter != null) {
        return getter(this, bridgedInstance.nativeObject);
      }
      // If no getter, maybe it's a method to be used in assignment? Unlikely.
      throw RuntimeError(
          "Bridged instance property '$propertyName' (getter) not found in cascade.");
    } else {
      throw RuntimeError(
          "property '$propertyName' (getter) not found in cascade.");
    }
  }

  Object? _executeCascadeIndexAccess(
      Object? targetValue, IndexExpression node) {
    if (targetValue == null) {
      Logger.debug("[Cascade] Target is null, skipping index access section.");
      return null;
    }

    final indexValue = node.index.accept<Object?>(this);
    // Perform index access ON targetValue
    if (targetValue is List) {
      if (indexValue is int) {
        if (indexValue < 0 || indexValue >= targetValue.length) {
          throw RuntimeError('Index out of range in cascade: $indexValue');
        }
        return targetValue[indexValue];
      } else {
        throw RuntimeError('List index must be an integer in cascade.');
      }
    } else if (targetValue is Map) {
      return targetValue[indexValue];
    } else if (targetValue is String && indexValue is int) {
      return targetValue[indexValue];
    } else {
      throw RuntimeError(
          'Unsupported target for index access in cascade: ${targetValue.runtimeType}');
    }
    // Return the accessed value (needed for assignment LHS)
  }

  void _executeCascadeAssignment(
      Object? targetValue, AssignmentExpression node) {
    if (targetValue == null) {
      Logger.debug("[Cascade] Target is null, skipping assignment section.");
      return;
    }

    final rhsValue = node.rightHandSide.accept<Object?>(this);
    final operatorType = node.operator.type;
    final lhs = node.leftHandSide;

    if (lhs is SimpleIdentifier) {
      // Property assignment: targetValue.propertyName op= rhsValue
      final propertyName = lhs.name;
      Object? newValue;
      if (operatorType == TokenType.EQ) {
        newValue = rhsValue;
      } else {
        // Compound assignment
        Object? currentValue;
        // Need to get the current value from the target
        if (targetValue is InterpretedInstance) {
          currentValue = targetValue.get(propertyName);
        } else if (toBridgedInstance(targetValue).$2) {
          final bridgedInstance = toBridgedInstance(targetValue).$1!;
          final getter = bridgedInstance.bridgedClass
              .findInstanceGetterAdapter(propertyName);
          if (getter == null) {
            throw RuntimeError(
                "No getter '$propertyName' for compound assignment in cascade.");
          }
          currentValue = getter(this, bridgedInstance.nativeObject);
        } else {
          throw RuntimeError(
              "Cannot get property '$propertyName' for compound assignment on ${targetValue.runtimeType} in cascade.");
        }
        newValue = computeCompoundValue(currentValue, rhsValue, operatorType);
      }

      // Set the value on the target
      if (targetValue is InterpretedInstance) {
        final setter = targetValue.klass.findInstanceSetter(propertyName);
        if (setter != null) {
          setter.bind(targetValue).call(this, [newValue], {});
        } else {
          targetValue.set(propertyName, newValue, this); // Direct field set
        }
      } else if (toBridgedInstance(targetValue).$2) {
        final bridgedInstance = toBridgedInstance(targetValue).$1!;
        final setter = bridgedInstance.bridgedClass
            .findInstanceSetterAdapter(propertyName);
        if (setter == null) {
          throw RuntimeError(
              "No setter '$propertyName' for assignment in cascade.");
        }
        setter(this, bridgedInstance.nativeObject, newValue);
      } else {
        throw RuntimeError(
            "Cannot set property '$propertyName' on ${targetValue.runtimeType} in cascade.");
      }
    } else if (lhs is IndexExpression) {
      // Index assignment: targetValue[index] op= rhsValue
      final indexValue = lhs.index.accept<Object?>(this);
      Object? newValue;

      if (operatorType == TokenType.EQ) {
        newValue = rhsValue;
      } else {
        // Compound assignment
        Object? currentValue;
        if (targetValue is List) {
          if (indexValue is! int) throw RuntimeError('List index must be int.');
          if (indexValue < 0 || indexValue >= targetValue.length) {
            throw RuntimeError('Index out of range.');
          }
          currentValue = targetValue[indexValue];
        } else if (targetValue is Map) {
          currentValue = targetValue[indexValue];
        } else {
          throw RuntimeError(
              "Compound index assignment target must be List or Map in cascade.");
        }
        newValue = computeCompoundValue(currentValue, rhsValue, operatorType);
      }

      // Set the value
      if (targetValue is List) {
        if (indexValue is! int) throw RuntimeError('List index must be int.');
        if (indexValue < 0 || indexValue >= targetValue.length) {
          throw RuntimeError('Index out of range.');
        }
        targetValue[indexValue] = newValue;
      } else if (targetValue is Map) {
        targetValue[indexValue] = newValue;
      } else {
        // Should have been caught earlier
        throw RuntimeError(
            "Index assignment target must be List or Map in cascade.");
      }
    } else if (lhs is PropertyAccess) {
      // Cascade assignment like: target..property = value or target..property += value
      // Note: targetValue is the original cascade target, NOT lhs.target
      final propertyName = lhs.propertyName.name;
      Object? newValue;

      if (operatorType == TokenType.EQ) {
        newValue = rhsValue; // Simple assignment
      } else {
        // Compound assignment
        Object? currentValue;
        // 1. Get current value from targetValue using propertyName
        if (targetValue is InterpretedInstance) {
          currentValue = targetValue.get(propertyName); // Handles field/getter
        } else if (toBridgedInstance(targetValue).$2) {
          final bridgedInstance = toBridgedInstance(targetValue).$1!;
          final getter = bridgedInstance.bridgedClass
              .findInstanceGetterAdapter(propertyName);
          if (getter == null) {
            throw RuntimeError(
                "No getter '$propertyName' for compound assignment in cascade.");
          }
          currentValue = getter(this, bridgedInstance.nativeObject);
        } else {
          throw RuntimeError(
              "Cannot get property '$propertyName' for compound assignment on ${targetValue.runtimeType} in cascade.");
        }
        // 2. Compute new value
        newValue = computeCompoundValue(currentValue, rhsValue, operatorType);
      }

      // 3. Set the new value on targetValue using propertyName
      if (targetValue is InterpretedInstance) {
        final setter = targetValue.klass.findInstanceSetter(propertyName);
        if (setter != null) {
          setter.bind(targetValue).call(this, [newValue], {});
        } else {
          // Direct field assignment if no setter
          targetValue.set(propertyName, newValue, this);
        }
      } else if (toBridgedInstance(targetValue).$2) {
        final bridgedInstance = toBridgedInstance(targetValue).$1!;
        final setter = bridgedInstance.bridgedClass
            .findInstanceSetterAdapter(propertyName);
        if (setter == null) {
          throw RuntimeError(
              "No setter '$propertyName' for assignment in cascade.");
        }
        setter(this, bridgedInstance.nativeObject, newValue);
      } else {
        throw RuntimeError(
            "Cannot set property '$propertyName' on ${targetValue.runtimeType} in cascade.");
      }
    } else {
      throw UnimplementedError(
          'Unsupported assignment LHS in cascade: ${lhs.runtimeType}');
    }
    // Assignment in cascade doesn't produce a value to be used further.
  }

  void _processCollectionElement(CollectionElement element, Object collection,
      {required bool isMap}) {
    if (element is Expression) {
      final value = element.accept<Object?>(this);
      if (isMap) {
        throw RuntimeError(
            "Expected a MapLiteralEntry ('key: value') but got an expression in map literal.");
      } else if (collection is List) {
        collection.add(value);
      } else if (collection is Set) {
        collection.add(value);
      }
    } else if (element is MapLiteralEntry) {
      if (!isMap) {
        throw RuntimeError(
            "Unexpected MapLiteralEntry ('key: value') in a non-map literal.");
      }
      if (collection is Map) {
        final key = element.key.accept<Object?>(this);
        final value = element.value.accept<Object?>(this);
        collection[key] = value;
      } else {
        // Should not happen if isMap is true
        throw StateError("Internal error: Expected Map for map literal.");
      }
    } else if (element is SpreadElement) {
      final expressionValue = element.expression.accept<Object?>(this);
      if (element.isNullAware && expressionValue == null) {
        // Null-aware spread with null value, do nothing
        return;
      }
      if (isMap) {
        Map? mapToAdd;
        final bridgedInstance = toBridgedInstance(expressionValue);
        if (expressionValue is Map) {
          mapToAdd = expressionValue;
        } else if (bridgedInstance.$2 &&
            bridgedInstance.$1?.nativeObject is Map) {
          mapToAdd = bridgedInstance.$1!.nativeObject as Map;
        } else {
          throw RuntimeError(
              'Spread element in a Map literal requires a Map, but got ${expressionValue?.runtimeType}');
        }
        (collection as Map).addAll(mapToAdd);
      } else {
        // List or Set Spread Logic...
        Object? iterableToAdd;
        if (toBridgedInstance(expressionValue).$2) {
          final bridgedInstance = toBridgedInstance(expressionValue).$1!;
          if (bridgedInstance.nativeObject is Iterable) {
            iterableToAdd = bridgedInstance.nativeObject;
          } else {
            // BridgedInstance does not contain an Iterable
            throw RuntimeError(
                'Spread element in a ${collection is List ? 'List' : 'Set'} literal requires an Iterable, but got BridgedInstance containing ${bridgedInstance.nativeObject.runtimeType}');
          }
        } else if (expressionValue is Iterable) {
          // Original check: If not BridgedInstance, check if it's directly Iterable
          iterableToAdd = expressionValue;
        } else {
          // Neither BridgedInstance with Iterable nor direct Iterable
          throw RuntimeError(
              'Spread element in a ${collection is List ? 'List' : 'Set'} literal requires an Iterable, but got ${expressionValue?.runtimeType}');
        }

        // Now use iterableToAdd which is guaranteed to be Iterable
        // Should always be non-null if no error thrown
        if (collection is List) {
          collection.addAll(iterableToAdd as Iterable); // Cast is safe here
        } else if (collection is Set) {
          collection.addAll(iterableToAdd as Iterable); // Cast is safe here
        } else {
          throw StateError(
              "Internal error: Expected List or Set for non-map literal.");
        }
        // else case handled by error throws above
      }
    } else if (element is IfElement) {
      final conditionValue = element.expression.accept<Object?>(this);
      bool conditionResult;
      final bridgedInstance = toBridgedInstance(conditionValue);
      if (conditionValue is bool) {
        conditionResult = conditionValue;
      } else if (bridgedInstance.$2 &&
          bridgedInstance.$1?.nativeObject is bool) {
        conditionResult = bridgedInstance.$1!.nativeObject as bool;
      } else {
        throw RuntimeError(
            'Condition in collection \'if\' must be a boolean, but got ${conditionValue?.runtimeType}');
      }

      if (conditionResult) {
        _processCollectionElement(element.thenElement, collection,
            isMap: isMap);
      } else if (element.elseElement != null) {
        _processCollectionElement(element.elseElement!, collection,
            isMap: isMap);
      }
    } else if (element is ForElement) {
      final loopParts = element.forLoopParts;
      if (loopParts is ForEachPartsWithDeclaration ||
          loopParts is ForEachPartsWithIdentifier) {
        final iterableExpression = loopParts is ForEachPartsWithDeclaration
            ? loopParts.iterable
            : (loopParts as ForEachPartsWithIdentifier).iterable;
        final loopVariableNode = loopParts is ForEachPartsWithDeclaration
            ? loopParts.loopVariable
            : (loopParts as ForEachPartsWithIdentifier).identifier;

        final iterableValue = iterableExpression.accept<Object?>(this);

        if (iterableValue is Iterable) {
          final loopEnvironment = Environment(enclosing: environment);
          final previousEnvironment = environment;
          environment = loopEnvironment;

          try {
            String variableName;
            if (loopVariableNode is DeclaredIdentifier) {
              variableName = loopVariableNode.name.lexeme;
              environment.define(variableName, null); // Define before loop
            } else if (loopVariableNode is SimpleIdentifier) {
              variableName = loopVariableNode.name;
            } else {
              throw StateError(
                  'Unexpected for-in loop variable type: ${loopVariableNode.runtimeType}');
            }

            for (final item in iterableValue) {
              environment.assign(variableName, item);
              _processCollectionElement(element.body, collection, isMap: isMap);
            }
          } finally {
            environment = previousEnvironment;
          }
        } else {
          throw RuntimeError(
              'Value used in collection \'for-in\' must be an Iterable, but got ${iterableValue?.runtimeType}');
        }
      } else if (loopParts is ForPartsWithDeclarations ||
          loopParts is ForPartsWithExpression) {
        AstNode? initialization;
        Expression? condition;
        List<Expression>? updaters;
        if (loopParts is ForPartsWithDeclarations) {
          initialization = loopParts.variables;
          condition = loopParts.condition;
          updaters = loopParts.updaters;
        } else if (loopParts is ForPartsWithExpression) {
          initialization = loopParts.initialization;
          condition = loopParts.condition;
          updaters = loopParts.updaters;
        }
        final loopEnvironment = Environment(enclosing: environment);
        final previousEnvironment = environment;
        environment = loopEnvironment;
        try {
          // Initialisation
          if (initialization != null) {
            initialization.accept<Object?>(this);
          }
          // Boucle
          while (true) {
            bool conditionResult = true;
            if (condition != null) {
              final evalResult = condition.accept<Object?>(this);
              final bridgedInstance = toBridgedInstance(evalResult);
              if (evalResult is bool) {
                conditionResult = evalResult;
              } else if (bridgedInstance.$2 &&
                  bridgedInstance.$1?.nativeObject is bool) {
                conditionResult = bridgedInstance.$1!.nativeObject as bool;
              } else {
                throw RuntimeError(
                    "The condition of a 'for' loop must be a boolean, but was ${evalResult?.runtimeType}.");
              }
            }
            if (!conditionResult) break;
            _processCollectionElement(element.body, collection, isMap: isMap);
            if (updaters != null) {
              for (final updater in updaters) {
                updater.accept<Object?>(this);
              }
            }
          }
        } finally {
          environment = previousEnvironment;
        }
      } else {
        throw UnimplementedError(
            'Unsupported for-loop type in collection literal: ${loopParts.runtimeType}');
      }
    } else if (element is NullAwareElement) {
      // Use element.expression as per analyzer AST definition
      final value = element.value.accept<Object?>(this);
      if (value != null) {
        if (collection is List) {
          collection.add(value);
        } else if (collection is Set) {
          collection.add(value);
        } else {
          // Should not happen if isMap is false
          throw StateError(
              "Internal error: Expected List or Set for NullAwareElement.");
        }
      }
      // If value is null, do nothing.
    } else {
      throw UnimplementedError(
          'Collection element type not yet supported: ${element.runtimeType}');
    }
  }

  @override
  Object? visitFunctionDeclaration(FunctionDeclaration node) {
    // Create a function object that captures the current environment (closure)
    // Use the .declaration constructor
    final returnType = node.returnType;
    bool isAsync = node.functionExpression.body.isAsynchronous;
    bool isNullable = false;
    if (returnType is NamedType) {
      isNullable = returnType.toSource().contains('?');
    }

    // Handle type parameters for generic functions
    Environment? tempEnvironment;
    final typeParameters = node.functionExpression.typeParameters;

    if (typeParameters != null) {
      Logger.debug(
          "[InterpreterVisitor.visitFunctionDeclaration] Function '${node.name.lexeme}' has ${typeParameters.typeParameters.length} type parameters");

      // Create a temporary environment for type resolution
      tempEnvironment = Environment(enclosing: environment);

      // Create temporary type parameter placeholders
      for (final typeParam in typeParameters.typeParameters) {
        final paramName = typeParam.name.lexeme;

        // Create a simple TypeParameter placeholder in the temp environment
        final typeParamPlaceholder = TypeParameter(paramName);
        tempEnvironment.define(paramName, typeParamPlaceholder);

        Logger.debug(
            "[InterpreterVisitor.visitFunctionDeclaration]   Defined type parameter '$paramName' in temp environment");
      }
    }

    // Use the temp environment (if any) for type resolution, otherwise use the normal environment
    final resolveEnvironment = tempEnvironment ?? environment;

    final declaredReturnType = tempEnvironment != null
        ? _resolveTypeAnnotationWithEnvironment(
            node.returnType, resolveEnvironment,
            isAsync: isAsync)
        : _resolveTypeAnnotation(node.returnType, isAsync: isAsync);

    final function = InterpretedFunction.declaration(
        node, environment, declaredReturnType, isNullable);
    // Define the function in the current environment
    environment.define(node.name.lexeme, function);
    return null; // Declaration itself doesn't return a value
  }

  // Handle function expressions (anonymous functions)
  @override
  Object? visitFunctionExpression(FunctionExpression node) {
    // Create a function object capturing the current environment (closure)
    // Use the .expression constructor since it might be anonymous
    final function = InterpretedFunction.expression(node, environment);
    // Return the function object itself as the value of the expression
    return function;
  }

  @override
  Object? visitReturnStatement(ReturnStatement node) {
    AstNode? eDecl = node;
    while (eDecl != null) {
      if (eDecl is FunctionDeclaration) {
        break;
      }
      eDecl = eDecl.parent;
    }

    Object? returnValue;
    if (node.expression != null) {
      returnValue = node.expression!.accept<Object?>(this);
      if (returnValue is AsyncSuspensionRequest) {
        return returnValue;
      }
    } else {
      returnValue = null;
    }

    if (eDecl != null && eDecl is FunctionDeclaration) {
      bool isNullable = false;
      final functionName = eDecl.name.lexeme;
      RuntimeType? declaredType;
      RuntimeType? valueRuntimeType;

      try {
        final currentCallable = environment.get(functionName);

        if (currentCallable is InterpretedFunction) {
          declaredType = currentCallable.declaredReturnType;
          isNullable = currentCallable.isNullable;

          // Special handling for async* generators: return without value should be allowed
          if (currentCallable.isAsyncGenerator && returnValue == null) {
            throw ReturnException(returnValue); // Exit generator cleanly
          }
        }
        valueRuntimeType = environment.getRuntimeType(returnValue);

        String declaredTypeDetails = "N/A";
        if (declaredType != null) {
          declaredTypeDetails =
              "Name: ${declaredType.name}, Hash: ${declaredType.hashCode}";
          if (declaredType is BridgedClass) {
            declaredTypeDetails +=
                ", NativeType: ${declaredType.nativeType}, NativeHash: ${declaredType.nativeType.hashCode}";
          }
        }

        String valueRuntimeTypeDetails = "N/A";
        if (valueRuntimeType != null) {
          valueRuntimeTypeDetails =
              "Name: ${valueRuntimeType.name}, Hash: ${valueRuntimeType.hashCode}";
          if (valueRuntimeType is BridgedClass) {
            valueRuntimeTypeDetails +=
                ", NativeType: ${valueRuntimeType.nativeType}, NativeHash: ${valueRuntimeType.nativeType.hashCode}";
          }
        }

        Logger.debug("[visitReturnStatement] Function: '$functionName'");
        Logger.debug(
            "[visitReturnStatement]   Declared Type: $declaredTypeDetails");
        Logger.debug(
            "[visitReturnStatement]   Value Runtime Type: $valueRuntimeTypeDetails");
        Logger.debug(
            "[visitReturnStatement]   Return Value: $returnValue (Type: ${returnValue?.runtimeType})");
        Logger.debug(
            "[visitReturnStatement]   Is Declared Type Nullable: $isNullable");

        if (declaredType != null && valueRuntimeType != null) {
          Logger.debug(
              "[visitReturnStatement]   declaredType.isSubtypeOf(valueRuntimeType) = ${declaredType.isSubtypeOf(valueRuntimeType)}");
        }

        if (valueRuntimeType != null) {
          if (declaredType != null) {
            if (declaredType.name != "dynamic" &&
                !declaredType.isSubtypeOf(valueRuntimeType,
                    value: returnValue)) {
              bool showError = true;
              if (isNullable && returnValue == null) {
                showError = false;
              }
              if (declaredType.name == "void" && returnValue == null) {
                showError = false;
              }
              if (declaredType.name == "Object" && returnValue != null) {
                showError = false;
              }

              if (showError) {
                throw RuntimeError(
                    "A value of type '${valueRuntimeType.name}' can't be returned from the function '$functionName' because it has a return type of '${eDecl.returnType}'.");
              }
            }
          }
        }
      } catch (e) {
        // Log before rethrow for more context in case of unexpected error here
        Logger.error(
            "[visitReturnStatement] Error during type check for function '$functionName': $e");
        if (e is Error) {
          Logger.error("Stack trace: ${e.stackTrace}");
        }
        rethrow;
      }
    }

    // For non-suspended results, throw the exception to unwind the stack.
    throw ReturnException(returnValue);
  }

  @override
  Object? visitConditionalExpression(ConditionalExpression node) {
    final conditionValue = node.condition.accept<Object?>(this);
    bool conditionResult;
    final bridgedInstance = toBridgedInstance(conditionValue);
    if (conditionValue is bool) {
      conditionResult = conditionValue;
    } else if (bridgedInstance.$2 && bridgedInstance.$1?.nativeObject is bool) {
      conditionResult = bridgedInstance.$1!.nativeObject as bool;
    } else {
      throw RuntimeError(
          "The condition of a conditional expression must be a boolean, but was ${conditionValue?.runtimeType}.");
    }

    if (conditionResult) {
      return node.thenExpression.accept<Object?>(this);
    } else {
      return node.elseExpression.accept<Object?>(this);
    }
  }

  @override
  Object? visitPrefixExpression(PrefixExpression node) {
    final operatorType = node.operator.type;
    final operandNode = node.operand;
    final operandValue = operandNode.accept<Object?>(this);
    final bridgedInstance = toBridgedInstance(operandValue);
    final operand =
        bridgedInstance.$2 ? bridgedInstance.$1!.nativeObject : operandValue;

    switch (operatorType) {
      case TokenType.BANG: // Logical NOT
        // Use unwrapped operand for check
        if (operand is bool) {
          return !operand;
        } else {
          // Error uses original value type
          throw RuntimeError(
              "Operand for '!' must be a boolean, but was ${operandValue?.runtimeType}.");
        }

      case TokenType.MINUS: // Unary minus (negation)
        // Use unwrapped operand for check
        if (operand is num) {
          return -operand;
        } else if (operand is BigInt) {
          return -operand;
        } else if (operandValue is InterpretedInstance) {
          // Check for class operator - method
          final operatorMethod = operandValue.findOperator('-');
          if (operatorMethod != null) {
            Logger.debug(
                "[PrefixExpr] Found class operator '-' on ${operandValue.klass.name}. Calling...");
            try {
              return operatorMethod.bind(operandValue).call(this, [], {});
            } on ReturnException catch (e) {
              return e.value;
            } catch (e) {
              throw RuntimeError("Error executing class operator '-': $e");
            }
          }
          // No class operator found, try extensions
        }

        const operatorName = '-';
        try {
          final extensionOperator =
              environment.findExtensionMember(operandValue, operatorName);
          if (extensionOperator is InterpretedExtensionMethod &&
              extensionOperator.isOperator) {
            Logger.debug(
                "[PrefixExpr] Found extension operator '-' for type ${operandValue?.runtimeType}. Calling...");
            // Args: receiver (operandValue)
            try {
              return extensionOperator.call(this, [operandValue], {});
            } on ReturnException catch (e) {
              return e.value;
            } catch (e) {
              throw RuntimeError("Error executing extension operator '-': $e");
            }
          }
        } on RuntimeError catch (findError) {
          Logger.debug(
              "[PrefixExpr] Extension operator '-' not found for type ${operandValue?.runtimeType}. Error: ${findError.message}");
          // Fall through
        }
        // Error uses original value type if extension not found/failed
        throw RuntimeError(
            "Operand for unary '-' must be a number or have an operator defined, but was ${operandValue?.runtimeType}.");

      case TokenType.TILDE: // Bitwise NOT (~)
        if (operand is int) {
          return ~operand;
        } else if (operand is BigInt) {
          // BigInt does not have a standard unary ~ operator in Dart
          // We rely solely on extensions for BigInt bitwise NOT
        } else if (operandValue is InterpretedInstance) {
          // Check for class operator ~ method
          final operatorMethod = operandValue.findOperator('~');
          if (operatorMethod != null) {
            Logger.debug(
                "[PrefixExpr] Found class operator '~' on ${operandValue.klass.name}. Calling...");
            try {
              return operatorMethod.bind(operandValue).call(this, [], {});
            } on ReturnException catch (e) {
              return e.value;
            } catch (e) {
              throw RuntimeError("Error executing class operator '~': $e");
            }
          }
          // No class operator found, try extensions
        }

        // Try Extension Operator '~' (for non-int or BigInt)
        const operatorNameTilde = '~';
        try {
          final extensionOperator =
              environment.findExtensionMember(operandValue, operatorNameTilde);
          if (extensionOperator is InterpretedExtensionMethod &&
              extensionOperator.isOperator) {
            Logger.debug(
                "[PrefixExpr] Found extension operator '~' for type ${operandValue?.runtimeType}. Calling...");
            // Args: receiver (operandValue)
            try {
              return extensionOperator.call(this, [operandValue], {});
            } on ReturnException catch (e) {
              return e.value;
            } catch (e) {
              throw RuntimeError("Error executing extension operator '~': $e");
            }
          }
        } on RuntimeError catch (findError) {
          Logger.debug(
              "[PrefixExpr] Extension operator '~' not found for type ${operandValue?.runtimeType}. Error: ${findError.message}");
          // Fall through
        }
        // Error if neither standard nor extension worked
        throw RuntimeError(
            "Operand for unary '~' must be an int or have an operator defined, but was ${operandValue?.runtimeType}.");

      case TokenType.PLUS_PLUS: // Prefix increment (++x)
      case TokenType.MINUS_MINUS: // Prefix decrement (--x)
        // Re-evaluate and unwrap operand specifically for ++/--
        final operandValue = operandNode.accept<Object?>(this);
        final bridgedInstance = toBridgedInstance(operandValue);
        final assignOperand = bridgedInstance.$2
            ? bridgedInstance.$1!.nativeObject
            : operandValue;

        // Check if AST node is assignable (SimpleIdentifier or PropertyAccess for now)
        if (operandNode is SimpleIdentifier) {
          final variableName = operandNode.name;
          // We need the current value (already got it as assignOperand)
          final currentValue = assignOperand;

          if (currentValue is num) {
            final newValue = operatorType == TokenType.PLUS_PLUS
                ? currentValue + 1
                : currentValue - 1;
            // Assign the new value back to the variable
            environment.assign(variableName, newValue);
            // Return the *new* value
            return newValue;
          } else if (operandValue is InterpretedInstance) {
            // Use custom + operator with literal 1
            final operatorMethod = operandValue.findOperator('+');
            if (operatorMethod != null) {
              try {
                // For ++x, we create appropriate operand and call x + operand
                final operand = _createIncrementOperand(
                    currentValue, operatorType == TokenType.PLUS_PLUS);
                // Note: For --, we could either call x + (-1) or x - 1
                // Let's use + with -1 for consistency
                final newValue =
                    operatorMethod.bind(operandValue).call(this, [operand], {});
                // Assign the new value back to the variable
                environment.assign(variableName, newValue);
                // Return the *new* value
                return newValue;
              } on ReturnException catch (e) {
                final newValue = e.value;
                // Assign the new value back to the variable
                environment.assign(variableName, newValue);
                // Return the *new* value
                return newValue;
              } catch (e) {
                throw RuntimeError(
                    "Error executing custom operator '+' for prefix '${operatorType == TokenType.PLUS_PLUS ? '++' : '--'}': $e");
              }
            } else {
              throw RuntimeError(
                  "Cannot increment/decrement object of type '${operandValue.klass.name}': No operator '+' found.");
            }
          } else {
            // Requires finding operator +/-, then assigning back.
            // Complex, skip for now.
            // Error uses original value type
            throw RuntimeError(
                "Operand for prefix '${operatorType == TokenType.PLUS_PLUS ? '++' : '--'}' must be a number, but was ${operandValue?.runtimeType}. Extension support TBD.");
          }
        } else if (operandNode is PropertyAccess) {
          // Handle property access like obj.field++
          final targetValue = operandNode.target?.accept<Object?>(this);
          final propertyName = operandNode.propertyName.name;

          if (targetValue is InterpretedInstance) {
            // Get current value via getter or field
            final currentValue = targetValue.get(propertyName);

            // Calculate new value
            Object? newValue;
            if (currentValue is num) {
              newValue = operatorType == TokenType.PLUS_PLUS
                  ? currentValue + 1
                  : currentValue - 1;
            } else if (currentValue is InterpretedInstance) {
              // Use custom + operator with literal 1
              final operatorMethod = currentValue.findOperator('+');
              if (operatorMethod != null) {
                try {
                  // For ++x, we create a literal 1 and call x + 1
                  operatorType == TokenType.PLUS_PLUS ? 1 : -1;
                  // Note: For --, we could either call x + (-1) or x - 1
                  // Let's use + with -1 for consistency
                  newValue = operatorMethod
                      .bind(currentValue)
                      .call(this, [operand], {});
                } on ReturnException catch (e) {
                  newValue = e.value;
                } catch (e) {
                  throw RuntimeError(
                      "Error executing custom operator '+' for prefix '${operatorType == TokenType.PLUS_PLUS ? '++' : '--'}': $e");
                }
              } else {
                throw RuntimeError(
                    "Cannot increment/decrement object of type '${currentValue.klass.name}': No operator '+' found.");
              }
            } else {
              throw RuntimeError(
                  "Cannot increment/decrement property '$propertyName' of type '${currentValue?.runtimeType}': Expected number or object with '+' operator.");
            }

            // Set new value via setter or field
            final setter = targetValue.klass.findInstanceSetter(propertyName);
            if (setter != null) {
              setter.bind(targetValue).call(this, [newValue], {});
            } else {
              targetValue.set(propertyName, newValue, this);
            }

            // Return the *new* value for prefix operators
            return newValue;
          } else {
            throw RuntimeError(
                "Cannot increment/decrement property on non-instance object of type '${targetValue?.runtimeType}'.");
          }
        } else if (operandNode is PrefixedIdentifier) {
          // Handle prefixed identifier like obj.field++ (parsed as PrefixedIdentifier)
          final targetValue = operandNode.prefix.accept<Object?>(this);
          final propertyName = operandNode.identifier.name;

          if (targetValue is InterpretedInstance) {
            // Get current value via getter or field
            final currentValue = targetValue.get(propertyName);

            // Calculate new value
            Object? newValue;
            if (currentValue is num) {
              newValue = operatorType == TokenType.PLUS_PLUS
                  ? currentValue + 1
                  : currentValue - 1;
            } else if (currentValue is InterpretedInstance) {
              // Use custom + operator with literal 1
              final operatorMethod = currentValue.findOperator('+');
              if (operatorMethod != null) {
                try {
                  // For ++x, we create a literal 1 and call x + 1
                  operatorType == TokenType.PLUS_PLUS ? 1 : -1;
                  // Note: For --, we could either call x + (-1) or x - 1
                  // Let's use + with -1 for consistency
                  newValue = operatorMethod
                      .bind(currentValue)
                      .call(this, [operand], {});
                } on ReturnException catch (e) {
                  newValue = e.value;
                } catch (e) {
                  throw RuntimeError(
                      "Error executing custom operator '+' for prefix '${operatorType == TokenType.PLUS_PLUS ? '++' : '--'}': $e");
                }
              } else {
                throw RuntimeError(
                    "Cannot increment/decrement object of type '${currentValue.klass.name}': No operator '+' found.");
              }
            } else {
              throw RuntimeError(
                  "Cannot increment/decrement property '$propertyName' of type '${currentValue?.runtimeType}': Expected number or object with '+' operator.");
            }

            // Set new value via setter or field
            final setter = targetValue.klass.findInstanceSetter(propertyName);
            if (setter != null) {
              setter.bind(targetValue).call(this, [newValue], {});
            } else {
              targetValue.set(propertyName, newValue, this);
            }

            // Return the *new* value for prefix operators
            return newValue;
          } else if (targetValue is InterpretedExtension) {
            // Handle static field/getter increment/decrement on extension (prefix)
            final extension = targetValue;

            // Get current value via static getter or field
            Object? currentValue;
            final staticGetter = extension.findStaticGetter(propertyName);
            if (staticGetter != null) {
              currentValue = staticGetter.call(this, [], {});
            } else if (extension.staticFields.containsKey(propertyName)) {
              currentValue = extension.getStaticField(propertyName);
            } else {
              throw RuntimeError(
                  "Extension '${extension.name}' has no static field or getter named '$propertyName'.");
            }

            // Calculate new value
            Object? newValue;
            if (currentValue is num) {
              newValue = operatorType == TokenType.PLUS_PLUS
                  ? currentValue + 1
                  : currentValue - 1;
            } else {
              throw RuntimeError(
                  "Cannot increment/decrement static property '$propertyName' of type '${currentValue?.runtimeType}': Expected number.");
            }

            // Set new value via static setter or field
            final staticSetter = extension.findStaticSetter(propertyName);
            if (staticSetter != null) {
              staticSetter.call(this, [newValue], {});
            } else if (extension.staticFields.containsKey(propertyName)) {
              extension.setStaticField(propertyName, newValue);
            } else {
              throw RuntimeError(
                  "Extension '${extension.name}' has no static setter or field named '$propertyName'.");
            }

            // Return the *new* value for prefix operators
            return newValue;
          } else {
            throw RuntimeError(
                "Cannot increment/decrement property on non-instance object of type '${targetValue?.runtimeType}'.");
          }
        } else if (operandNode is IndexExpression) {
          // Handle index access like ++array[i]
          final targetValue = operandNode.target?.accept<Object?>(this);
          final indexValue = operandNode.index.accept<Object?>(this);

          // Get current value via [] operator or direct access
          Object? currentValue;
          if (targetValue is List) {
            final index = indexValue as int;
            currentValue = targetValue[index];
          } else if (targetValue is Map) {
            currentValue = targetValue[indexValue];
          } else if (targetValue is InterpretedInstance) {
            // Use class operator [] if available
            final operatorMethod = targetValue.findOperator('[]');
            if (operatorMethod != null) {
              try {
                currentValue = operatorMethod
                    .bind(targetValue)
                    .call(this, [indexValue], {});
              } on ReturnException catch (e) {
                currentValue = e.value;
              } catch (e) {
                throw RuntimeError(
                    "Error executing class operator '[]' for prefix '${operatorType == TokenType.PLUS_PLUS ? '++' : '--'}': $e");
              }
            } else {
              throw RuntimeError(
                  "Cannot read index for prefix increment/decrement on ${targetValue.klass.name}: No operator '[]' found.");
            }
          } else {
            throw RuntimeError(
                "Cannot apply prefix '${operatorType == TokenType.PLUS_PLUS ? '++' : '--'}' to index of type '${targetValue?.runtimeType}'.");
          }

          // Calculate new value
          Object? newValue;
          if (currentValue is num) {
            newValue = operatorType == TokenType.PLUS_PLUS
                ? currentValue + 1
                : currentValue - 1;
          } else if (currentValue is InterpretedInstance) {
            // Use custom + operator with literal 1
            final operatorMethod = currentValue.findOperator('+');
            if (operatorMethod != null) {
              try {
                final operand = _createIncrementOperand(
                    currentValue, operatorType == TokenType.PLUS_PLUS);
                newValue =
                    operatorMethod.bind(currentValue).call(this, [operand], {});
              } on ReturnException catch (e) {
                newValue = e.value;
              } catch (e) {
                throw RuntimeError(
                    "Error executing custom operator '+' for prefix '${operatorType == TokenType.PLUS_PLUS ? '++' : '--'}': $e");
              }
            } else {
              throw RuntimeError(
                  "Cannot increment/decrement object at index of type '${currentValue.klass.name}': No operator '+' found.");
            }
          } else {
            throw RuntimeError(
                "Cannot increment/decrement value at index of type '${currentValue?.runtimeType}': Expected number or object with '+' operator.");
          }

          // Set new value via []= operator or direct access
          if (targetValue is List) {
            final index = indexValue as int;
            targetValue[index] = newValue;
          } else if (targetValue is Map) {
            targetValue[indexValue] = newValue;
          } else if (targetValue is InterpretedInstance) {
            // Use class operator []= if available
            final operatorMethod = targetValue.findOperator('[]=');
            if (operatorMethod != null) {
              try {
                operatorMethod
                    .bind(targetValue)
                    .call(this, [indexValue, newValue], {});
              } on ReturnException catch (_) {
                // []= should not return a value, but assignment expression returns assigned value
              } catch (e) {
                throw RuntimeError(
                    "Error executing class operator '[]=' for prefix '${operatorType == TokenType.PLUS_PLUS ? '++' : '--'}': $e");
              }
            } else {
              throw RuntimeError(
                  "Cannot write index for prefix increment/decrement on ${targetValue.klass.name}: No operator '[]=' found.");
            }
          }

          // Return the *new* value for prefix operators
          return newValue;
        } else {
          Logger.debug("Operand type: ${operandNode.runtimeType}");
          throw RuntimeError(
              "Operand for prefix '${operatorType == TokenType.PLUS_PLUS ? '++' : '--'}' must be an assignable variable, property, or index.");
        }
      default:
        // Check for class operators first for any other unary operators
        final String operatorLexeme = node.operator.lexeme;
        if (operandValue is InterpretedInstance) {
          final operatorMethod = operandValue.findOperator(operatorLexeme);
          if (operatorMethod != null) {
            Logger.debug(
                "[PrefixExpr] Found class operator '$operatorLexeme' on ${operandValue.klass.name}. Calling...");
            try {
              return operatorMethod.bind(operandValue).call(this, [], {});
            } on ReturnException catch (e) {
              return e.value;
            } catch (e) {
              throw RuntimeError(
                  "Error executing class operator '$operatorLexeme': $e");
            }
          }
        }

        // Check for extension operators if no class operator found
        try {
          final extensionOperator =
              environment.findExtensionMember(operandValue, operatorLexeme);
          if (extensionOperator is InterpretedExtensionMethod &&
              extensionOperator.isOperator) {
            Logger.debug(
                "[PrefixExpr] Found generic extension operator '$operatorLexeme' for type ${operandValue?.runtimeType}. Calling...");
            try {
              return extensionOperator.call(this, [operandValue], {});
            } on ReturnException catch (e) {
              return e.value;
            } catch (e) {
              throw RuntimeError(
                  "Error executing extension operator '$operatorLexeme': $e");
            }
          }
        } on RuntimeError {
          // Fall through if no generic extension op found
        }
        throw UnimplementedError(
            'Unary prefix operator not handled: ${node.operator.lexeme} ($operatorType)');
    }
  }

  @override
  Object? visitPostfixExpression(PostfixExpression node) {
    final operatorType = node.operator.type;

    // Support for the non-null assertion operator (!)
    if (operatorType == TokenType.BANG) {
      final operandValue = node.operand.accept<Object?>(this);
      if (operandValue == null) {
        throw RuntimeError(
            "Null check operator used on a null value at ${node.toString()}");
      }
      return operandValue;
    }

    // Check if operand is assignable (SimpleIdentifier or PropertyAccess)
    if (node.operand is SimpleIdentifier) {
      final variableName = (node.operand as SimpleIdentifier).name;
      Object? operandValue;
      InterpretedInstance? thisInstance;
      bool isInstanceField = false;

      // Try lexical scope first, then implicit 'this'
      try {
        operandValue = environment.get(variableName); // Try lexical scope
      } on RuntimeError {
        // Not found lexically, try implicit 'this'
        try {
          final potentialThis = environment.get('this');
          if (potentialThis is InterpretedInstance) {
            thisInstance = potentialThis;
            operandValue = thisInstance.get(variableName); // Get from instance
            isInstanceField = true;
          } else {
            throw RuntimeError("Undefined variable: $variableName");
          }
        } on RuntimeError {
          throw RuntimeError("Undefined variable: $variableName");
        }
      }
      final bridgedInstance = toBridgedInstance(operandValue);
      final currentValue =
          bridgedInstance.$2 ? bridgedInstance.$1!.nativeObject : operandValue;

      if (currentValue is num) {
        final newValue = operatorType == TokenType.PLUS_PLUS
            ? currentValue + 1
            : currentValue - 1;

        // Assign back to correct target (lexical or instance)
        if (isInstanceField && thisInstance != null) {
          final setter = thisInstance.klass.findInstanceSetter(variableName);
          if (setter != null) {
            setter.bind(thisInstance).call(this, [newValue], {});
          } else {
            thisInstance.set(
                variableName, newValue, this); // Assign to instance field
          }
        } else {
          environment.assign(
              variableName, newValue); // Assign to lexical variable
        }

        return operandValue; // Return the original value
      } else if (operandValue is InterpretedInstance) {
        // Use custom + operator with literal 1
        final operatorMethod = operandValue.findOperator('+');
        if (operatorMethod != null) {
          try {
            // For x++, we create a literal 1 and call x + 1
            final operand = _createIncrementOperand(
                currentValue, operatorType == TokenType.PLUS_PLUS);
            Object? newValue =
                operatorMethod.bind(operandValue).call(this, [operand], {});

            // Assign back to correct target (lexical or instance)
            if (isInstanceField && thisInstance != null) {
              final setter =
                  thisInstance.klass.findInstanceSetter(variableName);
              if (setter != null) {
                setter.bind(thisInstance).call(this, [newValue], {});
              } else {
                thisInstance.set(
                    variableName, newValue, this); // Assign to instance field
              }
            } else {
              environment.assign(
                  variableName, newValue); // Assign to lexical variable
            }

            return operandValue; // Return the original value for postfix
          } on ReturnException catch (e) {
            final newValue = e.value;

            // Assign back to correct target (lexical or instance)
            if (isInstanceField && thisInstance != null) {
              final setter =
                  thisInstance.klass.findInstanceSetter(variableName);
              if (setter != null) {
                setter.bind(thisInstance).call(this, [newValue], {});
              } else {
                thisInstance.set(
                    variableName, newValue, this); // Assign to instance field
              }
            } else {
              environment.assign(
                  variableName, newValue); // Assign to lexical variable
            }

            return operandValue; // Return the original value for postfix
          } catch (e) {
            throw RuntimeError(
                "Error executing custom operator '+' for postfix '${operatorType == TokenType.PLUS_PLUS ? '++' : '--'}': $e");
          }
        } else {
          throw RuntimeError(
              "Cannot increment/decrement object of type '${operandValue.klass.name}': No operator '+' found.");
        }
      } else {
        throw RuntimeError(
            "Operand for postfix '${operatorType == TokenType.PLUS_PLUS ? '++' : '--'}' must be a number, but was ${operandValue?.runtimeType}.");
      }
    } else if (node.operand is PropertyAccess) {
      // Handle property access like obj.field++
      final propertyAccess = node.operand as PropertyAccess;
      final targetValue = propertyAccess.target?.accept<Object?>(this);
      final propertyName = propertyAccess.propertyName.name;

      if (targetValue is InterpretedInstance) {
        // Get current value via getter or field
        final currentValue = targetValue.get(propertyName);
        final originalValue = currentValue; // Save for return

        // Calculate new value
        Object? newValue;
        if (currentValue is num) {
          newValue = operatorType == TokenType.PLUS_PLUS
              ? currentValue + 1
              : currentValue - 1;
        } else if (currentValue is InterpretedInstance) {
          // Use custom + operator with literal 1
          final operatorMethod = currentValue.findOperator('+');
          if (operatorMethod != null) {
            try {
              // For x++, we create a literal 1 and call x + 1
              final operand = _createIncrementOperand(
                  currentValue, operatorType == TokenType.PLUS_PLUS);
              newValue =
                  operatorMethod.bind(currentValue).call(this, [operand], {});
            } on ReturnException catch (e) {
              newValue = e.value;
            } catch (e) {
              throw RuntimeError(
                  "Error executing custom operator '+' for postfix '${operatorType == TokenType.PLUS_PLUS ? '++' : '--'}': $e");
            }
          } else {
            throw RuntimeError(
                "Cannot increment/decrement object of type '${currentValue.klass.name}': No operator '+' found.");
          }
        } else {
          throw RuntimeError(
              "Cannot increment/decrement property '$propertyName' of type '${currentValue?.runtimeType}': Expected number or object with '+' operator.");
        }

        // Set new value via setter or field
        final setter = targetValue.klass.findInstanceSetter(propertyName);
        if (setter != null) {
          setter.bind(targetValue).call(this, [newValue], {});
        } else {
          targetValue.set(propertyName, newValue, this);
        }

        // Return the *original* value for postfix operators
        return originalValue;
      } else {
        throw RuntimeError(
            "Cannot increment/decrement property on non-instance object of type '${targetValue?.runtimeType}'.");
      }
    } else if (node.operand is PrefixedIdentifier) {
      // Handle prefixed identifier like obj.field++ (parsed as PrefixedIdentifier)
      final prefixedIdentifier = node.operand as PrefixedIdentifier;
      final targetValue = prefixedIdentifier.prefix.accept<Object?>(this);
      final propertyName = prefixedIdentifier.identifier.name;

      if (targetValue is InterpretedInstance) {
        // Get current value via getter or field
        final currentValue = targetValue.get(propertyName);
        final originalValue = currentValue; // Save for return

        // Calculate new value
        Object? newValue;
        if (currentValue is num) {
          newValue = operatorType == TokenType.PLUS_PLUS
              ? currentValue + 1
              : currentValue - 1;
        } else if (currentValue is InterpretedInstance) {
          // Use custom + operator with literal 1
          final operatorMethod = currentValue.findOperator('+');
          if (operatorMethod != null) {
            try {
              // For x++, we create a literal 1 and call x + 1
              final operand = _createIncrementOperand(
                  currentValue, operatorType == TokenType.PLUS_PLUS);
              newValue =
                  operatorMethod.bind(currentValue).call(this, [operand], {});
            } on ReturnException catch (e) {
              newValue = e.value;
            } catch (e) {
              throw RuntimeError(
                  "Error executing custom operator '+' for postfix '${operatorType == TokenType.PLUS_PLUS ? '++' : '--'}': $e");
            }
          } else {
            throw RuntimeError(
                "Cannot increment/decrement object of type '${currentValue.klass.name}': No operator '+' found.");
          }
        } else {
          throw RuntimeError(
              "Cannot increment/decrement property '$propertyName' of type '${currentValue?.runtimeType}': Expected number or object with '+' operator.");
        }

        // Set new value via setter or field
        final setter = targetValue.klass.findInstanceSetter(propertyName);
        if (setter != null) {
          setter.bind(targetValue).call(this, [newValue], {});
        } else {
          targetValue.set(propertyName, newValue, this);
        }

        // Return the *original* value for postfix operators
        return originalValue;
      } else if (targetValue is InterpretedExtension) {
        // Handle static field/getter increment/decrement on extension
        final extension = targetValue;

        // Get current value via static getter or field
        Object? currentValue;
        final staticGetter = extension.findStaticGetter(propertyName);
        if (staticGetter != null) {
          currentValue = staticGetter.call(this, [], {});
        } else if (extension.staticFields.containsKey(propertyName)) {
          currentValue = extension.getStaticField(propertyName);
        } else {
          throw RuntimeError(
              "Extension '${extension.name}' has no static field or getter named '$propertyName'.");
        }

        final originalValue = currentValue; // Save for return

        // Calculate new value
        Object? newValue;
        if (currentValue is num) {
          newValue = operatorType == TokenType.PLUS_PLUS
              ? currentValue + 1
              : currentValue - 1;
        } else {
          throw RuntimeError(
              "Cannot increment/decrement static property '$propertyName' of type '${currentValue?.runtimeType}': Expected number.");
        }

        // Set new value via static setter or field
        final staticSetter = extension.findStaticSetter(propertyName);
        if (staticSetter != null) {
          staticSetter.call(this, [newValue], {});
        } else if (extension.staticFields.containsKey(propertyName)) {
          extension.setStaticField(propertyName, newValue);
        } else {
          throw RuntimeError(
              "Extension '${extension.name}' has no static setter or field named '$propertyName'.");
        }

        // Return the *original* value for postfix operators
        return originalValue;
      } else {
        throw RuntimeError(
            "Cannot increment/decrement property on non-instance object of type '${targetValue?.runtimeType}'.");
      }
    } else if (node.operand is IndexExpression) {
      // Handle index access like array[i]++
      final indexExpression = node.operand as IndexExpression;
      final targetValue = indexExpression.target?.accept<Object?>(this);
      final indexValue = indexExpression.index.accept<Object?>(this);

      // Get current value via [] operator or direct access
      Object? currentValue;
      if (targetValue is List) {
        final index = indexValue as int;
        currentValue = targetValue[index];
      } else if (targetValue is Map) {
        currentValue = targetValue[indexValue];
      } else if (targetValue is InterpretedInstance) {
        // Use class operator [] if available
        final operatorMethod = targetValue.findOperator('[]');
        if (operatorMethod != null) {
          try {
            currentValue =
                operatorMethod.bind(targetValue).call(this, [indexValue], {});
          } on ReturnException catch (e) {
            currentValue = e.value;
          } catch (e) {
            throw RuntimeError(
                "Error executing class operator '[]' for postfix '${operatorType == TokenType.PLUS_PLUS ? '++' : '--'}': $e");
          }
        } else {
          throw RuntimeError(
              "Cannot read index for postfix increment/decrement on ${targetValue.klass.name}: No operator '[]' found.");
        }
      } else {
        throw RuntimeError(
            "Cannot apply postfix '${operatorType == TokenType.PLUS_PLUS ? '++' : '--'}' to index of type '${targetValue?.runtimeType}'.");
      }

      final originalValue = currentValue; // Save for return

      // Calculate new value
      Object? newValue;
      if (currentValue is num) {
        newValue = operatorType == TokenType.PLUS_PLUS
            ? currentValue + 1
            : currentValue - 1;
      } else if (currentValue is InterpretedInstance) {
        // Use custom + operator with literal 1
        final operatorMethod = currentValue.findOperator('+');
        if (operatorMethod != null) {
          try {
            final operand = _createIncrementOperand(
                currentValue, operatorType == TokenType.PLUS_PLUS);
            newValue =
                operatorMethod.bind(currentValue).call(this, [operand], {});
          } on ReturnException catch (e) {
            newValue = e.value;
          } catch (e) {
            throw RuntimeError(
                "Error executing custom operator '+' for postfix '${operatorType == TokenType.PLUS_PLUS ? '++' : '--'}': $e");
          }
        } else {
          throw RuntimeError(
              "Cannot increment/decrement object at index of type '${currentValue.klass.name}': No operator '+' found.");
        }
      } else {
        throw RuntimeError(
            "Cannot increment/decrement value at index of type '${currentValue?.runtimeType}': Expected number or object with '+' operator.");
      }

      // Set new value via []= operator or direct access
      if (targetValue is List) {
        final index = indexValue as int;
        targetValue[index] = newValue;
      } else if (targetValue is Map) {
        targetValue[indexValue] = newValue;
      } else if (targetValue is InterpretedInstance) {
        // Use class operator []= if available
        final operatorMethod = targetValue.findOperator('[]=');
        if (operatorMethod != null) {
          try {
            operatorMethod
                .bind(targetValue)
                .call(this, [indexValue, newValue], {});
          } on ReturnException catch (_) {
            // []= should not return a value, but assignment expression returns assigned value
          } catch (e) {
            throw RuntimeError(
                "Error executing class operator '[]=' for postfix '${operatorType == TokenType.PLUS_PLUS ? '++' : '--'}': $e");
          }
        } else {
          throw RuntimeError(
              "Cannot write index for postfix increment/decrement on ${targetValue.klass.name}: No operator '[]=' found.");
        }
      }

      // Return the *original* value for postfix operators
      return originalValue;
    } else {
      throw RuntimeError(
          "Operand for postfix '${operatorType == TokenType.PLUS_PLUS ? '++' : '--'}' must be an assignable variable or property.");
    }
  }

  // Handle String Interpolation: "Value is ${expr}"
  @override
  Object? visitStringInterpolation(StringInterpolation node) {
    final buffer = StringBuffer();
    for (final element in node.elements) {
      if (element is InterpolationString) {
        buffer.write(element.value);
      } else if (element is InterpolationExpression) {
        final value = element.expression.accept<Object?>(this);
        buffer.write(stringify(value)); // Use stringify helper
      } else {
        // Should not happen based on AST structure
        throw StateError(
            'Unknown interpolation element: ${element.runtimeType}');
      }
    }
    return buffer.toString();
  }

  @override
  Object? visitSuperExpression(SuperExpression node) {
    if (currentFunction == null || currentFunction?.ownerType == null) {
      // Use ownerType
      throw RuntimeError("'super' can only be used within an instance method.");
    }
    final ownerType = currentFunction!.ownerType!; // Use ownerType
    // Need to ensure ownerType is actually a class for super access
    if (ownerType is! InterpretedClass) {
      throw RuntimeError(
          "'super' used outside of a class context (found ${ownerType.runtimeType}).");
    }
    final definingClass =
        ownerType; // Can safely use ownerType as InterpretedClass now

    InterpretedClass? standardSuperclass = definingClass.superclass;
    BridgedClass? bridgedSuperclass = definingClass.bridgedSuperclass;

    if (standardSuperclass == null && bridgedSuperclass == null) {
      throw RuntimeError(
          "Class '${definingClass.name}' does not have a standard or bridged superclass, cannot use 'super'.");
    }

    // Get the current 'this' instance
    try {
      final thisInstance = environment.get('this');
      if (thisInstance is InterpretedInstance) {
        // Pass the correct superclass type to BoundSuper
        if (standardSuperclass != null) {
          return BoundSuper(thisInstance, standardSuperclass);
        } else {
          // bridgedSuperclass cannot be null here due to the check above
          return BoundBridgedSuper(thisInstance, bridgedSuperclass!);
        }
      } else {
        // Should not happen if currentFunction is set correctly
        throw RuntimeError("Cannot find 'this' instance when using 'super'.");
      }
    } on RuntimeError {
      throw RuntimeError("Cannot find 'this' instance when using 'super'.");
    }
  }

  @override
  Object? visitLabeledStatement(LabeledStatement node) {
    final labelNames = node.labels.map((l) => l.label.name).toSet();
    final oldLabels = _currentStatementLabels;
    _currentStatementLabels = labelNames;
    Logger.debug("[LabeledStatement] Entering with labels: $labelNames");

    try {
      return node.statement.accept<Object?>(this);
    } on BreakException catch (e) {
      Logger.debug(
          "[LabeledStatement] Caught BreakException (label: ${e.label}) with current labels: $_currentStatementLabels");
      if (e.label != null && _currentStatementLabels.contains(e.label)) {
        // This break was targeting this labeled statement.
        Logger.debug(
            "[LabeledStatement] Consuming labeled break: '${e.label}'.");
        return null; // Effectively breaks out of the labeled statement.
      } else {
        // Unlabeled break or break for an outer label, rethrow.
        Logger.debug("[LabeledStatement] Rethrowing break...");
        rethrow;
      }
    }
    // ContinueException with a label matching this statement is an error
    // (you can only continue loops/switch members), so we don't catch it here.
    // It should be caught by the loop/switch or propagate further up.
    finally {
      Logger.debug("[LabeledStatement] Exiting labels: $labelNames");
      _currentStatementLabels = oldLabels;
    }
  }

  @override
  Object? visitClassDeclaration(ClassDeclaration node) {
    final className = node.name.lexeme;
    Logger.debug(
        "[Visitor.visitClassDeclaration] START for '$className' in env: ${environment.hashCode}");

    // Retrieve the placeholder class object created in Pass 1
    Object? placeholder = environment.get(className);
    if (placeholder == null || placeholder is! InterpretedClass) {
      // This should not happen if Pass 1 worked correctly
      throw StateError(
          "Placeholder for class '$className' not found or invalid during Pass 2.");
    }
    final klass = placeholder;
    Logger.debug(
        "[Visitor.visitClassDeclaration] Retrieved placeholder for '$className' (hash: ${klass.hashCode})");

    // Resolve and populate relationships ON THE EXISTING klass object
    // Superclass lookup
    // InterpretedClass? superclass; // Keep this commented or remove
    if (node.extendsClause != null) {
      final superclassName = node.extendsClause!.superclass.name.lexeme;
      Logger.debug(
          "[Visitor.visitClassDeclaration]   Trying to get superclass '$superclassName' from env: ${environment.hashCode}");
      Object? potentialSuperclass;
      try {
        potentialSuperclass = environment.get(superclassName);
      } on RuntimeError {
        throw RuntimeError(
            "Superclass '$superclassName' not found for class '$className'. Ensure it's defined.");
      }

      if (potentialSuperclass is InterpretedClass) {
        // Standard Dart Superclass
        final superclass = potentialSuperclass;

        // Add checks for final, interface, and sealed modifiers
        if (superclass.isFinal) {
          throw RuntimeError(
              "Class '$className' cannot extend final class '$superclassName'.");
        }
        if (superclass.isInterface) {
          throw RuntimeError(
              "Class '$className' cannot extend interface class '$superclassName'. Use 'implements'.");
        }
        if (superclass.isSealed) {
          throw RuntimeError(
              "Class '$className' cannot extend sealed class '$superclassName' outside of its library.");
        }

        // Set the superclass and clear bridged superclass
        klass.superclass = superclass;
        klass.bridgedSuperclass = null;
        Logger.debug(
            "[Visitor.visitClassDeclaration] Set standard superclass '$superclassName' for '$className'");
      } else if (potentialSuperclass is BridgedClass) {
        final bridgedSuperclass = potentialSuperclass;
        // No modifier checks needed for bridged classes (yet?)

        // Set the bridged superclass and clear standard superclass
        klass.bridgedSuperclass = bridgedSuperclass;
        klass.superclass = null;
        Logger.debug(
            "[Visitor.visitClassDeclaration] Set BRIDGED superclass '$superclassName' for '$className'");
      } else {
        throw RuntimeError(
            "Superclass '$superclassName' for class '$className' resolved to ${potentialSuperclass?.runtimeType}, which is not a class or bridged class.");
      }
    }

    // Interface lookup
    if (node.implementsClause != null) {
      Logger.debug(
          "[Visitor.visitClassDeclaration] Processing 'implements' clause for '$className' in env: ${environment.hashCode}");
      for (final interfaceType in node.implementsClause!.interfaces) {
        final interfaceName = interfaceType.name.lexeme;
        Logger.debug(
            "[Visitor.visitClassDeclaration]   Trying to get interface '$interfaceName' from env: ${environment.hashCode}");
        try {
          final potentialInterface = environment.get(interfaceName);
          if (potentialInterface is InterpretedClass) {
            // Add checks for base and sealed modifiers
            if (potentialInterface.isBase) {
              throw RuntimeError(
                  "Class '$className' cannot implement base class '$interfaceName' outside of its library.");
            }
            if (potentialInterface.isSealed) {
              throw RuntimeError(
                  "Class '$className' cannot implement sealed class '$interfaceName' outside of its library.");
            }

            // Add to the interfaces list of the existing klass object
            klass.interfaces.add(potentialInterface);
            Logger.debug(
                "[Visitor.visitClassDeclaration] Added interface '$interfaceName' for '$className'");
          } else {
            throw RuntimeError(
                "Class '$className' cannot implement non-class '$interfaceName' (${potentialInterface?.runtimeType}).");
          }
        } on RuntimeError {
          throw RuntimeError(
              "Interface '$interfaceName' not found for class '$className'. Ensure it's defined.");
        }
      }
    }

    // Mixin application lookup
    if (node.withClause != null) {
      Logger.debug(
          "[Visitor.visitClassDeclaration] Processing 'with' clause for '$className' in env: ${environment.hashCode}");
      for (final mixinType in node.withClause!.mixinTypes) {
        final mixinName = mixinType.name.lexeme;
        Logger.debug(
            "[Visitor.visitClassDeclaration]   Trying to get mixin '$mixinName' from env: ${environment.hashCode}");

        Object? mixin;
        try {
          mixin = environment.get(mixinName);
        } on RuntimeError {
          throw RuntimeError(
              "Mixin '$mixinName' not found during lookup for class '$className'. Ensure it's defined (as a mixin or class mixin).");
        }

        if (mixin is InterpretedClass) {
          if (!mixin.isMixin) {
            throw RuntimeError(
                "Class '$mixinName' cannot be used as a mixin because it's not declared with 'mixin' or 'class mixin'.");
          }

          // Add checks for base and sealed modifiers
          if (mixin.isBase) {
            throw RuntimeError(
                "Class '$className' cannot mix in base class '$mixinName' outside of its library.");
          }
          if (mixin.isSealed) {
            throw RuntimeError(
                "Class '$className' cannot mix in sealed class '$mixinName' outside of its library.");
          }

          // Add to the mixins list of the existing klass object
          klass.mixins.add(mixin);
          Logger.debug(
              "[Visitor.visitClassDeclaration] Applied interpreted mixin '$mixinName' to '$className'");
        } else if (mixin is BridgedClass) {
          // Support for bridged classes as mixins
          if (!mixin.canBeUsedAsMixin) {
            throw RuntimeError(
                "Bridged class '$mixinName' cannot be used as a mixin. Set canBeUsedAsMixin=true when registering the bridge.");
          }

          // Add to the bridged mixins list
          klass.bridgedMixins.add(mixin);
          Logger.debug(
              "[Visitor.visitClassDeclaration] Applied bridged mixin '$mixinName' to '$className'");
        } else {
          throw RuntimeError(
              "Identifier '$mixinName' resolved to ${mixin?.runtimeType}, which is not a class/mixin, for class '$className'.");
        }
      }
    }

    // Populate members ON THE EXISTING klass object
    final staticInitEnv = environment; // Statics use the class definition env
    final originalVisitorEnv = environment; // Backup visitor env

    Logger.debug(
        "[Visitor.visitClassDeclaration] Processing members for '$className' (hash: ${klass.hashCode})");

    for (final member in node.members) {
      if (member is MethodDeclaration) {
        final methodName = member.name.lexeme;
        // Pass the ALREADY RETRIEVED klass object
        final function =
            InterpretedFunction.method(member, staticInitEnv, klass);

        if (member.isStatic) {
          if (member.isGetter) {
            klass.staticGetters[methodName] = function;
          } else if (member.isSetter) {
            klass.staticSetters[methodName] = function;
          } else {
            klass.staticMethods[methodName] = function;
          }
        } else if (!member.isAbstract) {
          if (member.isGetter) {
            klass.getters[methodName] = function;
          } else if (member.isSetter) {
            klass.setters[methodName] = function;
          } else if (member.isOperator) {
            // Add operator methods to the operators map
            klass.operators[methodName] = function;
          } else {
            klass.methods[methodName] = function;
          }
        } else {
          // Abstract
          if (!klass.isAbstract) {
            throw RuntimeError(
                "Abstract methods can only be declared in abstract classes. Method '${klass.name}.$methodName'.");
          }
          if (member.body is! EmptyFunctionBody) {
            throw RuntimeError(
                "Abstract methods cannot have a body. Method '${klass.name}.$methodName'.");
          }
          if (member.isGetter) {
            klass.getters[methodName] = function;
          } else if (member.isSetter) {
            klass.setters[methodName] = function;
          } else if (member.isOperator) {
            // Add abstract operator methods to the operators map
            klass.operators[methodName] = function;
          } else {
            klass.methods[methodName] = function;
          }
        }
      } else if (member is ConstructorDeclaration) {
        final function =
            InterpretedFunction.constructor(member, staticInitEnv, klass);
        final constructorName = member.name?.lexeme ?? '';
        klass.constructors[constructorName] = function;
      } else if (member is FieldDeclaration) {
        if (member.isStatic) {
          try {
            environment = staticInitEnv;
            for (final variable in member.fields.variables) {
              final fieldName = variable.name.lexeme;
              final isLate = member.fields.lateKeyword != null;
              final isFinal = member.fields.keyword?.lexeme == 'final';

              if (isLate) {
                // Handle late static field
                if (variable.initializer != null) {
                  // Late static field with lazy initializer
                  final lateVar = LateVariable(fieldName, () {
                    // Create a closure that will evaluate the initializer when accessed
                    final savedEnv = environment;
                    try {
                      environment = staticInitEnv;
                      return variable.initializer!.accept<Object?>(this);
                    } finally {
                      environment = savedEnv;
                    }
                  }, isFinal: isFinal);
                  klass.staticFields[fieldName] = lateVar;
                  Logger.debug(
                      "[ClassDecl] Defined late static field '$fieldName' with lazy initializer for class '${klass.name}'.");
                } else {
                  // Late static field without initializer
                  final lateVar =
                      LateVariable(fieldName, null, isFinal: isFinal);
                  klass.staticFields[fieldName] = lateVar;
                  Logger.debug(
                      "[ClassDecl] Defined late static field '$fieldName' without initializer for class '${klass.name}'.");
                }
              } else {
                // Regular static field handling
                Object? value;
                if (variable.initializer != null) {
                  value = variable.initializer!.accept<Object?>(this);
                }
                klass.staticFields[fieldName] = value;
              }
            }
          } finally {
            environment = originalVisitorEnv;
          }
        } else {
          klass.fieldDeclarations.add(member);
        }
      } else {
        throw StateError('Unknown member type: ${member.runtimeType}');
      }
    }
    Logger.debug(
        "[Visitor.visitClassDeclaration] Finished processing members for '$className'");

    // Final Checks (run on the populated klass object)
    // Check for unimplemented abstract members
    if (!klass.isAbstract) {
      final inheritedAbstract = klass.getAbstractInheritedMembers();
      final concreteMembers = klass.getConcreteMembers();
      for (final abstractName in inheritedAbstract.keys) {
        if (!concreteMembers.containsKey(abstractName)) {
          final abstractMember = inheritedAbstract[abstractName]!;
          String memberType = "method";
          if (abstractMember.isGetter) memberType = "getter";
          if (abstractMember.isSetter) memberType = "setter";
          throw RuntimeError(
              "Missing concrete implementation for inherited abstract $memberType '$abstractName' in class '${klass.name}'.");
        }
      }
    }

    // Check for unimplemented interface members
    if (!klass.isAbstract) {
      final requiredInterfaceMembers = klass.getAllInterfaceMembers();
      final availableConcreteMembers = klass.getAllConcreteMembers();
      for (final requiredName in requiredInterfaceMembers.keys) {
        if (!availableConcreteMembers.containsKey(requiredName)) {
          final memberType = requiredInterfaceMembers[requiredName]!;
          throw RuntimeError(
              "Missing concrete implementation for interface $memberType '$requiredName' in class '${klass.name}'.");
        }
      }
    }
    Logger.debug("[Visitor.visitClassDeclaration] END for '$className'");
    // No need to define/assign klass in the environment here, it was done in Pass 1.
    return null; // Class declaration statement doesn't return a value
  }

  @override
  Object? visitAssertStatement(AssertStatement node) {
    // Assertions are always enabled in this interpreter for now.
    final conditionValue = node.condition.accept<Object?>(this);

    final bridgedInstance = toBridgedInstance(conditionValue);
    bool conditionResult;
    if (conditionValue is bool) {
      conditionResult = conditionValue;
    } else if (bridgedInstance.$2 && bridgedInstance.$1?.nativeObject is bool) {
      conditionResult = bridgedInstance.$1!.nativeObject as bool;
    } else {
      throw RuntimeError(
        "Assertion condition must be a boolean, but was ${conditionValue?.runtimeType}.",
      );
    }

    if (!conditionResult) {
      // Condition is false, evaluate the message and throw.
      String assertionMessage = "Assertion failed";
      if (node.message != null) {
        final messageValue = node.message!.accept<Object?>(this);
        assertionMessage = "Assertion failed: ${stringify(messageValue)}";
      }
      // Mimic Dart's AssertionError by throwing a RuntimeError.
      throw RuntimeError(assertionMessage);
    }

    return null; // Assert statements don't produce a value.
  }

  // Visit Mixin Declaration (Adjusted for Two-Pass)
  @override
  Object? visitMixinDeclaration(MixinDeclaration node) {
    final mixinName = node.name.lexeme;
    Logger.debug(
        "[Visitor.visitMixinDeclaration] START for '$mixinName' in env: ${environment.hashCode}");

    // Retrieve the placeholder mixin object created in Pass 1
    Object? placeholder = environment.get(mixinName);
    if (placeholder == null ||
        placeholder is! InterpretedClass ||
        !placeholder.isMixin) {
      throw StateError(
          "Placeholder for mixin '$mixinName' not found or invalid during Pass 2.");
    }
    final mixinClass = placeholder;
    Logger.debug(
        "[Visitor.visitMixinDeclaration] Retrieved placeholder for mixin '$mixinName' (hash: ${mixinClass.hashCode})");

    // Resolve 'on' clause constraints ON THE EXISTING mixinClass object
    if (node.onClause != null) {
      mixinClass.onClauseTypes.clear(); // Clear existing before populating
      for (final typeNode in node.onClause!.superclassConstraints) {
        final typeName = typeNode.name.lexeme;
        try {
          final potentialType = environment.get(typeName);
          if (potentialType is InterpretedClass) {
            // Add to the onClauseTypes list of the existing mixinClass object
            mixinClass.onClauseTypes.add(potentialType);
            Logger.debug(
                "[Visitor.visitMixinDeclaration] Added 'on' constraint '$typeName' for '$mixinName'");
          } else {
            throw RuntimeError(
                "Type '$typeName' in 'on' clause of mixin '$mixinName' is not a class (${potentialType?.runtimeType}).");
          }
        } on RuntimeError {
          throw RuntimeError(
              "Type '$typeName' in 'on' clause of mixin '$mixinName' not found. Ensure it's defined.");
        }
      }
    }

    // Populate members ON THE EXISTING mixinClass object
    final declarationEnv =
        environment; // Members use the mixin's declaration env
    final originalVisitorEnv = environment;

    Logger.debug(
        "[Visitor.visitMixinDeclaration] Processing members for mixin '$mixinName' (hash: ${mixinClass.hashCode})");

    try {
      environment = declarationEnv;
      for (final member in node.members) {
        if (member is MethodDeclaration) {
          final methodName = member.name.lexeme;
          // Methods capture the GLOBAL environment via the mixinClass
          final function =
              InterpretedFunction.method(member, globalEnvironment, mixinClass);
          if (member.isStatic) {
            // Static members belong to the mixin definition itself
            if (member.isGetter) {
              mixinClass.staticGetters[methodName] = function;
            } else if (member.isSetter) {
              mixinClass.staticSetters[methodName] = function;
            } else {
              mixinClass.staticMethods[methodName] = function;
            }
          } else {
            if (member.isGetter) {
              mixinClass.getters[methodName] = function;
            } else if (member.isSetter) {
              mixinClass.setters[methodName] = function;
            } else if (member.isOperator) {
              // Add operator methods to the operators map for mixins
              mixinClass.operators[methodName] = function;
            } else {
              mixinClass.methods[methodName] = function;
            }
          }
        } else if (member is FieldDeclaration) {
          if (member.isStatic) {
            for (final variable in member.fields.variables) {
              mixinClass.staticFields[variable.name.lexeme] =
                  variable.initializer?.accept<Object?>(this);
            }
          } else {
            mixinClass.fieldDeclarations.add(member);
          }
        } else if (member is ConstructorDeclaration) {
          throw RuntimeError(
              "Mixins cannot declare constructors ('$mixinName').");
        }
      }
    } finally {
      environment = originalVisitorEnv;
    }

    Logger.debug("[Visitor.visitMixinDeclaration] END for '$mixinName'");
    return null; // Mixin declaration doesn't return a value
  }

  @override
  Object? visitEnumDeclaration(EnumDeclaration node) {
    final enumName = node.name.lexeme;
    Logger.debug(
        "[Visitor.visitEnumDeclaration] START (Pass 2) for '$enumName'");

    // Retrieve the enum placeholder object created in Pass 1
    final enumObj = environment.get(enumName);
    if (enumObj == null || enumObj is! InterpretedEnum) {
      throw StateError(
          "Enum placeholder object for '$enumName' not found or invalid during Pass 2.");
    }

    // Process Mixin Application (similar to class mixin handling)
    if (node.withClause != null) {
      Logger.debug(
          "[Visitor.visitEnumDeclaration] Processing 'with' clause for '$enumName'");
      for (final mixinType in node.withClause!.mixinTypes) {
        final mixinName = mixinType.name.lexeme;
        Logger.debug(
            "[Visitor.visitEnumDeclaration]   Trying to get mixin '$mixinName'");

        Object? mixin;
        try {
          mixin = environment.get(mixinName);
        } on RuntimeError {
          throw RuntimeError(
              "Mixin '$mixinName' not found during lookup for enum '$enumName'. Ensure it's defined (as a mixin or class mixin).");
        }

        if (mixin is InterpretedClass) {
          if (!mixin.isMixin) {
            throw RuntimeError(
                "Class '$mixinName' cannot be used as a mixin because it's not declared with 'mixin' or 'class mixin'.");
          }

          // Add to the mixins list of the enum object
          enumObj.mixins.add(mixin);
          Logger.debug(
              "[Visitor.visitEnumDeclaration] Applied interpreted mixin '$mixinName' to '$enumName'");
        } else if (mixin is BridgedClass) {
          // Support for bridged classes as mixins
          if (!mixin.canBeUsedAsMixin) {
            throw RuntimeError(
                "Bridged class '$mixinName' cannot be used as a mixin. Set canBeUsedAsMixin=true when registering the bridge.");
          }

          // Add to the bridged mixins list
          enumObj.bridgedMixins.add(mixin);
          Logger.debug(
              "[Visitor.visitEnumDeclaration] Applied bridged mixin '$mixinName' to '$enumName'");
        } else {
          throw RuntimeError(
              "Identifier '$mixinName' resolved to ${mixin?.runtimeType}, which is not a class/mixin, for enum '$enumName'.");
        }
      }
    }

    // Process Members (Static and Instance)
    // Members defined in the enum body (methods, getters, fields, constructors)
    final originalVisitorEnv = environment; // Save original environment
    try {
      // Members are defined in the enum's declaration scope
      environment = enumObj.declarationEnvironment;
      for (final member in node.members) {
        if (member is MethodDeclaration) {
          final methodName = member.name.lexeme;
          // Methods capture the enum's declaration environment implicitly
          final function =
              InterpretedFunction.method(member, environment, enumObj);

          if (member.isStatic) {
            if (member.isGetter) {
              enumObj.staticGetters[methodName] = function;
            } else if (member.isSetter) {
              enumObj.staticSetters[methodName] = function;
            } else {
              enumObj.staticMethods[methodName] = function;
            }
            Logger.debug(
                "[Visitor.visitEnumDeclaration]   Processed static method/getter/setter: $methodName");
          } else {
            if (member.isAbstract) {
              throw RuntimeError(
                  "Enums cannot have abstract members ('$enumName.$methodName').");
            }
            if (member.isGetter) {
              enumObj.getters[methodName] = function;
            } else if (member.isSetter) {
              enumObj.setters[methodName] = function;
            } else {
              enumObj.methods[methodName] = function;
            }
            Logger.debug(
                "[Visitor.visitEnumDeclaration]   Processed instance method/getter/setter: $methodName");
          }
        } else if (member is ConstructorDeclaration) {
          if (member.factoryKeyword != null) {
            throw UnimplementedError(
                "Factory constructors in enums are not yet supported.");
          }
          if (member.redirectedConstructor != null) {
            throw UnimplementedError(
                "Redirecting constructors in enums are not yet supported.");
          }
          // Check if it's the default unnamed constructor or a named one
          final constructorName = member.name?.lexeme ?? '';
          // Constructors also capture the enum's declaration environment
          final function =
              InterpretedFunction.constructor(member, environment, enumObj);

          enumObj.constructors[constructorName] = function;
          Logger.debug(
              "[Visitor.visitEnumDeclaration]   Processed constructor: ${constructorName.isEmpty ? enumName : '$enumName.$constructorName'}");
        } else if (member is FieldDeclaration) {
          // Store field declarations for instance initialization
          // Only non-static fields are relevant for enum value instances
          if (!member.isStatic) {
            enumObj.fieldDeclarations.add(member);
            for (final variable in member.fields.variables) {
              Logger.debug(
                  "[Visitor.visitEnumDeclaration]   Stored instance field declaration: ${variable.name.lexeme}");
            }
          } else {
            // Evaluate static fields immediately
            for (final variable in member.fields.variables) {
              final fieldName = variable.name.lexeme;
              Object? value;
              if (variable.initializer != null) {
                value = variable.initializer!.accept<Object?>(this);
              }
              enumObj.staticFields[fieldName] = value;
              Logger.debug(
                  "[Visitor.visitEnumDeclaration]   Evaluated static field: $fieldName = $value");
            }
          }
        } else {
          Logger.warn(
              "[Visitor.visitEnumDeclaration]   Ignoring unknown member type: ${member.runtimeType}");
        }
      }
    } finally {
      environment = originalVisitorEnv; // Restore environment
    }

    // Instantiate Enum Values
    Logger.debug(
        "[Visitor.visitEnumDeclaration]   Instantiating enum values...");
    for (int i = 0; i < node.constants.length; i++) {
      final constantDecl = node.constants[i];
      final valueName = constantDecl.name.lexeme;

      if (enumObj.values.containsKey(valueName)) {
        Logger.warn(
            "[Visitor.visitEnumDeclaration] Enum value '$enumName.$valueName' already exists (should not happen).");
        continue;
      }

      // Create the runtime value instance (without initialized fields yet)
      final enumValueInstance = InterpretedEnumValue(enumObj, valueName, i);

      // Initialize Instance Fields using Constructor
      final constructorInvocation = constantDecl.arguments;
      final constructorName =
          constructorInvocation?.constructorSelector?.name.name ?? '';
      final constructorFunc = enumObj.constructors[constructorName];

      if (constructorFunc == null && constructorInvocation != null) {
        throw RuntimeError(
            "Enum '$enumName' does not have a constructor named '$constructorName' required by constant '$valueName'.");
      }
      if (constructorFunc == null &&
          enumObj.constructors.isNotEmpty &&
          enumObj.constructors.containsKey('')) {
        throw RuntimeError(
            "Enum '$enumName' has a default constructor but constant '$valueName' doesn't call it implicitly (requires explicit `()` if args are needed or constructor exists).");
      }
      // If there are NO constructors defined at all, and no args are passed, it's okay.
      if (constructorFunc != null && constructorInvocation != null) {
        Logger.debug(
            "[Visitor.visitEnumDeclaration]     Calling constructor '${constructorName.isEmpty ? enumName : '$enumName.$constructorName'}' for value '$valueName'");
        // Evaluate arguments for the constructor call
        final (positionalArgs, namedArgs) =
            _evaluateArguments(constructorInvocation.argumentList);

        // Call the constructor function, binding `this` to the enumValueInstance.
        // The constructor's call method needs to handle field initialization.
        try {
          // Use the _prepareExecutionEnvironment helper? Or call directly?
          // Need to ensure constructor initializers (: this.field = arg) run.
          // Let's assume constructorFunc.call handles this when isInitializer is true.
          final boundConstructor = constructorFunc.bind(enumValueInstance);
          boundConstructor.call(this, positionalArgs, namedArgs);
          Logger.debug(
              "[Visitor.visitEnumDeclaration]     Constructor call finished for '$valueName'. Fields: $enumValueInstance"); // Log instance directly for now
        } on RuntimeError catch (e) {
          throw RuntimeError(
              "Error executing constructor for enum value '$enumName.$valueName': ${e.message}");
        } catch (e) {
          throw RuntimeError(
              "Unexpected error executing constructor for enum value '$enumName.$valueName': $e");
        }
      } else if (constructorFunc == null &&
          constructorInvocation == null &&
          enumObj.constructors.isNotEmpty) {
        // Has constructors, but none called and no default exists implicitly.
        throw RuntimeError(
            "Enum constant '$enumName.$valueName' must call a constructor if the enum defines any.");
      } else {
        Logger.debug(
            "[Visitor.visitEnumDeclaration]     No constructor called for '$valueName' (enum has no explicit constructors or constant has no args).");
        // Initialize fields from declarations if no constructor called?
        // This might mirror class field initialization before constructor body.
        final fieldInitEnv =
            Environment(enclosing: enumObj.declarationEnvironment);
        fieldInitEnv.define('this', enumValueInstance);
        final originalVisitorEnvForFields = environment;
        try {
          environment = fieldInitEnv;
          for (final fieldDecl in enumObj.fieldDeclarations) {
            for (final variable in fieldDecl.fields.variables) {
              if (variable.initializer != null) {
                final fieldName = variable.name.lexeme;
                final value = variable.initializer!.accept<Object?>(this);
                enumValueInstance.setField(fieldName, value);
                Logger.debug(
                    "[Visitor.visitEnumDeclaration]     Initialized instance field '$fieldName'=$value for '$valueName' (default init).");
              }
            }
          }
        } finally {
          environment = originalVisitorEnvForFields;
        }
      }

      // Store the fully initialized instance in the enum object's map
      enumObj.values[valueName] = enumValueInstance;
      Logger.debug(
          "[Visitor.visitEnumDeclaration]   Created and initialized instance for '$enumName.$valueName' with index $i");
    }

    // Pre-cache the values list
    try {
      enumObj.valuesList; // Access the getter to trigger cache creation
      Logger.debug(
          "[Visitor.visitEnumDeclaration]   Cached 'values' list for '$enumName'.");
    } catch (e) {
      // Log error if caching fails (shouldn't happen ideally)
      Logger.error(
          "[Visitor.visitEnumDeclaration] Failed to cache 'values' for '$enumName': $e");
    }

    Logger.debug("[Visitor.visitEnumDeclaration] END (Pass 2) for '$enumName'");
    return null; // Declaration doesn't return a value
  }

  // Helper function to compute compound assignment values
  Object? computeCompoundValue(
      Object? currentValue, Object? rhsValue, TokenType operatorType) {
    // Unwrap BridgedInstance if necessary
    final bridgedInstance = toBridgedInstance(currentValue);
    final left =
        bridgedInstance.$2 ? bridgedInstance.$1!.nativeObject : currentValue;
    final right = rhsValue;

    if (operatorType == TokenType.PLUS_EQ) {
      // Use unwrapped left/right for calculation
      if (left is num && right is num) {
        return left + right;
      } else if (left is String && right != null) {
        return left + stringify(right);
      } else if (left is List && right is List) {
        // For List += List, create a new list with both elements
        // This is how Dart's List + operator works
        return [...left, ...right];
      }
      // Fall through to extension check if standard types don't match
    } else if (operatorType == TokenType.MINUS_EQ) {
      // Use unwrapped left/right for calculation
      if (left is num && right is num) {
        return left - right;
      }
      // Fall through
    } else if (operatorType == TokenType.STAR_EQ) {
      // Use unwrapped left/right for calculation
      if (left is num && right is num) {
        return left * right;
      }
      // Fall through
    } else if (operatorType == TokenType.SLASH_EQ) {
      // Use unwrapped left/right for calculation
      if (left is num && right is num) {
        if (right == 0) throw RuntimeError("Division by zero in '/='.");
        return left.toDouble() / right.toDouble();
      }
      // Fall through
    } else if (operatorType == TokenType.TILDE_SLASH_EQ) {
      // Use unwrapped left/right for calculation
      if (left is num && right is num) {
        if (rhsValue == 0) {
          throw RuntimeError("Integer division by zero in '~/='.");
        }
        return left ~/ right;
      }
      // Fall through
    } else if (operatorType == TokenType.PERCENT_EQ) {
      // Use unwrapped left/right for calculation
      if (left is num && right is num) {
        if (right == 0) throw RuntimeError("Modulo by zero in '%='.");
        return left % right;
      }
      // Fall through
    } else if (operatorType == TokenType.QUESTION_QUESTION_EQ) {
      // Note: Uses original currentValue, not unwrapped 'left'
      if (currentValue == null) {
        return rhsValue; // If left is null, assign right
      } else {
        return currentValue; // If left is not null, keep left
      }
    } else if (operatorType == TokenType.AMPERSAND_EQ) {
      // Bitwise AND assignment (&=)
      if (left is int && right is int) {
        return left & right;
      } else if (left is BigInt && right is BigInt) {
        return left & right;
      }
      // Fall through to extension search
    } else if (operatorType == TokenType.BAR_EQ) {
      // Bitwise OR assignment (|=)
      if (left is int && right is int) {
        return left | right;
      } else if (left is BigInt && right is BigInt) {
        return left | right;
      }
      // Fall through to extension search
    } else if (operatorType == TokenType.CARET_EQ) {
      // Bitwise XOR assignment (^=)
      if (left is int && right is int) {
        return left ^ right;
      } else if (left is BigInt && right is BigInt) {
        return left ^ right;
      }
      // Fall through to extension search
    } else if (operatorType == TokenType.GT_GT_EQ) {
      // Right shift assignment (>>=)
      if (left is int && right is int) {
        return left >> right;
      } else if (left is BigInt && right is int) {
        return left >> right;
      }
      // Fall through to extension search
    } else if (operatorType == TokenType.LT_LT_EQ) {
      // Left shift assignment (<<=)
      if (left is int && right is int) {
        return left << right;
      } else if (left is BigInt && right is int) {
        return left << right;
      }
      // Fall through to extension search
    } else if (operatorType == TokenType.GT_GT_GT_EQ) {
      // Unsigned right shift assignment (>>>=)
      if (left is int && right is int) {
        return left >>> right;
      }
      // Note: BigInt doesn't support >>> operator
      // Fall through to extension search
    }

    Logger.debug(
        "[CompoundAssign] Standard op failed for $operatorType. Trying extension operator.");
    final String? operatorName = _mapCompoundToOperatorName(operatorType);

    if (operatorName != null) {
      try {
        final extensionOperator =
            environment.findExtensionMember(currentValue, operatorName);

        if (extensionOperator is InterpretedExtensionMethod &&
            extensionOperator.isOperator) {
          Logger.debug(
              "[CompoundAssign] Found extension operator '$operatorName' for type ${currentValue?.runtimeType}. Calling...");
          // Call the extension operator method
          // Args: receiver (currentValue), right-hand-side (rhsValue)
          final extensionPositionalArgs = [currentValue, rhsValue];
          try {
            return extensionOperator.call(this, extensionPositionalArgs, {});
          } on ReturnException catch (e) {
            return e.value; // Should not happen for operators, but handle
          } catch (e) {
            throw RuntimeError(
                "Error executing extension operator '$operatorName' for compound assignment: $e");
          }
        }
        Logger.debug(
            "[CompoundAssign] No suitable extension operator '$operatorName' found for type ${currentValue?.runtimeType}.");
      } on RuntimeError catch (findError) {
        Logger.debug(
            "[CompoundAssign] No extension member '$operatorName' found for type ${currentValue?.runtimeType}. Error: ${findError.message}");
        // Fall through to the final unimplemented error
      }
    }

    throw UnimplementedError(
        'Compound assignment operator $operatorType not handled for types ${currentValue?.runtimeType} and ${rhsValue?.runtimeType}');
  }

  // Map compound assignment token to operator method name
  String? _mapCompoundToOperatorName(TokenType compoundOp) {
    switch (compoundOp) {
      case TokenType.PLUS_EQ:
        return '+';
      case TokenType.MINUS_EQ:
        return '-';
      case TokenType.STAR_EQ:
        return '*';
      case TokenType.SLASH_EQ:
        return '/';
      case TokenType.PERCENT_EQ:
        return '%';
      case TokenType.TILDE_SLASH_EQ:
        return '~/';
      case TokenType.AMPERSAND_EQ:
        return '&';
      case TokenType.BAR_EQ:
        return '|';
      case TokenType.CARET_EQ:
        return '^';
      case TokenType.GT_GT_EQ:
        return '>>';
      case TokenType.LT_LT_EQ:
        return '<<';
      case TokenType.GT_GT_GT_EQ:
        return '>>>';
      // TokenType.QUESTION_QUESTION_EQ (??=) doesn't map to a binary operator method.
      default:
        return null;
    }
  }

  /// Check if a List matches the expected generic type argument
  bool _checkGenericListType(List list, TypeAnnotation elementTypeNode) {
    // If list is empty, we can't verify element types
    if (list.isEmpty) {
      return true; // Accept empty lists for any type
    }

    // Check each element
    for (final element in list) {
      if (!_checkValueMatchesType(element, elementTypeNode)) {
        return false;
      }
    }
    return true;
  }

  /// Check if a Map matches the expected generic type arguments
  bool _checkGenericMapType(
      Map map, TypeAnnotation keyTypeNode, TypeAnnotation valueTypeNode) {
    // If map is empty, we can't verify key/value types
    if (map.isEmpty) {
      return true; // Accept empty maps for any type
    }

    // Check each key-value pair
    for (final entry in map.entries) {
      if (!_checkValueMatchesType(entry.key, keyTypeNode)) {
        return false;
      }
      if (!_checkValueMatchesType(entry.value, valueTypeNode)) {
        return false;
      }
    }
    return true;
  }

  /// Check if a value matches a type annotation
  bool _checkValueMatchesType(Object? value, TypeAnnotation typeNode) {
    if (typeNode is! NamedType) {
      // For now, only handle NamedType
      return true;
    }

    final typeName = typeNode.name.lexeme;

    // Handle nullable types
    if (typeNode.question != null && value == null) {
      return true; // null matches nullable types
    }

    // Check built-in types
    switch (typeName) {
      case 'int':
        return value is int;
      case 'double':
        return value is double;
      case 'num':
        return value is num;
      case 'String':
        return value is String;
      case 'bool':
        return value is bool;
      case 'List':
        if (value is! List) return false;
        // Check nested generic type if present
        if (typeNode.typeArguments != null &&
            typeNode.typeArguments!.arguments.isNotEmpty) {
          return _checkGenericListType(
              value, typeNode.typeArguments!.arguments[0]);
        }
        return true;
      case 'Map':
        if (value is! Map) return false;
        // Check nested generic types if present
        if (typeNode.typeArguments != null &&
            typeNode.typeArguments!.arguments.length >= 2) {
          return _checkGenericMapType(
              value,
              typeNode.typeArguments!.arguments[0],
              typeNode.typeArguments!.arguments[1]);
        }
        return true;
      case 'Object':
      case 'dynamic':
        return value !=
            null; // Everything matches Object/dynamic (except null for Object)
      default:
        // For user-defined types, try to resolve from environment
        try {
          final targetType = environment.get(typeName);
          if (targetType is InterpretedClass) {
            return value is InterpretedInstance &&
                value.klass.isSubtypeOf(targetType);
          } else if (targetType is BridgedClass) {
            return value is BridgedInstance &&
                value.bridgedClass.isSubtypeOf(targetType);
          }
        } catch (_) {
          // If type not found, assume it matches (lenient approach)
          return true;
        }
        return true;
    }
  }

  @override
  dynamic visitIdentifier(Identifier node) {
    final value = environment.get(node.name);
    if (value == null) {
      // Log environment ID on failure
      Logger.debug(
          "[visitIdentifier] Failed to find '${node.name}' in env: ${environment.hashCode}");
      throw RuntimeError("Undefined variable: ${node.name}");
    }
    return value;
  }

  bool _isInCatchBlock = false;

  InternalInterpreterException? _originalCaughtInternalExceptionForRethrow;

  @override
  Object? visitTryStatement(TryStatement node) {
    // Store the internal exception if caught
    InternalInterpreterException? caughtInternalException;
    StackTrace? caughtStackTrace;

    Object? tryResult;
    Object? returnValue; // Store either the try result or the catch result

    final originalEnv = environment; // Save to restore after catch/finally

    try {
      // 1. Execute the try block
      Logger.debug("[TryStatement] Entering try block");
      tryResult = node.body.accept<Object?>(this);
      returnValue = tryResult; // Default value if no exception
      Logger.debug("[TryStatement] Try block completed normally");
    } on ReturnException {
      // If the try returns, the finally must execute, but we propagate the return
      Logger.debug(
          "[TryStatement] Propagating ReturnException from try block.");
      rethrow;
    } on BreakException {
      // Propagate for outer loops/switch
      Logger.debug("[TryStatement] Propagating BreakException from try block");
      rethrow;
    } on ContinueException {
      // Propagate for outer loops
      Logger.debug(
          "[TryStatement] Propagating ContinueException from try block");
      rethrow;
    } on InternalInterpreterException catch (e, s) {
      // Catch ONLY the exceptions already encapsulated (coming from a 'throw')
      Logger.debug(
          "[TryStatement] Caught internal exception in try block: ${e.originalThrownValue}");
      caughtInternalException = e; // Store the internal exception
      caughtStackTrace = s;
      returnValue = null; // No normal try result
    } catch (userException, userStack) {
      // Catch any other exception (potentially native)
      Logger.debug(
          "[TryStatement] Caught unexpected non-InternalInterpreterException in TRY: $userException");
      // Encapsulate the user/native exception in our internal type
      caughtInternalException = InternalInterpreterException(userException);
      caughtStackTrace = userStack;
      returnValue = null;
    }

    // 2. Execute the catch blocks (if an internal exception was raised AND stored)
    if (caughtInternalException != null) {
      // Use the ORIGINAL value from the internal exception for checks
      final originalThrownValue = caughtInternalException.originalThrownValue;

      Logger.debug(
          "[TryStatement] Looking for catch clauses for thrown value: ${stringify(originalThrownValue)} (type: ${originalThrownValue?.runtimeType})");

      for (final clause in node.catchClauses) {
        bool typeMatch = false;
        String? targetCatchTypeName;

        // Type check (on Type)
        if (clause.exceptionType == null) {
          // No 'on Type' clause, matches anything
          typeMatch = true;
          Logger.debug("[TryStatement] Catch clause matches any type.");
        } else {
          final typeNode = clause.exceptionType!;
          if (typeNode is NamedType) {
            targetCatchTypeName = typeNode.name.lexeme;
            Logger.debug(
                "[TryStatement] Checking catch clause for type: $targetCatchTypeName");

            // Use originalThrownValue for type checking
            switch (targetCatchTypeName) {
              case 'int':
                typeMatch = originalThrownValue is int;
                break;
              case 'double':
                typeMatch = originalThrownValue is double;
                break;
              case 'num':
                typeMatch = originalThrownValue is num;
                break;
              case 'String':
                typeMatch = originalThrownValue is String;
                break;
              case 'bool':
                typeMatch = originalThrownValue is bool;
                break;
              case 'List':
                typeMatch = originalThrownValue is List;
                break;
              case 'Null':
                // This is tricky. 'on Null' might not be common.
                // Check if the original value is null.
                typeMatch = originalThrownValue == null;
                break;
              case 'Object':
                // Everything non-null is an Object?
                // Dart's 'on Object' catches non-null exceptions.
                typeMatch = originalThrownValue != null;
                break;
              case 'dynamic': // 'on dynamic' catches everything, like no 'on' clause
                typeMatch = true;
                break;
              case 'void': // Cannot catch on void
                typeMatch = false;
                break;
              default:
                // User-defined type
                try {
                  final targetType = environment.get(targetCatchTypeName);
                  if (targetType is InterpretedClass) {
                    // Check if the ORIGINAL thrown value is an instance of the target type
                    if (originalThrownValue is InterpretedInstance) {
                      typeMatch =
                          originalThrownValue.klass.isSubtypeOf(targetType);
                      Logger.debug(
                          "[TryStatement]   Checking instance '${originalThrownValue.klass.name}' against class '$targetCatchTypeName'. Result: $typeMatch");
                    } else {
                      // Native value cannot be subtype of user-defined class
                      typeMatch = false;
                      Logger.debug(
                          "[TryStatement]   Thrown value is native (${originalThrownValue?.runtimeType}), cannot match user class '$targetCatchTypeName'.");
                    }
                  } else {
                    // Target type name resolved, but it's not an InterpretedClass
                    typeMatch = false;
                    Logger.warn(
                        "[TryStatement] Catch clause type '$targetCatchTypeName' not found or not a class/mixin.");
                  }
                } catch (e) {
                  // Error resolving targetCatchTypeName
                  Logger.warn(
                      "[TryStatement] Error resolving catch clause type '$targetCatchTypeName': $e");
                  typeMatch = false;
                }
            }
          } else {
            // Handle other type nodes like FunctionType if necessary
            Logger.warn(
                "[TryStatement] Unsupported catch clause type node: ${clause.exceptionType.runtimeType}");
            typeMatch = false;
          }
        }

        if (typeMatch) {
          Logger.debug(
              "[TryStatement] Found matching catch clause${targetCatchTypeName != null ? ' for type $targetCatchTypeName' : ''}.");
          final exceptionParameterName = clause.exceptionParameter?.name.lexeme;
          final stackTraceParameterName =
              clause.stackTraceParameter?.name.lexeme;

          // Create an environment for the catch block
          environment =
              originalEnv; // Restore the environment before creating the catch environment
          final catchEnv = Environment(enclosing: environment);
          if (exceptionParameterName != null) {
            // Define with the ORIGINAL thrown value
            catchEnv.define(exceptionParameterName, originalThrownValue);
            Logger.debug(
                "[TryStatement] Defined exception var '$exceptionParameterName' with original value: ${stringify(originalThrownValue)}");
          }
          if (stackTraceParameterName != null) {
            // Store the textual representation of the stack trace
            // Ensure caughtStackTrace is not null before calling toString()
            final stackTraceString =
                caughtStackTrace?.toString() ?? "Stack trace unavailable";
            catchEnv.define(stackTraceParameterName, stackTraceString);
            Logger.debug(
                "[TryStatement] Defined stacktrace var '$stackTraceParameterName'."); // Don't print full trace here
          }

          // Execute the catch block in its environment
          environment = catchEnv;
          _isInCatchBlock = true;
          _originalCaughtInternalExceptionForRethrow =
              caughtInternalException; // Store the internal exception for potential rethrow
          //
          try {
            Logger.debug("[TryStatement] Entering catch block body");
            returnValue = clause.body.accept<Object?>(this);
            Logger.debug("[TryStatement] Catch block completed normally");
            // The exception is handled, clear caughtInternalException to not rethrow it after finally
            caughtInternalException = null;
          } on ReturnException {
            // The catch made a return, we propagate it immediately but the finally must execute
            Logger.debug(
                "[TryStatement] Caught ReturnException in CATCH block");
            // IMPORTANT: Clean the rethrow state BEFORE rethrowing
            _isInCatchBlock = false;
            _originalCaughtInternalExceptionForRethrow = null;
            rethrow; // IMPORTANT: Ensure the return ends the function
          } on InternalInterpreterException catch (catchInternalError, catchStack) {
            if (identical(catchInternalError,
                _originalCaughtInternalExceptionForRethrow)) {
              // This is the exception rethrown by 'rethrow'. It must be allowed to propagate.
              Logger.debug(
                  "[TryStatement] Identified rethrown exception. Propagating.");
              // IMPORTANT: Clean the rethrow state BEFORE rethrowing
              _isInCatchBlock = false;
              _originalCaughtInternalExceptionForRethrow = null;
              rethrow; // Relaunch to let the outer mechanism handle it
            } else {
              // This is a NEW internal exception coming from the catch body.
              Logger.debug(
                  "[TryStatement] Caught NEW internal exception in CATCH block: ${catchInternalError.originalThrownValue}");
              caughtInternalException =
                  catchInternalError; // The new internal exception replaces the old one
              caughtStackTrace = catchStack; // Update stack trace too
              // The new exception is NOT handled by this try/catch
              returnValue = null;
            }
          } catch (nativeError, nativeStack) {
            // Catch other unexpected errors from catch block
            Logger.debug(
                "[TryStatement] Caught unexpected non-InternalInterpreterException in CATCH: $nativeError");
            // Wrap it as InternalInterpreterException to propagate
            caughtInternalException = InternalInterpreterException(nativeError);
            caughtStackTrace = nativeStack;
            returnValue = null;
          } finally {
            // IMPORTANT: Clean the rethrow state if we exit the catch
            _isInCatchBlock = false;
            _originalCaughtInternalExceptionForRethrow = null;
            environment =
                originalEnv; // Restore the environment after the catch
          }
          // Exit the for loop of catch clauses, because we found a match
          break;
        } else {
          Logger.debug(
              "[TryStatement] Skipping catch clause (type mismatch: needed $targetCatchTypeName, got ${originalThrownValue?.runtimeType})");
        }
      } // fin boucle for catchClauses
    } // fin if (caughtInternalException != null)

    // 3. Execute the finally block (always)
    // Store potential exception from finally block (must be internal type now)
    InternalInterpreterException? finallyInternalException;

    if (node.finallyBlock != null) {
      environment = originalEnv; // Ensure we are in the correct environment
      Logger.debug("[TryStatement] Entering finally block");
      try {
        node.finallyBlock!.accept<Object?>(this);
        Logger.debug("[TryStatement] Finally block completed normally");
      } on ReturnException {
        // If finally returns, it overrides everything
        Logger.debug("[TryStatement] Caught ReturnException in FINALLY block");
        rethrow; // The return of the finally is the final value
      } on InternalInterpreterException catch (e) {
        // Catch internal exceptions coming from finally (throw/rethrow in finally)
        Logger.debug(
            "[TryStatement] Caught internal exception in FINALLY block: ${e.originalThrownValue}");
        // The internal exception of the finally prevails
        finallyInternalException = e; // Store internal exception
        // We might want to store the stack trace too if needed later
      } catch (e) {
        // Catch other unexpected errors from finally block
        Logger.debug(
            "[TryStatement] Caught unexpected non-InternalInterpreterException in FINALLY: $e");
        // Wrap it as InternalInterpreterException
        finallyInternalException = InternalInterpreterException(e);
      }
    }

    // 4. Déterminer le résultat final
    if (finallyInternalException != null) {
      Logger.debug(
          "[TryStatement] Rethrowing internal exception from FINALLY: ${finallyInternalException.originalThrownValue}");
      throw finallyInternalException; // The internal exception of the Finally always prevails
    }

    // If there is an unhandled internal exception (either original, or from a catch) and no exception from the finally
    if (caughtInternalException != null /* && !exceptionHandled */) {
      // Note: If it was handled, caughtInternalException was set to null inside the matching catch block.
      // So, if caughtInternalException is still non-null here, it means it wasn't handled.
      Logger.debug(
          "[TryStatement] Rethrowing unhandled internal exception from TRY/CATCH: ${caughtInternalException.originalThrownValue}");
      throw caughtInternalException;
    }

    // Otherwise, return the value (either from the try, or from the catch that handled the exception)
    // Note: if a catch made a return, it was already propagated by the 'rethrow' above.
    Logger.debug("[TryStatement] Exiting normally, returning: $returnValue");
    return returnValue;
  }

  @override
  Object? visitThrowExpression(ThrowExpression node) {
    // 1. Evaluate the expression that is thrown
    final thrownValue = node.expression.accept<Object?>(this);

    // 2. Create and throw an InternalInterpreterException.
    final message = stringify(thrownValue); // Keep for debug log
    Logger.debug("[ThrowExpression] Throwing (original value): $message");
    // Throw the specific internal exception, wrapping the original value
    throw InternalInterpreterException(thrownValue);
    // We don't capture stack trace here, the 'catch' block does it.
  }

  @override
  Object? visitRethrowExpression(RethrowExpression node) {
    final asyncState = currentAsyncState;
    if (asyncState == null) {
      if (!_isInCatchBlock ||
          _originalCaughtInternalExceptionForRethrow == null) {
        throw RuntimeError("'rethrow' can only be used within a catch block.");
      }
      Logger.debug(
          "[Rethrow] Rethrowing original internal exception: ${_originalCaughtInternalExceptionForRethrow!.originalThrownValue}");
      // Re-launch the *original internal exception* that was caught by the enclosing catch block
      throw _originalCaughtInternalExceptionForRethrow!;
    }
    if (!asyncState.isHandlingErrorForRethrow) {
      throw RuntimeError("'rethrow' can only be used within a catch block.");
    }
    final originalError = asyncState.originalErrorForRethrow;
    if (originalError == null) {
      // Should not happen if isHandlingErrorForRethrow is true, but safety check
      throw StateError("Internal error: Inconsistent state for rethrow.");
    }
    Logger.debug(
        "[Rethrow] Rethrowing original internal exception: ${originalError.originalThrownValue}");
    // Set flag to indicate this is a rethrow, not a new exception
    asyncState.isCurrentlyRethrowing = true;
    // Relaunch the original exception stored in the async state
    throw originalError;
  }

  @override
  Object? visitIsExpression(IsExpression node) {
    final expressionValue = node.expression.accept<Object?>(this);
    final typeNode = node.type;
    bool result = false;

    if (typeNode is NamedType) {
      final typeName = typeNode.name.lexeme;

      // Handle built-in types first
      switch (typeName) {
        case 'int':
          result = expressionValue is int;
          break;
        case 'double':
          result = expressionValue is double;
          break;
        case 'num':
          result = expressionValue is num;
          break;
        case 'String':
          result = expressionValue is String;
          break;
        case 'bool':
          result = expressionValue is bool;
          break;
        case 'List':
          if (expressionValue is! List) {
            result = false;
          } else if (typeNode.typeArguments == null ||
              typeNode.typeArguments!.arguments.isEmpty) {
            // No type arguments specified, just check if it's a List
            result = true;
          } else {
            // Check generic type arguments
            result = _checkGenericListType(
                expressionValue, typeNode.typeArguments!.arguments[0]);
          }
          break;
        case 'Map':
          if (expressionValue is! Map) {
            result = false;
          } else if (typeNode.typeArguments == null ||
              typeNode.typeArguments!.arguments.isEmpty) {
            // No type arguments specified, just check if it's a Map
            result = true;
          } else {
            // Check generic type arguments
            final typeArgs = typeNode.typeArguments!.arguments;
            if (typeArgs.length >= 2) {
              result = _checkGenericMapType(
                  expressionValue, typeArgs[0], typeArgs[1]);
            } else {
              result = true; // Partial generic, just accept
            }
          }
          break;
        case 'Null':
          result = expressionValue == null;
          break;
        case 'Object':
          // Everything non-null is an Object?
          result = expressionValue != null;
          break;
        case 'dynamic': // 'is dynamic' is always true
        case 'void': // 'is void' is always false (or error?) - let's say false
          result = typeName == 'dynamic';
          break;
        default:
          try {
            final targetType = environment.get(typeName);

            if (targetType is BridgedClass) {
              if (expressionValue is BridgedInstance) {
                // Use the new helper method
                result = expressionValue.bridgedClass.isSubtypeOf(targetType);
              } else {
                // A non-instance value cannot be a subtype of a user-defined class
                result = false;
              }
            } else if (targetType is InterpretedClass) {
              if (expressionValue is InterpretedInstance) {
                // Use the new helper method
                result = expressionValue.klass.isSubtypeOf(targetType);
              } else {
                // A non-instance value cannot be a subtype of a user-defined class
                result = false;
              }
            } else if (targetType is NativeFunction &&
                targetType.call(this, []) is Type) {
              final object = targetType.call(this, []);

              return expressionValue.runtimeType == object;
            } else {
              throw RuntimeError(
                  "Type '$typeName' not found or is not a ${expressionValue.runtimeType}.");
            }
          } on RuntimeError catch (e) {
            // Propagate type lookup error
            // Wrap in InternalInterpreterException to be caught correctly
            throw InternalInterpreterException(
                RuntimeError("Type check failed: ${e.message}"));
          }
      }
    } else {
      // Handle FunctionType, etc., later if needed
      throw UnimplementedError(
          'Type check for ${typeNode.runtimeType} not implemented.');
    }

    // Handle negation (is!)
    if (node.notOperator != null) {
      return !result;
    } else {
      return result;
    }
  }

  @override
  Object? visitSetOrMapLiteral(SetOrMapLiteral node) {
    bool isMap;
    bool typeExplicit = false;

    // Check explicit type arguments first
    if (node.typeArguments != null &&
        node.typeArguments!.arguments.isNotEmpty) {
      isMap = node.typeArguments!.arguments.length == 2;
      typeExplicit = true;
      Logger.debug(
          "[SetOrMapLiteral] Determined type via explicit args: isMap = $isMap");
    } else {
      // No explicit types, infer from content
      isMap = false; // Default to Set if unsure initially
      bool onlySpreads = true;
      CollectionElement? firstEffectiveElement;

      for (final element in node.elements) {
        if (element is MapLiteralEntry) {
          isMap = true;
          onlySpreads = false;
          firstEffectiveElement = element;
          Logger.debug(
              "[SetOrMapLiteral] Determined isMap = true (found MapLiteralEntry).");
          break; // Found a map entry, definitely a map
        }
        if (element is! SpreadElement && firstEffectiveElement == null) {
          firstEffectiveElement = element;
          onlySpreads = false;
          // If it's an Expression, isMap remains false (it's a Set)
          if (element is Expression) {
            Logger.debug(
                "[SetOrMapLiteral] Determined isMap = false (found first non-spread Expression).");
          }
        }
        if (element is! SpreadElement) {
          onlySpreads = false;
        }
      }

      // Handle empty literal or spread-only literal
      if (!typeExplicit) {
        // Re-evaluate if type wasn't explicit
        if (node.elements.isEmpty) {
          isMap = true; // Empty literal defaults to Map
          Logger.debug(
              "[SetOrMapLiteral] Determined isMap = true (empty literal).");
        } else if (onlySpreads) {
          // Only spread elements, no explicit type args. Infer from first spread.
          Logger.debug(
              "[SetOrMapLiteral] Only spreads found. Inferring type from first spread element.");
          final firstSpread = node.elements.first as SpreadElement;
          final spreadValue = firstSpread.expression.accept<Object?>(this);
          // Check if the evaluated spread value is a Map or looks like one
          final bridgedInstance = toBridgedInstance(spreadValue);
          if (spreadValue is Map ||
              (bridgedInstance.$2 && bridgedInstance.$1?.nativeObject is Map)) {
            isMap = true;
            Logger.debug(
                "[SetOrMapLiteral]   First spread evaluated to Map. Setting isMap = true.");
          } else {
            isMap = false; // Assume Set otherwise
            Logger.debug(
                "[SetOrMapLiteral]   First spread did not evaluate to Map. Setting isMap = false.");
          }
        } else if (firstEffectiveElement is MapLiteralEntry) {
          isMap = true; // Confirmation if first non-spread was entry
        } else {
          isMap = false; // If first non-spread was Expression, it's a Set
        }
      }
    }

    // Create and populate the collection
    final Object collection = isMap ? <Object?, Object?>{} : <Object?>{};

    for (final element in node.elements) {
      try {
        _processCollectionElement(element, collection, isMap: isMap);
      } on RuntimeError catch (e) {
        final literalType = isMap ? "Map" : "Set";
        // Check if error already contains context to avoid duplication
        if (!e.message.contains('in $literalType literal')) {
          throw RuntimeError("${e.message} (in $literalType literal)");
        } else {
          rethrow; // Rethrow original error with context
        }
      }
    }

    // If this is a const collection, return an unmodifiable version
    if (node.constKeyword != null) {
      if (isMap) {
        return Map.unmodifiable(collection as Map<Object?, Object?>);
      } else {
        return Set.unmodifiable(collection as Set<Object?>);
      }
    }

    return collection;
  }

  // Resolve TypeAnnotation AST node to RuntimeType
  RuntimeType _resolveTypeAnnotation(TypeAnnotation? typeNode,
      {bool isAsync = false}) {
    return _resolveTypeAnnotationWithEnvironment(typeNode, environment,
        isAsync: isAsync);
  }

  // Resolve TypeAnnotation AST node to RuntimeType using a specific environment
  RuntimeType _resolveTypeAnnotationWithEnvironment(
      TypeAnnotation? typeNode, Environment env,
      {bool isAsync = false}) {
    if (typeNode == null) {
      return BridgedClass(nativeType: dynamic, name: 'dynamic');
    }
    if (typeNode is NamedType) {
      String typeName = isAsync
          ? typeNode
              .toSource()
              .replaceAll('?', '')
              .substringAfter('<')
              .substringBeforeLast('>')
          : typeNode.name.lexeme;
      if (typeName.contains('<') && typeName.contains('>')) {
        typeName = typeName.substring(0, typeName.indexOf('<'));
      }
      if (typeName == "void") {
        return BridgedClass(nativeType: VoidType, name: 'void');
      }
      Logger.debug("[ResolveType] Resolving NamedType: $typeName");
      try {
        final resolved = env.get(typeName);
        if (resolved is RuntimeType) {
          Logger.debug(
              "[ResolveType]   Resolved to RuntimeType: ${resolved.name}");
          return resolved;
        } else {
          throw RuntimeError(
              "Symbol '$typeName' resolved to non-type value: $resolved");
        }
      } on RuntimeError {
        // Handle special case: 'dynamic' type doesn't exist in environment usually
        if (typeName == 'dynamic') {
          Logger.debug("[ResolveType]   Resolved to dynamic (special case)");
          // Need a representation for dynamic. Using a placeholder for now.
          // Ideally, have a predefined DynamicRuntimeType() instance.
          return BridgedClass(
              nativeType: Object, name: 'dynamic'); // Corrected placeholder
        }
        throw RuntimeError("Type '$typeName' not found.");
      }
    } else {
      Logger.error(
          "[ResolveType] Unsupported TypeAnnotation type: ${typeNode.runtimeType}");
      throw UnimplementedError(
          "Type resolution for ${typeNode.runtimeType} not implemented yet.");
    }
  }

  @override
  Object? visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructorNameNode = node.constructorName.type;

    // Handle qualified types like `bool.fromEnvironment` where the analyzer creates a NamedType
    // with importPrefix="bool" and name="fromEnvironment"
    String constructorName;
    String? namedConstructorPart;

    // Check if this is a NamedType with an importPrefix (qualified name like bool.fromEnvironment)
    if (constructorNameNode.importPrefix != null) {
      // This is a case like `bool.fromEnvironment` where:
      // - importPrefix.name = "bool"
      // - name2 (or name) = "fromEnvironment"
      // We treat this as: className="bool", namedConstructor="fromEnvironment"
      constructorName = constructorNameNode.importPrefix!.name.lexeme;
      namedConstructorPart = constructorNameNode.name.lexeme;

      Logger.debug(
          "[InstanceCreation] Qualified type detected: '$constructorName.$namedConstructorPart'");
    } else {
      // Normal case: simple type name
      constructorName = constructorNameNode.name.lexeme;
      namedConstructorPart = node.constructorName.name
          ?.name; // Name of the named constructor (or null)

      Logger.debug(
          "[InstanceCreation] Creating instance of '$constructorName'${namedConstructorPart != null ? '.$namedConstructorPart' : ''}");
    }

    // Resolve the type
    Object? typeValue;
    try {
      typeValue = environment.get(constructorName);
    } on RuntimeError {
      throw RuntimeError(
          "Type '$constructorName' not found for instantiation.");
    }

    // Check the resolved type
    if (typeValue is InterpretedClass) {
      // CASE 1: InterpretedClass
      final klass = typeValue;
      Logger.debug(
          "[InstanceCreation]   Type resolved to InterpretedClass: '$constructorName'");

      // Check if the class is abstract
      if (klass.isAbstract) {
        throw RuntimeError(
            "Cannot instantiate abstract class '$constructorName'.");
      }

      // Evaluate the arguments
      final evaluationResult = _evaluateArgumentsAsync(node.argumentList);
      if (evaluationResult is AsyncSuspensionRequest) {
        return evaluationResult; // Propagate suspension
      }
      final (positionalArgs, namedArgs) =
          evaluationResult as (List<Object?>, Map<String, Object?>);

      // Find and call the constructor (interpreted)
      final constructorLookupName =
          namedConstructorPart ?? ''; // Use '' for default
      final constructor = klass.findConstructor(constructorLookupName);

      if (constructor == null) {
        throw RuntimeError(
            "Class '$constructorName' does not have a constructor named '$constructorLookupName'.");
      }

      try {
        // Evaluate the type arguments
        List<RuntimeType>? evaluatedTypeArguments;
        final typeArgsNode = node.constructorName.type.typeArguments;
        if (typeArgsNode != null) {
          evaluatedTypeArguments = typeArgsNode.arguments
              .map((typeNode) => _resolveTypeAnnotation(typeNode))
              .toList();
        }

        // Handle factory constructors differently from regular constructors
        if (constructor.isFactory) {
          // Factory constructors don't need a pre-created instance
          // They are responsible for creating and returning their own instance
          Logger.debug(
              "[InstanceCreation] Calling factory constructor '$constructorLookupName'");

          // Call the factory constructor directly without creating an instance first
          // The factory will create its own instance and return it
          final result = constructor.call(
              this, positionalArgs, namedArgs, evaluatedTypeArguments);

          // Factory constructors should return an instance of the expected type
          if (result is InterpretedInstance && result.klass == klass) {
            return result;
          } else if (result is InterpretedInstance) {
            throw RuntimeError(
                "Factory constructor '$constructorLookupName' returned an instance of '${result.klass.name}' but expected '$constructorName'.");
          } else {
            throw RuntimeError(
                "Factory constructor '$constructorLookupName' must return an instance, but returned ${result?.runtimeType}.");
          }
        } else {
          // Regular constructors: create instance first, then call constructor
          Logger.debug(
              "[InstanceCreation] Calling regular constructor '$constructorLookupName'");

          // Create and initialize the fields, passing the type arguments
          final instance =
              klass.createAndInitializeInstance(this, evaluatedTypeArguments);
          // Bind 'this' and call the constructor logic
          final boundConstructor = constructor.bind(instance);
          boundConstructor.call(
              this, positionalArgs, namedArgs, evaluatedTypeArguments);
          // The constructor call returns the instance
          return instance;
        }
      } on ReturnException catch (e) {
        // Handle return exceptions (applies to both factory and regular constructors)
        if (constructor.isFactory) {
          // For factory constructors, the return value is the actual result
          return e.value;
        } else {
          // For regular constructors, check if returned value is valid
          if (e.value != null && e.value is InterpretedInstance) {
            final instance = e.value as InterpretedInstance; // Explicit cast
            if (instance.klass == klass) {
              // Check on the casted instance
              return instance;
            }
          }
          // If the condition fails (null, not InterpretedInstance, or wrong class)
          throw RuntimeError(
              "Constructor return value error for '$constructorName'.");
        }
      } on RuntimeError catch (e) {
        // Simplified error message
        throw RuntimeError(
            "Constructor execution error for '$constructorName.': ${e.message}");
      }
    } else if (typeValue is BridgedClass) {
      // CASE 2: BridgedClass
      final bridgedClass = typeValue;
      Logger.debug(
          "[InstanceCreation]   Type resolved to BridgedClass: '$constructorName'");

      // Check if this is actually a static method call disguised as a constructor call
      // This happens with cases like `bool.fromEnvironment(...)` where fromEnvironment is a static method
      if (namedConstructorPart != null) {
        final staticMethodAdapter =
            bridgedClass.findStaticMethodAdapter(namedConstructorPart);
        if (staticMethodAdapter != null) {
          Logger.debug(
              "[InstanceCreation] Found static method '$namedConstructorPart' on bridged class '$constructorName'");

          final (positionalArgs, namedArgs) =
              _evaluateArguments(node.argumentList);

          try {
            // Call the static method adapter
            final result = staticMethodAdapter(this, positionalArgs, namedArgs);

            // Static methods return values directly (often native values like bool, String, etc.)
            Logger.debug(
                "[InstanceCreation] Static method returned: ${result?.runtimeType}");

            // Return the result as-is. Static methods may return native values or BridgedInstances
            return result;
          } catch (e) {
            Logger.error(
                "[InstanceCreation] Error calling static method '$namedConstructorPart' on '$constructorName': $e");
            throw RuntimeError(
                "Error during static method call '$constructorName.$namedConstructorPart': $e");
          }
        }
      }

      final (positionalArgs, namedArgs) = _evaluateArguments(node.argumentList);

      // Find the constructor adapter (bridged)
      final constructorLookupName =
          namedConstructorPart ?? ''; // Use '' if null
      final constructorAdapter =
          bridgedClass.findConstructorAdapter(constructorLookupName);

      if (constructorAdapter == null) {
        throw RuntimeError(
            "Bridged class '$constructorName' does not have a registered constructor named '$constructorLookupName'. Check bridge definition.");
      }

      // Call the constructor adapter
      try {
        // The adapter is responsible for:
        // 1. Converting the interpreted positionalArgs/namedArgs to native types.
        // 2. Calling the actual native constructor.
        // 3. Returning the created native object.
        final nativeObject =
            constructorAdapter(this, positionalArgs, namedArgs);

        // Check if the adapter returned a value (it should)
        if (nativeObject == null) {
          throw RuntimeError(
              "Bridged constructor adapter for '\$constructorName.$constructorLookupName' returned null unexpectedly.");
        }

        // Wrap the native object in BridgedInstance
        final bridgedInstance = BridgedInstance(bridgedClass, nativeObject);
        Logger.debug(
            "[InstanceCreation]   Successfully created BridgedInstance wrapping native object: \${nativeObject.runtimeType}");
        return bridgedInstance;
      } on RuntimeError catch (e) {
        // If the adapter itself raises a RuntimeError (e.g. conversion failure)
        throw RuntimeError(
            "Error during bridged constructor '$constructorLookupName' for class '$constructorName': ${e.message}");
      } catch (e) {
        // Catch potential native exceptions raised by the adapter or the native constructor
        Logger.error(
            "[InstanceCreation] Native exception during bridged constructor '$constructorName.$constructorLookupName': \$e\\n\$s");
        // Encapsulate the native error in a RuntimeError for propagation
        throw RuntimeError(
            "Native error during bridged constructor '$constructorLookupName' for class '$constructorName': \$e");
      }
    } else {
      // CASE 3: The resolved type is neither InterpretedClass nor BridgedClass
      throw RuntimeError(
          "Identifier '$constructorName' resolved to ${typeValue?.runtimeType}, which is not a class type that can be instantiated.");
    }
  }

  (List<Object?>, Map<String, Object?>) _evaluateArguments(
      ArgumentList argumentList) {
    List<Object?> positionalArgs = [];
    Map<String, Object?> namedArgs = {};
    bool namedArgsEncountered = false;

    for (final arg in argumentList.arguments) {
      if (arg is NamedExpression) {
        namedArgsEncountered = true;
        final name = arg.name.label.name;
        final value = arg.expression.accept<Object?>(this);

        // Check for async suspension in named arguments
        if (value is AsyncSuspensionRequest) {
          return value as dynamic; // Propagate suspension request
        }

        if (namedArgs.containsKey(name)) {
          throw RuntimeError("Named argument '$name' provided more than once.");
        }
        final bridgedInstance = toBridgedInstance(value);
        namedArgs[name] = _bridgeInterpreterValueToNative(
            bridgedInstance.$2 ? bridgedInstance.$1!.nativeObject : value);
      } else {
        if (namedArgsEncountered) {
          throw RuntimeError(
              "Positional arguments cannot follow named arguments.");
        }
        final a = arg.accept<Object?>(this);

        // Check for async suspension in positional arguments
        if (a is AsyncSuspensionRequest) {
          return a as dynamic; // Propagate suspension request
        }

        final bridgedInstance = toBridgedInstance(a);
        positionalArgs.add(_bridgeInterpreterValueToNative(
            bridgedInstance.$2 ? bridgedInstance.$1!.nativeObject : a));
      }
    }

    return (positionalArgs, namedArgs);
  }

  Object? _bridgeInterpreterValueToNative(Object? interpreterValue) {
    if (interpreterValue is BridgedInstance) {
      return interpreterValue.nativeObject;
    }

    if (interpreterValue is BridgedEnumValue) {
      return interpreterValue.nativeValue;
    }

    return interpreterValue;
  }

  /// Evaluates arguments for async function calls, handling await expressions.
  /// Returns either (List&lt;Object?&gt;, Map&lt;String, Object?&gt;) or AsyncSuspensionRequest.
  Object? _evaluateArgumentsAsync(ArgumentList argumentList) {
    List<Object?> positionalArgs = [];
    Map<String, Object?> namedArgs = {};
    bool namedArgsEncountered = false;

    for (final arg in argumentList.arguments) {
      if (arg is NamedExpression) {
        namedArgsEncountered = true;
        final name = arg.name.label.name;
        final value = arg.expression.accept<Object?>(this);

        // Check for async suspension in named arguments
        if (value is AsyncSuspensionRequest) {
          Logger.debug(
              "[_evaluateArgumentsAsync] Async suspension in named argument '$name'");
          return value; // Propagate suspension request
        }

        if (namedArgs.containsKey(name)) {
          throw RuntimeError("Named argument '$name' provided more than once.");
        }
        final bridgedInstance = toBridgedInstance(value);
        namedArgs[name] = _bridgeInterpreterValueToNative(
            bridgedInstance.$2 ? bridgedInstance.$1!.nativeObject : value);
      } else {
        if (namedArgsEncountered) {
          throw RuntimeError(
              "Positional arguments cannot follow named arguments.");
        }
        final a = arg.accept<Object?>(this);

        // Check for async suspension in positional arguments
        if (a is AsyncSuspensionRequest) {
          Logger.debug(
              "[_evaluateArgumentsAsync] Async suspension in positional argument");
          return a; // Propagate suspension request
        }

        final bridgedInstance = toBridgedInstance(a);
        positionalArgs.add(_bridgeInterpreterValueToNative(
            bridgedInstance.$2 ? bridgedInstance.$1!.nativeObject : a));
      }
    }

    Logger.debug(
        "[_evaluateArgumentsAsync] All arguments evaluated successfully: ${positionalArgs.length} positional, ${namedArgs.length} named");
    return (positionalArgs, namedArgs);
  }

  // Add FunctionExpressionInvocation handler
  @override
  Object? visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    // 1. Evaluate the function expression itself.
    // This should result in a Callable (like InterpretedFunction or NativeFunction).
    final calleeValue = node.function.accept<Object?>(this);

    // 2. Evaluate arguments (shared logic).
    final (positionalArgs, namedArgs) = _evaluateArguments(node.argumentList);

    // 3. Evaluate type arguments (shared logic).
    List<RuntimeType>? evaluatedTypeArguments;
    final typeArgsNode = node.typeArguments;
    if (typeArgsNode != null) {
      evaluatedTypeArguments = typeArgsNode.arguments
          .map((typeNode) => _resolveTypeAnnotation(typeNode))
          .toList();
    }

    // 4. Check if it's actually callable (standard callable).
    if (calleeValue is Callable) {
      // 5. Perform the standard call.
      try {
        return calleeValue.call(
            this, positionalArgs, namedArgs, evaluatedTypeArguments);
      } on ReturnException catch (e) {
        return e.value;
      }
    } else {
      // Try Extension 'call' Method
      const methodName = 'call';
      try {
        final extensionMethod =
            environment.findExtensionMember(calleeValue, methodName);

        if (extensionMethod is InterpretedExtensionMethod &&
            !extensionMethod
                .isOperator && // Ensure it's a regular method named 'call'
            !extensionMethod.isGetter &&
            !extensionMethod.isSetter) {
          Logger.debug(
              "[FuncExprInvoke] Found extension method 'call' for type ${calleeValue?.runtimeType}. Calling...");

          // Prepare arguments for extension method:
          // First arg is the receiver (the object being called)
          final extensionPositionalArgs = [calleeValue, ...positionalArgs];

          try {
            // Call the extension method
            return extensionMethod.call(this, extensionPositionalArgs,
                namedArgs, evaluatedTypeArguments);
          } on ReturnException catch (e) {
            return e.value;
          } catch (e) {
            throw RuntimeError("Error executing extension method 'call': $e");
          }
        }
        Logger.debug(
            "[FuncExprInvoke] No suitable extension method 'call' found for type ${calleeValue?.runtimeType}.");
      } on RuntimeError catch (findError) {
        Logger.debug(
            "[FuncExprInvoke] No extension member 'call' found for type ${calleeValue?.runtimeType}. Error: ${findError.message}");
        // Fall through to the final standard error below.
      }

      // Original Error: The expression evaluated did not yield a callable function or an object with a callable 'call' extension.
      throw RuntimeError(
          "Attempted to call something that is not a function and has no 'call' extension method. Got type: ${calleeValue?.runtimeType}");
    }
  }

  @override
  Object? visitConstructorReference(ConstructorReference node) {
    final typeNode = node.constructorName.type;
    final constructorId = node.constructorName.name; // Null for default
    final constructorLookupName = constructorId?.name ?? '';

    // Resolve the class type
    final className = typeNode.name.lexeme;
    Object? classValue;
    try {
      classValue = environment.get(className);
    } on RuntimeError {
      throw RuntimeError(
          "Type '$className' not found for constructor reference.");
    }

    if (classValue is InterpretedClass) {
      // Find the InterpretedFunction for the constructor
      final constructorFunction =
          classValue.findConstructor(constructorLookupName);
      if (constructorFunction == null) {
        throw RuntimeError(
            "Constructor '$constructorLookupName' not found for class '$className'.");
      }
      // Return the constructor function itself as the tear-off value
      return constructorFunction;
    } else if (classValue is BridgedClass) {
      // Find the adapter (just to check existence)
      final adapter = classValue.findConstructorAdapter(constructorLookupName);
      if (adapter == null) {
        throw RuntimeError(
            "Bridged constructor '$constructorLookupName' not found for class '$className'.");
      }

      throw UnimplementedError(
          "Tear-off for bridged constructors ('$className.$constructorLookupName') is not yet supported.");
    } else {
      throw RuntimeError(
          "Identifier '$className' did not resolve to a class type.");
    }
  }

  @override
  Object? visitFunctionReference(FunctionReference node) {
    // The actual logic is in visiting the underlying function expression
    // (Identifier, PropertyAccess, ConstructorReference, etc.)
    // which should return the Callable/Function object itself.
    return node.function.accept<Object?>(this);
  }

  @override
  Object? visitEmptyStatement(EmptyStatement node) {
    // An empty statement does nothing.
    return null;
  }

  @override
  Object? visitSwitchStatement(SwitchStatement node) {
    final switchValue = node.expression.accept<Object?>(this);
    final switchEnvironment = Environment(enclosing: environment);
    final previousEnvironment = environment;
    environment = switchEnvironment;

    bool matched = false; // Has any case matched the switchValue?
    bool execute =
        false; // Should we execute statements in the current/next section?

    try {
      for (final member in node.members) {
        List<Statement> statementsToExecute = [];

        if (member is SwitchCase) {
          if (!matched) {
            final caseValue = member.expression.accept<Object?>(this);
            Logger.debug(
                "[Switch] Checking legacy case value: $caseValue against $switchValue");
            if (switchValue == caseValue) {
              matched = true;
              execute = true;
              Logger.debug("[Switch] Matched legacy case: $caseValue");
            }
          }
          statementsToExecute = member.statements;
        } else if (member is SwitchPatternCase) {
          // Try explicit cast to potentially help the linter
          final pattern = member.guardedPattern.pattern;
          if (pattern is ConstantPattern) {
            // This handles 'case <constant>:'
            if (!matched) {
              // Access expression from the ConstantPattern
              final caseValue = pattern.expression.accept<Object?>(this);
              Logger.debug(
                  "[Switch] Checking pattern case value: $caseValue against $switchValue");
              if (switchValue == caseValue) {
                matched = true;
                execute = true; // Start executing
                Logger.debug("[Switch] Matched pattern case: $caseValue");
              }
            }
            statementsToExecute = member.statements;
          } else {
            // Handle other pattern types using our improved _matchAndBind function
            if (!matched) {
              // Create a temporary environment for pattern matching in switch
              final tempEnvironment = Environment(enclosing: environment);
              try {
                _matchAndBind(pattern, switchValue, tempEnvironment);
                // If we get here, the pattern matched
                matched = true;
                execute = true;
                // Copy any bound variables to the current environment
                // In a full implementation, we might want to handle variable scoping more carefully
                for (final name in tempEnvironment.values.keys) {
                  try {
                    final value = tempEnvironment.get(name);
                    environment.define(name, value);
                  } catch (e) {
                    // Variable might already exist or other issue, ignore for now
                  }
                }
                Logger.debug(
                    "[Switch] Matched pattern case: ${pattern.runtimeType}");
              } on PatternMatchException catch (e) {
                Logger.debug(
                    "[Switch] Pattern ${pattern.runtimeType} did not match: ${e.message}");
                // Pattern didn't match, continue to next case
              }
            }
            statementsToExecute = member.statements;
          }
        } else if (member is SwitchDefault) {
          Logger.debug("[Switch] Reached default case.");
          if (!matched || execute) {
            // Execute default if no match OR fallthrough
            execute = true;
          }
          statementsToExecute = member.statements;
        } else {
          throw StateError('Unknown switch member type: ${member.runtimeType}');
        }

        // Execute statements if needed (either matched this round or fell through)
        if (execute) {
          Logger.debug(
              "[Switch] Executing statements for matched/fallthrough/default...");
          try {
            for (final statement in statementsToExecute) {
              statement.accept<Object?>(this);
            }
            // Fall-through continues if no break
          } on BreakException catch (e) {
            Logger.debug(
                "[Switch] Caught BreakException (label: ${e.label}) with current labels: $_currentStatementLabels");
            if (e.label == null || _currentStatementLabels.contains(e.label)) {
              // Unlabeled break OR labeled break targeting this switch.
              Logger.debug("[Switch] Breaking switch.");
              execute = false; // Stop execution after this block
              break; // Exit the loop over members
            } else {
              // Labeled break targeting an outer construct.
              Logger.debug("[Switch] Rethrowing outer break...");
              rethrow;
            }
          } on ContinueException {
            // 'continue' without a label is invalid here according to Dart spec
            // Analyzer should catch 'continue L;' if L doesn't label a loop/switch member
            throw RuntimeError(
                "'continue' is not valid inside a switch case/default block without a loop target.");
          }
        }
      }
    } finally {
      environment = previousEnvironment;
    }

    return null; // Switch statements don't produce a value.
  }

  // Await Expression (Partial Support)
  @override
  Object? visitAwaitExpression(AwaitExpression node) {
    // Check for async state machine: do we have an async state?
    if (currentAsyncState == null) {
      // This shouldn't happen if the call is properly orchestrated
      throw StateError(
          "Internal error: 'await' encountered outside of a managed async execution state.");
    }

    // Initial check: Are we in an async function?
    if (!currentAsyncState!.function.isAsync) {
      throw RuntimeError("'await' can only be used inside an async function.");
    }

    // Check if we are in invocation resumption mode
    if (currentAsyncState!.isInvocationResumptionMode) {
      Logger.debug(
          "[AwaitExpression] In invocation resumption mode, returning last await result: ${currentAsyncState!.lastAwaitResult}");
      return currentAsyncState!.lastAwaitResult;
    }

    Logger.debug("[AwaitExpression] Evaluating expression for await...");
    final expressionValue = node.expression.accept<Object?>(this);

    // HANDLING NESTED SUSPENSIONS
    if (expressionValue is AsyncSuspensionRequest) {
      // If the awaited expression itself is an await, just propagate its suspension request.
      Logger.debug(
          "[AwaitExpression] Awaited expression itself suspended. Propagating AsyncSuspensionRequest.");
      return expressionValue;
    }

    if (expressionValue is Future) {
      Logger.debug(
          "[AwaitExpression] Expression evaluated to a Future. Returning AsyncSuspensionRequest.");
      final future = expressionValue as Future<Object?>;

      // CRUCIAL: Return the suspension request with the future and the current state.
      // The async state machine will use this information.
      // Note: currentAsyncState cannot be null here because of the previous check.
      return AsyncSuspensionRequest(future, currentAsyncState!);
    } else {
      // The argument to 'await' MUST be a Future.
      throw RuntimeError(
          "The argument to 'await' must be a Future, but received type: ${expressionValue?.runtimeType}");
    }
  }

  // =======================================================================
  // Pattern Matching Helper
  // =======================================================================

  /// Attempts to match the [pattern] against the [value].
  /// If successful, binds any variables declared in the pattern within the [environment].
  /// Throws [PatternMatchException] on failure.
  void _matchAndBind(
      DartPattern pattern, Object? value, Environment environment) {
    Logger.debug(
        "[_matchAndBind] Matching pattern ${pattern.runtimeType} against value ${value?.runtimeType}");

    if (pattern is DeclaredVariablePattern) {
      // Handles: var x, final T x, int x
      final name = pattern.name.lexeme;
      if (name == '_') {
        // Wildcard name in declaration: match succeeds, no binding
        Logger.debug("[_matchAndBind] Wildcard (declared) match success.");
        return;
      }
      environment.define(name, value);
      Logger.debug("[_matchAndBind] Bound variable '$name' = $value");
    } else if (pattern is WildcardPattern) {
      // Handles: _ when used as a standalone sub-pattern
      Logger.debug("[_matchAndBind] Wildcard (sub-pattern) match success.");
      return; // Match succeeds, no binding
    } else if (pattern is AssignedVariablePattern) {
      // Handles assignment patterns like: (a, _) = record;
      final name = pattern.name.lexeme;
      if (name == '_') {
        // Wildcard name in assignment: match succeeds, no binding
        Logger.debug("[_matchAndBind] Wildcard (assigned) match success.");
        return;
      }
      try {
        environment.assign(name, value);
        Logger.debug("[_matchAndBind] Assigned variable '$name' = $value");
      } on RuntimeError catch (e) {
        // Convert assignment errors (e.g., variable not defined) to PatternMatchException
        throw PatternMatchException(
            "Failed to assign pattern variable '$name': ${e.message}");
      }
    } else if (pattern is ConstantPattern) {
      // Handles: case 1:, case "abc":, case MyClass.constant:
      // Evaluate the constant expression within the pattern
      final patternValue = pattern.expression.accept<Object?>(this);
      // Compare the switch value against the evaluated pattern constant
      // Use simple equality check for now.
      if (value != patternValue) {
        throw PatternMatchException(
            "Constant pattern value $patternValue does not match switch value $value");
      }
      Logger.debug(
          "[_matchAndBind] Constant pattern matched: $value == $patternValue");
      // No binding needed for constant patterns
    } else if (pattern is ListPattern) {
      // Handles: [p1, p2, ...], including rest elements like [p1, ...rest]
      if (value is! List) {
        throw PatternMatchException(
            "Expected a List, but got ${value?.runtimeType}");
      }

      // Check if there's a rest element and handle accordingly
      final restElementIndex =
          pattern.elements.indexWhere((e) => e is RestPatternElement);

      if (restElementIndex == -1) {
        // No rest element: exact length match required
        if (pattern.elements.length != value.length) {
          throw PatternMatchException(
              "List pattern expected ${pattern.elements.length} elements, but List has ${value.length}.");
        }

        // Match subpatterns recursively
        for (int i = 0; i < pattern.elements.length; i++) {
          final element = pattern.elements[i];
          final subValue = value[i];

          // Extract the actual pattern from the element wrapper
          DartPattern subPattern;
          if (element is DartPattern) {
            subPattern = element;
          } else {
            throw StateError(
                "Unexpected ListPatternElement type: ${element.runtimeType}");
          }

          Logger.debug(
              "[_matchAndBind]   Matching list element $i: ${subPattern.runtimeType} against ${subValue?.runtimeType}");
          _matchAndBind(subPattern, subValue, environment);
        }
      } else {
        // Has rest element: more complex matching
        final RestPatternElement restElement =
            pattern.elements[restElementIndex] as RestPatternElement;
        final beforeRestCount = restElementIndex;
        final afterRestCount = pattern.elements.length - restElementIndex - 1;
        final minRequiredLength = beforeRestCount + afterRestCount;

        if (value.length < minRequiredLength) {
          throw PatternMatchException(
              "List pattern expected at least $minRequiredLength elements, but List has ${value.length}.");
        }

        // Match elements before rest
        for (int i = 0; i < beforeRestCount; i++) {
          final element = pattern.elements[i];
          final subValue = value[i];

          DartPattern subPattern;
          if (element is DartPattern) {
            subPattern = element;
          } else {
            throw StateError(
                "Unexpected ListPatternElement type before rest: ${element.runtimeType}");
          }

          Logger.debug(
              "[_matchAndBind]   Matching list element $i (before rest): ${subPattern.runtimeType} against ${subValue?.runtimeType}");
          _matchAndBind(subPattern, subValue, environment);
        }

        // Handle rest element
        final restStartIndex = beforeRestCount;
        final restEndIndex = value.length - afterRestCount;
        final restValues = value.sublist(restStartIndex, restEndIndex);

        if (restElement.pattern != null) {
          // Rest element has a pattern (e.g., ...rest), bind the sublist
          Logger.debug(
              "[_matchAndBind]   Matching rest element: ${restElement.pattern!.runtimeType} against List of ${restValues.length} elements");
          _matchAndBind(restElement.pattern!, restValues, environment);
        }
        // If restElement.pattern is null, it's just "..." (anonymous rest), no binding needed

        // Match elements after rest
        for (int i = 0; i < afterRestCount; i++) {
          final patternIndex = restElementIndex + 1 + i;
          final valueIndex = value.length - afterRestCount + i;
          final element = pattern.elements[patternIndex];
          final subValue = value[valueIndex];

          DartPattern subPattern;
          if (element is DartPattern) {
            subPattern = element;
          } else {
            throw StateError(
                "Unexpected ListPatternElement type after rest: ${element.runtimeType}");
          }

          Logger.debug(
              "[_matchAndBind]   Matching list element $valueIndex (after rest): ${subPattern.runtimeType} against ${subValue?.runtimeType}");
          _matchAndBind(subPattern, subValue, environment);
        }
      }
      Logger.debug("[_matchAndBind] List pattern matched successfully.");
    } else if (pattern is MapPattern) {
      // Handles: {'key': p1, 'key2': p2, ...}, including rest elements like {'key': p1, ...rest}
      if (value is! Map) {
        throw PatternMatchException(
            "Expected a Map, but got ${value?.runtimeType}");
      }

      final Set<Object?> matchedKeys = {};

      // Match regular entries first
      for (int i = 0; i < pattern.elements.length; i++) {
        final element = pattern.elements[i];

        if (element is MapPatternEntry) {
          final keyPatternExpr = element.key;
          final valuePattern = element.value;

          final keyToLookup = keyPatternExpr.accept<Object?>(this);

          if (!value.containsKey(keyToLookup)) {
            throw PatternMatchException(
                "Map pattern key '$keyToLookup' not found in the map.");
          }

          final subValue = value[keyToLookup];
          Logger.debug(
              "[_matchAndBind]   Matching map entry '$keyToLookup': ${valuePattern.runtimeType} against ${subValue?.runtimeType}");
          _matchAndBind(valuePattern, subValue, environment);
          matchedKeys.add(keyToLookup);
        } else if (element is RestPatternElement) {
          // Handle rest element
          final remainingEntries = <Object?, Object?>{};
          for (final entry in value.entries) {
            if (!matchedKeys.contains(entry.key)) {
              remainingEntries[entry.key] = entry.value;
            }
          }

          if (element.pattern != null) {
            // Rest element has a pattern (e.g., ...rest), bind the remaining map
            Logger.debug(
                "[_matchAndBind]   Matching rest element: ${element.pattern!.runtimeType} against Map of ${remainingEntries.length} entries");
            _matchAndBind(element.pattern!, remainingEntries, environment);
          }
          // If element.pattern is null, it's just "..." (anonymous rest), no binding needed
        } else {
          throw StateError(
              "Unexpected MapPatternElement type: ${element.runtimeType}");
        }
      }

      Logger.debug("[_matchAndBind] Map pattern matched successfully.");
    } else if (pattern is RecordPattern) {
      Logger.debug(
          '[_matchAndBind] Matching pattern ${pattern.runtimeType} against value ${value.runtimeType}');
      if (value is! InterpretedRecord) {
        Logger.debug(
            'DEBUG [_matchAndBind] Mismatch: Value is not an InterpretedRecord.');
        // Failure case handled by throwing or returning normally if not exhaustive
        // Depending on context (declaration vs refutable)
        // For now, let's assume declaration context (must match or throw)
        throw PatternMatchException(
            'Expected a Record, but got ${value?.runtimeType}'); // Corrected message
      }

      final positionalPatternFields =
          pattern.fields.where((f) => f.name == null).toList();
      final namedPatternFieldsNodes =
          pattern.fields.where((f) => f.name != null).toList();

      Logger.debug(
          '[_matchAndBind]   Pattern positional fields count: ${positionalPatternFields.length}');
      Logger.debug(
          '[_matchAndBind]   Value positional fields count: ${value.positionalFields.length}');
      Logger.debug(
          '[_matchAndBind]   Pattern named fields count: ${namedPatternFieldsNodes.length}');
      Logger.debug(
          '[_matchAndBind]   Value named fields count: ${value.namedFields.length}');

      // Check positional fields count FIRST
      if (positionalPatternFields.length > value.positionalFields.length) {
        // Adjusted error message to match test expectation
        throw RuntimeError(
            'Pattern match failed: Record pattern expected at least ${positionalPatternFields.length} positional fields, but Record only has ${value.positionalFields.length}.');
      }

      // Match positional fields
      for (int i = 0; i < positionalPatternFields.length; i++) {
        final fieldPatternNode = positionalPatternFields[i];
        final fieldValue = value.positionalFields[i];
        Logger.debug(
            'DEBUG [_matchAndBind]   Matching record positional field $i: ${fieldPatternNode.runtimeType} against ${fieldValue?.runtimeType ?? 'null'}');

        // Assume fieldPatternNode IS a RecordPatternField because it came from pattern.fields
        // We need the actual pattern nested within the field.
        // Directly access .pattern assuming the node type is correct (dynamic access if needed)
        final fieldPattern = (fieldPatternNode as dynamic).pattern;

        // Recursive call, rely on exceptions for failure
        _matchAndBind(fieldPattern, fieldValue, environment);
        Logger.debug(
            'DEBUG [_matchAndBind]     Positional field $i match success.');
      }

      // Match named fields
      for (final fieldNode in namedPatternFieldsNodes) {
        // We know fieldNode has name != null here
        // Assume fieldNode is RecordPatternField based on filtering
        final fieldPatternNode = fieldNode;

        // Use the corrected access path
        final fieldName = fieldPatternNode.name?.name?.lexeme;
        if (fieldName == null) {
          // This case implies fieldPatternNode.name was null, which contradicts the filter where((f) => f.name != null)
          // Or fieldPatternNode.name.name was null, which is unlikely for a SimpleIdentifier.
          throw StateError(
              'Internal error: Named field detected but name lexeme is null.');
        }

        Logger.debug(
            'DEBUG [_matchAndBind]   Matching record named field \'$fieldName\': ${fieldPatternNode.pattern.runtimeType} against value type ${value.namedFields[fieldName]?.runtimeType ?? 'null'}');

        if (!value.namedFields.containsKey(fieldName)) {
          throw PatternMatchException(
              'Record pattern named field \'$fieldName\' not found in the record.');
        }
        final fieldValue = value.namedFields[fieldName];

        // Recursive match on the pattern inside the field
        final fieldSubPattern = (fieldPatternNode as dynamic).pattern;
        _matchAndBind(fieldSubPattern, fieldValue, environment);
        Logger.debug(
            'DEBUG [_matchAndBind]     Named field \'$fieldName\' match success.');
      }

      Logger.debug('[_matchAndBind] Record pattern matched successfully.');
      // Success: function completes normally
    } else if (pattern is ObjectPattern) {
      // Handles: ClassName(field1: pattern1, field2: pattern2)
      Logger.debug(
          '[_matchAndBind] Matching object pattern ${pattern.type.name.lexeme} against value ${value?.runtimeType}');

      // Get the expected type name
      final expectedTypeName = pattern.type.name.lexeme;

      // Check if the value is of the expected type
      // For now, we'll do basic runtime type checking
      // In a full implementation, this would involve more sophisticated type checking

      // Try to match common Dart types and interpreted classes
      bool typeMatches = false;
      String actualTypeName = value?.runtimeType.toString() ?? 'null';

      // Handle common type aliases and matches
      if (expectedTypeName == 'int' && value is int) {
        typeMatches = true;
      } else if (expectedTypeName == 'double' && value is double) {
        typeMatches = true;
      } else if (expectedTypeName == 'num' && value is num) {
        typeMatches = true;
      } else if (expectedTypeName == 'String' && value is String) {
        typeMatches = true;
      } else if (expectedTypeName == 'bool' && value is bool) {
        typeMatches = true;
      } else if (expectedTypeName == 'List' && value is List) {
        typeMatches = true;
      } else if (expectedTypeName == 'Map' && value is Map) {
        typeMatches = true;
      } else if (expectedTypeName == 'Set' && value is Set) {
        typeMatches = true;
      } else if (value != null && actualTypeName.endsWith(expectedTypeName)) {
        // Basic heuristic: if the actual type name ends with expected type name
        typeMatches = true;
      } else {
        // Check if the value has an interpreted class that matches
        // This is a simplified check - a full implementation would be more robust
        try {
          // Try to look up the expected type in the environment
          final expectedType = environment.get(expectedTypeName);
          if (expectedType is RuntimeType) {
            // In a full implementation, we'd check if value is an instance of expectedType
            typeMatches =
                true; // For now, assume it matches if we found the type
          }
        } catch (e) {
          // Type not found in environment, use basic matching
        }
      }

      if (!typeMatches) {
        throw PatternMatchException(
            "Object pattern expected type '$expectedTypeName', but got '${value?.runtimeType}'");
      }

      // Match each field pattern
      for (final field in pattern.fields) {
        final PatternFieldName? fieldName = field.name;
        final DartPattern fieldPattern = field.pattern;

        if (fieldName == null) {
          throw PatternMatchException("Object pattern field must have a name");
        }

        // Get the field name string
        String fieldNameStr;
        if (fieldName.name != null) {
          fieldNameStr = fieldName.name!.lexeme;
        } else {
          throw PatternMatchException(
              "Object pattern field name is not a simple identifier");
        }

        // Extract the field value from the object
        Object? fieldValue;

        // For basic types, we can't really access fields, so this is limited
        // In a full implementation, this would use reflection or interpreter class instances
        if (value is Map && value.containsKey(fieldNameStr)) {
          // If it's a map, treat field access as key access (common pattern)
          fieldValue = value[fieldNameStr];
        } else {
          // For now, we'll assume field access is not supported for most types
          // A full implementation would use reflection or interpreter-managed objects
          throw PatternMatchException(
              "Object pattern field access '$fieldNameStr' is not yet fully supported for type '${value?.runtimeType}'");
        }

        Logger.debug(
            "[_matchAndBind]   Matching object field '$fieldNameStr': ${fieldPattern.runtimeType} against ${fieldValue?.runtimeType}");
        _matchAndBind(fieldPattern, fieldValue, environment);
      }

      Logger.debug("[_matchAndBind] Object pattern matched successfully.");
    } else {
      throw UnimplementedError(
          "Pattern type not yet supported in _matchAndBind: ${pattern.runtimeType}");
    }
  }

  @override
  Object? visitRecordLiteral(RecordLiteral node) {
    final positional = <Object?>[];
    final named = <String, Object?>{};

    for (final field in node.fields) {
      if (field is NamedExpression) {
        final name = field.name.label.name;
        final value = field.expression.accept<Object?>(this);
        if (named.containsKey(name)) {
          throw RuntimeError(
              "Record literal field '$name' specified more than once.");
        }
        named[name] = value;
      } else {
        // Positional field: expression
        if (named.isNotEmpty) {
          // As per Dart spec, positional fields must come before named fields
          throw RuntimeError(
              "Positional fields must come before named fields in record literal.");
        }
        positional.add(field.accept<Object?>(this));
      }
    }
    Logger.debug("[visitRecordLiteral] Created record: ($positional, $named)");
    return InterpretedRecord(positional, named);
  }

  @override
  Object? visitPatternAssignment(PatternAssignment node) {
    // 1. Evaluate the right-hand side expression
    final rhsValue = node.expression.accept<Object?>(this);

    // 2. Match the pattern against the value and bind variables
    try {
      _matchAndBind(node.pattern, rhsValue, environment);
    } on PatternMatchException catch (e) {
      // Convert pattern match failures into standard RuntimeErrors for assignment expressions
      throw RuntimeError("Pattern assignment failed: ${e.message}");
    } catch (e) {
      // Catch other potential errors during binding
      throw RuntimeError("Error during pattern assignment: $e");
    }

    // 3. Pattern assignment expression evaluates to the RHS value
    return rhsValue;
  }

  @override
  Object? visitSwitchExpression(SwitchExpression node) {
    final switchValue = node.expression.accept<Object?>(this);
    final originalEnvironment = environment; // Backup current environment

    for (final caseExpr in node.cases) {
      final pattern = caseExpr.guardedPattern.pattern;
      final guard = caseExpr.guardedPattern.whenClause?.expression;
      final body = caseExpr.expression;

      // Create a temporary environment for this case's pattern variables
      // Enclose the *original* environment where the switch expression is evaluated
      final caseEnvironment = Environment(enclosing: originalEnvironment);

      try {
        // Attempt to match and bind variables in the temporary environment
        _matchAndBind(pattern, switchValue, caseEnvironment);
        Logger.debug(
            "[SwitchExpr] Pattern ${pattern.runtimeType} matched value ${switchValue?.runtimeType}");

        // Pattern matched, now check the guard (if it exists)
        bool guardPassed = true;
        if (guard != null) {
          final previousVisitorEnv = environment; // Backup
          try {
            environment = caseEnvironment; // Evaluate guard in case scope
            final guardResult = guard.accept<Object?>(this);
            if (guardResult is! bool) {
              throw RuntimeError(
                  "Switch expression 'when' clause must evaluate to a boolean.");
            }
            guardPassed = guardResult;
            Logger.debug("[SwitchExpr] Guard evaluated to: $guardPassed");
          } finally {
            environment = previousVisitorEnv; // Restore
          }
        }

        // If guard passed (or no guard), evaluate and return the body result
        if (guardPassed) {
          Logger.debug("[SwitchExpr] Guard passed or absent. Evaluating body.");

          final previousVisitorEnv = environment; // Backup
          try {
            environment = caseEnvironment; // Evaluate body in case scope
            final result = body.accept<Object?>(this);
            Logger.debug("[SwitchExpr] Body evaluated to: $result. Returning.");
            return result; // Return the result of the matching case's body
          } finally {
            environment = previousVisitorEnv; // Restore
          }
        }
      } on PatternMatchException catch (e) {
        // Pattern didn't match, try the next case
        Logger.debug(
            "[SwitchExpr] Pattern ${pattern.runtimeType} did not match: ${e.message}. Trying next case.");
        continue;
      }
      // If we reach here, it means the pattern matched but the guard failed.
      Logger.debug(
          "[SwitchExpr] Pattern matched but guard failed. Trying next case.");
    } // End of loop through cases

    // If no case matched and returned a value
    throw RuntimeError(
        "Switch expression was not exhaustive for value: $switchValue (${switchValue?.runtimeType})");
  }

  @override
  Object? visitExtensionDeclaration(ExtensionDeclaration node) {
    final extensionName = node.name?.lexeme;
    Logger.debug(
        "[visitExtensionDeclaration] Declaring extension: ${extensionName ?? '<unnamed>'}");

    // 1. Resolve the 'on' type
    final onTypeNode = node.onClause?.extendedType;
    if (onTypeNode == null) {
      // This might happen for extension types, which are different.
      // For now, assume classic extensions always have an 'on' clause.
      Logger.warn(
          "[visitExtensionDeclaration] Extension '${extensionName ?? '<unnamed>'}' has no 'on' clause, skipping.");
      return null;
    }

    // Resolve the type name from the AST node
    String onTypeName;
    if (onTypeNode is NamedType) {
      onTypeName = onTypeNode.name.lexeme;
    } else {
      Logger.warn(
          "[visitExtensionDeclaration] Unsupported 'on' type node for resolution: ${onTypeNode.runtimeType}. Skipping extension.");
      return null;
    }

    // Look up the RuntimeType in the environment
    RuntimeType onRuntimeType;
    try {
      final typeValue = environment.get(onTypeName);

      // Handle Resolution of Native/Bridged Types
      if (typeValue is RuntimeType) {
        // Standard case: Found an InterpretedClass/Mixin or existing BridgedClass
        onRuntimeType = typeValue;
        Logger.debug(
            "[visitExtensionDeclaration] Resolved 'on' type '$onTypeName' to RuntimeType: ${onRuntimeType.name}");
      } else if (typeValue is NativeFunction) {
        // Heuristic: If environment.get returns a NativeFunction for a common type name,
        // assume it represents the native type and find/create a corresponding BridgedClass.
        // This relies on the global environment being populated correctly with type bridges.
        BridgedClass? bridgedType = _getBridgedClassForNativeType(onTypeName);
        if (bridgedType != null) {
          onRuntimeType = bridgedType;
          Logger.debug(
              "[visitExtensionDeclaration] Resolved native 'on' type '$onTypeName' to BridgedClass: ${onRuntimeType.name}");
        } else {
          // We found something, but couldn't map it to a known bridged type
          throw RuntimeError(
              "Symbol '$onTypeName' resolved to NativeFunction but could not map to a known BridgedClass.");
        }
      } else {
        // Resolved to something unexpected (e.g., an instance, null, etc.)
        throw RuntimeError(
            "Symbol '$onTypeName' resolved to non-type: ${typeValue?.runtimeType}");
      }
    } on RuntimeError catch (e) {
      // Check if the error is specifically "Undefined variable"which means the type wasn't found at all.
      if (e.message.contains("Undefined variable: $onTypeName")) {
        // Special handling for core types that might not be explicitly defined if stdlib wasn't fully loaded?
        // Or maybe they are always NativeFunctions?
        BridgedClass? coreBridgedType =
            _getBridgedClassForNativeType(onTypeName);
        if (coreBridgedType != null) {
          onRuntimeType = coreBridgedType;
          Logger.debug(
              "[visitExtensionDeclaration] Resolved unfound core 'on' type '$onTypeName' to BridgedClass: ${onRuntimeType.name}");
        } else {
          // Type genuinely not found or not a recognized core type
          throw RuntimeError(
              "Could not resolve 'on' type '$onTypeName' for extension '${extensionName ?? '<unnamed>'}': Type not found or not a recognized core type.");
        }
      } else {
        // Propagate other RuntimeErrors (like the non-type error from above)
        throw RuntimeError(
            "Could not resolve 'on' type '$onTypeName' for extension '${extensionName ?? '<unnamed>'}': ${e.message}");
      }
    }

    // 2. Process members (methods, getters, setters, operators) - both instance and static
    final members = <String, Callable>{};
    final staticMethods = <String, Callable>{};
    final staticGetters = <String, Callable>{};
    final staticSetters = <String, Callable>{};
    final staticFields = <String, Object?>{};

    for (final member in node.members) {
      if (member is MethodDeclaration) {
        final methodName = member
            .name.lexeme; // Operator names like '+', '[]' are also lexemes

        if (member.isStatic) {
          // Handle static methods, getters, and setters
          final function =
              InterpretedFunction.method(member, environment, null);

          if (member.isGetter) {
            staticGetters[methodName] = function;
            Logger.debug(
                "[visitExtensionDeclaration]   Added static getter: $methodName");
          } else if (member.isSetter) {
            staticSetters[methodName] = function;
            Logger.debug(
                "[visitExtensionDeclaration]   Added static setter: $methodName");
          } else {
            staticMethods[methodName] = function;
            Logger.debug(
                "[visitExtensionDeclaration]   Added static method: $methodName");
          }
        } else {
          // Create InterpretedExtensionMethod for instance method-like declarations
          final function =
              InterpretedExtensionMethod(member, environment, onRuntimeType);
          members[methodName] = function;
          String memberType = "method";
          if (member.isGetter) memberType = "getter";
          if (member.isSetter) memberType = "setter";
          if (member.isOperator) memberType = "operator";
          Logger.debug(
              "[visitExtensionDeclaration]   Added extension $memberType: $methodName");
        }
      } else if (member is FieldDeclaration) {
        // Only static fields are allowed in extensions.
        if (!member.isStatic) {
          Logger.warn(
              "[visitExtensionDeclaration] Instance fields are not allowed in extensions. Skipping field '$member'.");
          continue; // Skip instance fields
        }
        // Handle static fields - store in the InterpretedExtension object
        for (final variable in member.fields.variables) {
          final fieldName = variable.name.lexeme;
          Object? value;
          if (variable.initializer != null) {
            // Evaluate static initializer immediately in the current environment
            try {
              value = variable.initializer!.accept<Object?>(this);
            } catch (e) {
              throw RuntimeError(
                  "Error evaluating static initializer for extension field '$fieldName': $e");
            }
          }
          // Store in staticFields map instead of environment
          staticFields[fieldName] = value;
          Logger.debug(
              "[visitExtensionDeclaration]   Stored static field: $fieldName");
        }
      } else {
        Logger.warn(
            "[visitExtensionDeclaration] Unsupported extension member type: ${member.runtimeType}. Skipping.");
      }
    }

    // 3. Create and store the InterpretedExtension
    final interpretedExtension = InterpretedExtension(
      name: extensionName,
      onType: onRuntimeType,
      members: members,
      staticMethods: staticMethods,
      staticGetters: staticGetters,
      staticSetters: staticSetters,
      staticFields: staticFields,
    );

    // How to store it? In the environment associated with its name?
    // Or in a separate list in the environment?
    // Let's try defining it by name if it has one, otherwise maybe a special list.
    if (extensionName != null) {
      environment.define(extensionName, interpretedExtension);
      Logger.debug(
          "[visitExtensionDeclaration] Defined named extension '$extensionName' in environment.");
    } else {
      // Store unnamed extensions in a special list in the environment
      environment.addUnnamedExtension(interpretedExtension);
      Logger.debug(
          "[visitExtensionDeclaration] Added unnamed extension to environment list.");
    }

    return null; // Declarations typically return null
  }

  BridgedClass? _getBridgedClassForNativeType(String typeName) {
    // This function maps core Dart type names (as strings) to their
    // corresponding BridgedClass representations used by the interpreter.
    // This relies on these BridgedClass instances being available (e.g., created during stdlib setup).
    // We get them from the global environment.
    Object? typeValue;
    try {
      // Use globalEnvironment which should have stdlib types defined.
      typeValue = globalEnvironment.get(typeName);
    } on RuntimeError {
      // Type not found in global environment
      Logger.warn(
          "[_getBridgedClassForNativeType] Type '$typeName' not found in global environment.");
      return null;
    }

    if (typeValue is BridgedClass) {
      // Successfully found the corresponding BridgedClass
      return typeValue;
    } else {
      // Found the name, but it wasn't a BridgedClass (e.g., maybe the NativeFunction constructor)
      Logger.warn(
          "[_getBridgedClassForNativeType] Symbol '$typeName' found in global env but is not a BridgedClass (type: ${typeValue?.runtimeType}).");
      // Special case: Maybe it maps to a fundamental type like Object?
      if (typeName == 'dynamic') {
        try {
          final objectType = globalEnvironment.get('Object');
          if (objectType is BridgedClass) return objectType;
          // ignore: empty_catches
        } on RuntimeError {}
      }
      return null;
    }
  }

  @override
  Object? visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    // 1. Retrieve the 'this' instance currently being created.
    InterpretedInstance? thisInstance;
    try {
      final thisValue = environment.get('this');
      if (thisValue is InterpretedInstance) {
        thisInstance = thisValue;
      } else {
        throw RuntimeError(
            "Internal error: 'this' is not an InterpretedInstance during super constructor call.");
      }
    } on RuntimeError {
      throw RuntimeError(
          "Internal error: Could not find 'this' during super constructor call.");
    }

    // 2. Check that the class has a bridged superclass.
    final currentClass = thisInstance.klass;
    final bridgedSuper = currentClass.bridgedSuperclass;
    if (bridgedSuper == null) {
      // If the superclass is interpreted, this call should be handled differently
      // (standard inherited constructor call).
      // For now, assume that if we get here, it's because of a bridged superclass.
      throw RuntimeError(
          "Cannot call super() constructor: Class '${currentClass.name}' does not have a registered bridged superclass.");
    }

    // 3. Determine the name of the super constructor to call.
    final constructorName =
        node.constructorName?.name ?? ''; // '' for the default

    // 4. Find the constructor adapter for the bridged superclass.
    final constructorAdapter =
        bridgedSuper.findConstructorAdapter(constructorName);
    if (constructorAdapter == null) {
      throw RuntimeError(
          "Bridged superclass '${bridgedSuper.name}' has no constructor named '$constructorName'.");
    }

    // 5. Evaluate the arguments passed to super(...).
    final (positionalArgs, namedArgs) = _evaluateArguments(node.argumentList);

    // 6. Call the constructor adapter.
    Object? nativeSuperObject;
    try {
      nativeSuperObject = constructorAdapter(this, positionalArgs, namedArgs);
      if (nativeSuperObject == null) {
        throw RuntimeError(
            "Bridged super constructor adapter for '${bridgedSuper.name}.$constructorName' returned null.");
      }
    } catch (e, s) {
      Logger.error(
          "Native exception during super constructor call to '${bridgedSuper.name}.$constructorName': $e\n$s");
      throw RuntimeError(
          "Native error during super constructor call '$constructorName': $e");
    }

    // 7. Store the returned native object on the 'this' instance.
    thisInstance.bridgedSuperObject = nativeSuperObject;
    Logger.debug(
        "[SuperConstructorInvocation] Stored native super object (${nativeSuperObject.runtimeType}) on instance of ${currentClass.name}.");

    return null; // The super() call itself doesn't return a value.
  }

  @override
  Object? visitImportDirective(ImportDirective node) {
    final importUriString = node.uri.stringValue;
    if (importUriString == null) {
      Logger.warn(
          "[visitImportDirective] Import directive with null URI string.");
      return null; // Return null if the URI is null
    }

    Logger.debug(
        "[InterpreterVisitor.visitImportDirective] START processing import: $importUriString");

    Uri resolvedUri;
    final importUri = Uri.parse(importUriString);

    if (importUri.isScheme('dart') || importUri.isScheme('package')) {
      resolvedUri = importUri;
      Logger.debug(
          "[visitImportDirective] Using absolute/unresolvable URI: $resolvedUri");
    } else {
      final baseUri = moduleLoader.currentlibrary;

      if (baseUri != null) {
        Logger.debug(
            "[visitImportDirective] Attempting to resolve relative URI '$importUriString' relative to '$baseUri'");
        resolvedUri = baseUri.resolveUri(importUri);
        Logger.debug(
            "[visitImportDirective] Resolved relative URI: $resolvedUri");
      } else {
        throw RuntimeError(
            "Unable to resolve relative import '$importUriString': Base URI not defined in ModuleLoader. "
            "Either provide a basePath parameter or use absolute URIs.");
      }
    }

    final prefixIdentifier = node.prefix; // Get the prefix identifier
    final prefixName = prefixIdentifier?.name;
    Logger.debug(
        "[visitImportDirective] Loading module for resolved URI: $resolvedUri (prefix: $prefixName)");

    LoadedModule loadedModule = moduleLoader.loadModule(resolvedUri);

    // Extract the show/hide combinators from the import directive
    Set<String>? showNames;
    Set<String>? hideNames;

    for (final combinator in node.combinators) {
      if (combinator is ShowCombinator) {
        showNames ??= {};
        showNames.addAll(combinator.shownNames.map((id) => id.name));
        Logger.debug(
            "[visitImportDirective] Combinator: show ${combinator.shownNames.map((id) => id.name).join(', ')}");
      } else if (combinator is HideCombinator) {
        hideNames ??= {};
        hideNames.addAll(combinator.hiddenNames.map((id) => id.name));
        Logger.debug(
            "[visitImportDirective] Combinator: hide ${combinator.hiddenNames.map((id) => id.name).join(', ')}");
      }
    }

    if (prefixName != null) {
      Logger.debug(
          "[visitImportDirective] Importation du module '${resolvedUri.toString()}' avec le préfixe '$prefixName'. Show: $showNames, Hide: $hideNames");

      Environment envForPrefix;
      if (showNames != null || hideNames != null) {
        // Apply show/hide to the exported environment of the loaded module BEFORE defining it for the prefix
        envForPrefix = loadedModule.exportedEnvironment
            .shallowCopyFiltered(showNames: showNames, hideNames: hideNames);
      } else {
        envForPrefix = loadedModule.exportedEnvironment;
      }
      environment.definePrefixedImport(prefixName, envForPrefix);
    } else {
      Logger.debug(
          "[visitImportDirective] Direct import of module '${resolvedUri.toString()}' into the current environment. Show: $showNames, Hide: $hideNames");
      // Apply show/hide directly during import into the current environment
      environment.importEnvironment(loadedModule.exportedEnvironment,
          show: showNames, hide: hideNames);
    }
    return null; // Import directives do not produce a value.
  }

  /// Helper method to create the appropriate operand for ++ and -- operators.
  /// For numeric types, returns 1 or -1 directly.
  /// For custom classes, attempts to create an instance with value 1 or -1.
  Object? _createIncrementOperand(Object? targetValue, bool isIncrement) {
    if (targetValue is! InterpretedInstance) {
      // For primitive types (num, int, double), return the literal value
      return isIncrement ? 1 : -1;
    }

    // For custom class instances, try to create an instance of the same class
    // with the value 1 or -1. This handles cases like CustomNumber(1).
    try {
      final klass = targetValue.klass;
      final operandValue = isIncrement ? 1 : -1;

      // Try to create an instance with the operand value
      final newInstance = klass.call(this, [operandValue], {});
      return newInstance;
    } catch (e) {
      // If we can't create an instance, fall back to the literal value
      // This allows the operator to handle the error appropriately
      return isIncrement ? 1 : -1;
    }
  }
} // End of InterpreterVisitor class
