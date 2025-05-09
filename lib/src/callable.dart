import 'dart:async';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:d4rt/d4rt.dart';

// Interface or base class for all "callable" entities
abstract class Callable {
  // Number of expected arguments
  int get arity;
  // Method to execute the callable
  Object? call(InterpreterVisitor visitor, List<Object?> positionalArguments,
      [Map<String, Object?> namedArguments, List<RuntimeType>? typeArguments]);
}

class _ExecutionPreparationResult {
  final Environment environment;
  final bool redirected;
  _ExecutionPreparationResult(this.environment, this.redirected);
}

// Represents a function or method defined by the user
class InterpretedFunction implements Callable {
  final FormalParameterList? _parameters;
  final FunctionBody _body;
  final Environment _closure;
  final String? _name;
  // Add isInitializer flag for constructors
  final bool isInitializer;
  // Store constructor initializers
  final List<ConstructorInitializer>? _constructorInitializers;
  // Flags for getters and setters
  final bool isGetter;
  final bool isSetter;
  // Store the class/enum where this function/method was defined
  final RuntimeType? ownerType; // Nullable for non-class/enum functions
  // Abstract flag for methods
  final bool isAbstract;
  // Async flag for methods/functions
  final bool isAsync;

  final RuntimeType? declaredReturnType; // Store the declared type

  final bool isNullable; // Store if the return type is nullable

  // Public getter for the closure environment
  Environment get closure => _closure;

  // Private constructor for bind
  InterpretedFunction._internal(
    this._parameters,
    this._body,
    this._closure,
    this._name, {
    this.isInitializer = false,
    List<ConstructorInitializer>? constructorInitializers,
    this.isGetter = false,
    this.isSetter = false,
    this.ownerType,
    this.isAbstract = false,
    this.isAsync = false,
    this.declaredReturnType,
    this.isNullable = false,
  }) : _constructorInitializers = constructorInitializers;

  // Constructor for declared functions (top-level or nested, not methods)
  InterpretedFunction.declaration(FunctionDeclaration declaration,
      Environment closure, RuntimeType? declaredReturnType, bool isNullable)
      : this._internal(
          declaration.functionExpression.parameters,
          declaration.functionExpression.body,
          closure,
          declaration.name.lexeme,
          isGetter: declaration.isGetter, // Pass getter flag
          isSetter: declaration.isSetter, // Pass setter flag
          ownerType: null, // Not defined within a class/enum
          isAbstract: false, // Non-method functions cannot be abstract
          isAsync: declaration
              .functionExpression.body.isAsynchronous, // Pass async flag
          declaredReturnType: declaredReturnType,
          isNullable: isNullable,
        );

  // Constructor for function expressions (anonymous)
  InterpretedFunction.expression(
      FunctionExpression expression, Environment closure)
      : this._internal(expression.parameters, expression.body, closure, null,
            ownerType: null, // Not defined within a class/enum
            isAbstract: false, // Anonymous functions cannot be abstract
            isAsync: expression.body.isAsynchronous // Pass async flag
            );

  // Constructor for methods
  InterpretedFunction.method(
      MethodDeclaration declaration, Environment closure, RuntimeType? owner)
      : this._internal(declaration.parameters, declaration.body, closure,
            declaration.name.lexeme,
            // Consider factory methods later
            isInitializer: false, // Methods are not initializers (usually)
            isGetter: declaration.isGetter, // Pass getter flag
            isSetter: declaration.isSetter, // Pass setter flag
            ownerType: owner, // Pass the owner type (class or enum)
            isAbstract: declaration.isAbstract, // Set the abstract flag
            isAsync: declaration.body.isAsynchronous // Pass async flag
            );

  // Constructor for constructors
  InterpretedFunction.constructor(ConstructorDeclaration declaration,
      Environment closure, RuntimeType? owner)
      : this._internal(declaration.parameters, declaration.body, closure,
            declaration.name?.lexeme ?? '', // Use '' for unnamed constructor
            isInitializer: true,
            constructorInitializers:
                declaration.initializers, // Pass to renamed param
            ownerType: owner, // Pass the owner type (class or enum)
            isAbstract: false, // Constructors cannot be abstract
            isAsync: false // Constructors cannot be async
            );

  @override
  int get arity {
    if (isSetter) return 1; // Setters always take one argument
    // Original logic for required positional parameters
    final params = _parameters?.parameters;
    if (params == null) return 0;
    return params
        .whereType<NormalFormalParameter>()
        .where((p) => p.isRequiredPositional)
        .length;
  }

  // Calculate total positional parameters (required + optional)
  int get _totalPositionalArity {
    final params = _parameters?.parameters;
    if (params == null) return 0;
    return params.where((p) => p.isPositional).length;
  }

  /// Binds 'this' to a specific instance, returning a new callable
  /// where the closure has 'this' defined.
  Callable bind(RuntimeValue instance) {
    if (ownerType == null) {
      // Check ownerType instead of definingClass
      throw RuntimeError("Cannot bind 'this' to a non-method function.");
    }
    // Create a new environment that encloses the original function closure,
    // but defines 'this' locally.
    final boundEnvironment = Environment(enclosing: closure);
    boundEnvironment.define('this', instance);

    // Create a new function *instance* that uses the bound environment
    // Need to ensure all relevant properties (isGetter, isSetter, etc.) are copied.
    final boundFunction = InterpretedFunction._internal(
      _parameters,
      _body,
      boundEnvironment,
      _name,
      isInitializer: isInitializer,
      constructorInitializers: _constructorInitializers,
      isGetter: isGetter,
      isSetter: isSetter,
      ownerType: ownerType, // Pass ownerType
      isAbstract: isAbstract,
      isAsync: isAsync,
      declaredReturnType: declaredReturnType,
    );
    return boundFunction;
  }

  /// Helper to setup environment, bind args, and run initializers.
  /// Returns the execution environment and whether redirection occurred.
  _ExecutionPreparationResult _prepareExecutionEnvironment(
    InterpreterVisitor visitor,
    List<Object?> positionalArguments,
    Map<String, Object?> namedArguments,
  ) {
    final executionEnvironment = Environment(enclosing: _closure);
    final params = _parameters?.parameters;
    int positionalArgIndex = 0;
    final providedNamedArgs = namedArguments;
    final processedParamNames = <String>{};

    if (params != null) {
      for (final param in params) {
        String? paramName;
        Expression? defaultValueExpr;
        bool isRequired = false;
        bool isOptionalPositional = false;
        bool isNamed = false;
        bool isRequiredNamed = false;
        bool isFieldInitializing = false; // NEW flag

        // Determine parameter info
        FormalParameter actualParam =
            param; // Handle potential DefaultFormalParameter wrapper
        if (param is DefaultFormalParameter) {
          defaultValueExpr = param.defaultValue;
          actualParam = param.parameter;
        }

        if (actualParam is NormalFormalParameter) {
          paramName = actualParam.name?.lexeme;
          isRequired = actualParam.isRequiredPositional;
          isOptionalPositional = actualParam.isOptionalPositional;
          isNamed = actualParam.isNamed;
          isRequiredNamed = actualParam.isRequiredNamed;
          // Check if it's specifically a field-initializing parameter (this.x)
          if (actualParam is FieldFormalParameter) {
            isFieldInitializing = true;
          }
        } else {
          throw UnimplementedError(
              "Unsupported parameter kind after unwrapping DefaultFormalParameter: ${actualParam.runtimeType}");
        }

        if (paramName == null) throw StateError("Parameter missing name");
        processedParamNames.add(paramName);

        // Find corresponding argument and value
        Object? valueToDefine;
        bool argumentProvided = false;

        if (isOptionalPositional || isRequired) {
          if (positionalArgIndex < positionalArguments.length) {
            valueToDefine = positionalArguments[positionalArgIndex++];
            argumentProvided = true;
          }
        } else if (isNamed) {
          if (providedNamedArgs.containsKey(paramName)) {
            valueToDefine = providedNamedArgs[paramName];
            argumentProvided = true;
          }
        } else {
          // This should not happen if logic above is correct
          throw StateError(
              "Parameter '$paramName' is neither positional nor named?");
        }

        // Handle defaults and required checks
        if (!argumentProvided) {
          if (defaultValueExpr != null) {
            final previousVisitorEnv = visitor.environment;
            try {
              // Default values evaluated in the *calling* scope (closure of the function)
              visitor.environment = _closure;
              valueToDefine = defaultValueExpr.accept<Object?>(visitor);
            } finally {
              visitor.environment = previousVisitorEnv;
            }
          } else if (isRequired || isRequiredNamed) {
            throw RuntimeError(
                "Missing required ${isNamed ? 'named' : ''} argument for '$paramName' in function '${_name ?? '<anonymous>'}'.");
          } else {
            // Optional parameters default to null if no default value specified
            valueToDefine = null;
          }
        }

        // Define variable in execution scope OR Initialize field
        if (isFieldInitializing) {
          // It's a `this.fieldName` parameter. Initialize the field directly.
          final thisValue = _closure.get('this')
              as RuntimeValue; // Get 'this' as RuntimeValue
          // Directly call set on the RuntimeValue (works for both Instance and EnumValue)
          // We don't need the visitor here, as field init parameters don't call setters.
          Logger.debug(
              "[_prepareEnv] Attempting to set this.$paramName = $valueToDefine for instance ${thisValue.hashCode}");
          thisValue.set(paramName, valueToDefine);
        } else {
          // It's a regular parameter. Define it in the execution environment.
          executionEnvironment.define(paramName, valueToDefine);
        }
      }

      // Final Validation
      if (positionalArgIndex < positionalArguments.length) {
        throw RuntimeError(
            "Too many positional arguments. Expected at most $_totalPositionalArity, got ${positionalArguments.length}.");
      }
      for (final providedName in providedNamedArgs.keys) {
        if (!processedParamNames.contains(providedName)) {
          throw RuntimeError(
              "Function '${_name ?? '<anonymous>'}' does not have a parameter named '$providedName'.");
        }
      }
    } else if (positionalArguments.isNotEmpty || providedNamedArgs.isNotEmpty) {
      throw RuntimeError(
          "Function '${_name ?? '<anonymous>'}' takes no arguments, but arguments were provided.");
    }

    bool explicitSuperCalled = false; // Track if super() or this() was called
    bool redirected = false;
    if (isInitializer) {
      // Only run initializers for constructors
      // Determine superclass ONLY if owner is a class
      InterpretedClass? superClass;
      if (ownerType is InterpretedClass) {
        final ownerClass = ownerType as InterpretedClass; // Cast to local var
        superClass = ownerClass.superclass;
      }

      // Get 'this' which could be InterpretedInstance OR InterpretedEnumValue
      final RuntimeValue thisValue = _closure.get('this') as RuntimeValue;

      if (_constructorInitializers != null &&
          _constructorInitializers.isNotEmpty) {
        final originalVisitorEnv = visitor.environment;
        try {
          // Initializers run in the environment of the constructor *body*,
          // which encloses the closure (with 'this') and params.
          visitor.environment = executionEnvironment;

          for (final initializer in _constructorInitializers) {
            if (initializer is ConstructorFieldInitializer) {
              // Handles: this.fieldName = expression
              final fieldName = initializer.fieldName.name;
              final value = initializer.expression.accept<Object?>(visitor);
              if (value is AsyncSuspensionRequest) {
                // Propagate suspension state. Cannot continue synchronously.
                // This is a complex case - how does the continuation work?
                // For now, throw an error indicating this isn't fully supported.
                throw UnimplementedError(
                    "'await' is not supported within constructor field initializers.");
              }
              thisValue.set(
                  fieldName, value); // No visitor needed for direct field init
            } else if (initializer is SuperConstructorInvocation) {
              // Handles: super(...) or super.named(...)
              if (explicitSuperCalled) {
                throw RuntimeError(
                    "Cannot call 'super' or 'this' multiple times in a constructor initializer list.");
              }
              if (ownerType is! InterpretedClass) {
                // Should not happen if this is called from a constructor
                throw StateError(
                    "Super constructor call outside of class context.");
              }
              final ownerClass = ownerType as InterpretedClass;
              final InterpretedClass? dartSuperClass = ownerClass.superclass;
              final BridgedClass? bridgedSuperClass =
                  ownerClass.bridgedSuperclass;

              if (dartSuperClass == null && bridgedSuperClass == null) {
                throw RuntimeError(
                    "Cannot call 'super' in constructor of class '${ownerType?.name}' because it has no superclass."); // Use ownerType?.name
              }

              final superConstructorName =
                  initializer.constructorName?.name ?? '';

              if (dartSuperClass != null) {
                final superConstructor =
                    dartSuperClass.findConstructor(superConstructorName);
                if (superConstructor == null) {
                  throw RuntimeError(
                      "Superclass '${dartSuperClass.name}' does not have a constructor named '$superConstructorName'.");
                }
                // Evaluate arguments (existing logic)
                final (superPositionalArgs, superNamedArgs) =
                    _evaluateArgumentsForInvocation(
                        visitor, initializer.argumentList, "super()");
                // Call Dart super constructor (existing logic)
                final superCallResult = superConstructor
                    .bind(thisValue)
                    .call(visitor, superPositionalArgs, superNamedArgs);
                if (superCallResult is AsyncSuspensionRequest) {
                  throw StateError(
                      "Internal error: Super constructor call returned SuspendedState.");
                }
              } else if (bridgedSuperClass != null) {
                final constructorAdapter = bridgedSuperClass
                    .findConstructorAdapter(superConstructorName);
                if (constructorAdapter == null) {
                  throw RuntimeError(
                      "Bridged superclass '${bridgedSuperClass.name}' does not have a constructor named '$superConstructorName'. Check bridge definition.");
                }
                // Evaluate arguments (using helper)
                final (superPositionalArgs, superNamedArgs) =
                    _evaluateArgumentsForInvocation(
                        visitor, initializer.argumentList, "super()");
                // Call the bridged constructor adapter
                try {
                  // Adapter needs the *visitor* and args. It does NOT operate on 'thisValue' directly.
                  // The adapter is responsible for finding/creating the native object.
                  final nativeSuperObject = constructorAdapter(
                      visitor, superPositionalArgs, superNamedArgs);

                  // We need to associate this new native object with our current instance.
                  if (thisValue is InterpretedInstance) {
                    // Store the returned native object in the public field
                    thisValue.bridgedSuperObject =
                        nativeSuperObject; // Use the public field
                    Logger.debug(
                        "[SuperCall] Stored native object from bridged super constructor '$superConstructorName' ($nativeSuperObject)");
                  } else {
                    // This case (e.g., calling super() from an enum constructor?) seems unlikely/invalid.
                    throw StateError(
                        "Cannot call super() constructor on non-instance 'this'.");
                  }
                } on RuntimeError catch (e) {
                  throw RuntimeError(
                      "Error during bridged super constructor '$superConstructorName': ${e.message}");
                } catch (e) {
                  throw RuntimeError(
                      "Native error during bridged super constructor '$superConstructorName': $e");
                }
              } else {
                // Should be impossible given the check at the start
                throw StateError(
                    "Internal error: No superclass found despite initial check.");
              }
              explicitSuperCalled = true;
            } else if (initializer is RedirectingConstructorInvocation) {
              // Handles: this(...)
              if (explicitSuperCalled) {
                throw RuntimeError(
                    "Cannot call 'super' or 'this' multiple times in a constructor initializer list.");
              }

              final targetConstructorName =
                  initializer.constructorName?.name ?? '';
              InterpretedFunction? targetConstructor;
              if (ownerType is InterpretedClass) {
                final ownerClass =
                    ownerType as InterpretedClass; // Cast to local var
                targetConstructor =
                    ownerClass.findConstructor(targetConstructorName);
              }
              if (targetConstructor == null) {
                throw RuntimeError(
                    "Class '${ownerType?.name ?? '<unknown>'}' does not have a constructor named '$targetConstructorName' for redirection."); // Use ownerType?.name
              }

              // Evaluate arguments for this(...) call
              final List<Object?> targetPositionalArgs = [];
              final Map<String, Object?> targetNamedArgs = {};
              bool targetNamedArgsEncountered = false;
              for (final arg in initializer.argumentList.arguments) {
                final argValue = arg.accept<Object?>(visitor);
                if (argValue is AsyncSuspensionRequest) {
                  throw UnimplementedError(
                      "'await' is not supported within redirecting constructor call arguments.");
                }

                if (arg is NamedExpression) {
                  targetNamedArgsEncountered = true;
                  final name = arg.name.label.name;
                  // Use already evaluated value
                  if (targetNamedArgs.containsKey(name)) {
                    throw RuntimeError(
                        "Named argument '$name' provided multiple times to this().");
                  }
                  targetNamedArgs[name] = argValue;
                } else {
                  if (targetNamedArgsEncountered) {
                    throw RuntimeError(
                        "Positional arguments cannot follow named arguments in this().");
                  }
                  targetPositionalArgs
                      .add(argValue); // Use already evaluated value
                }
              }

              // Call the target constructor, bound to the *same* instance
              // NOTE: Redirecting constructor call CANNOT suspend
              final redirectCallResult = targetConstructor
                  .bind(thisValue)
                  .call(visitor, targetPositionalArgs, targetNamedArgs);
              if (redirectCallResult is AsyncSuspensionRequest) {
                // Should not happen as constructors are not async
                throw StateError(
                    "Internal error: Redirecting constructor call returned SuspendedState.");
              }

              explicitSuperCalled = true;
              redirected = true; // Mark that redirection occurred
            } else {
              throw StateError(
                  "Unknown constructor initializer type: ${initializer.runtimeType}");
            }
          }
        } finally {
          visitor.environment =
              originalVisitorEnv; // Restore visitor environment
        }
      }

      // If no explicit super() or this() was called, and there IS a superclass,
      // implicitly call the superclass's unnamed constructor with no arguments.
      if (!explicitSuperCalled && superClass != null) {
        final defaultSuperConstructor = superClass.findConstructor('');
        if (defaultSuperConstructor == null) {
          throw RuntimeError(
              "Implicit call to superclass '${superClass.name}' default constructor failed: No default constructor found.");
        }
        // Call the default super constructor, bound to the *current* instance
        // NOTE: Default super constructor call CANNOT suspend
        final defaultSuperResult =
            defaultSuperConstructor.bind(thisValue).call(visitor, [], {});
        if (defaultSuperResult is AsyncSuspensionRequest) {
          // Should not happen as constructors are not async
          throw StateError(
              "Internal error: Implicit super constructor call returned SuspendedState.");
        }
      }
    }

    return _ExecutionPreparationResult(executionEnvironment, redirected);
  }

  @override
  Object? call(InterpreterVisitor visitor, List<Object?> positionalArguments,
      [Map<String, Object?> namedArguments = const {},
      List<RuntimeType>? typeArguments]) {
    final prepResult = _prepareExecutionEnvironment(
      visitor,
      positionalArguments,
      namedArguments,
    );

    final executionEnvironment = prepResult.environment;
    final redirected = prepResult.redirected;

    final previousCurrentFunction = visitor.currentFunction; // Save previous
    visitor.currentFunction = this; // Set current function
    final previousAsyncState =
        visitor.currentAsyncState; // Sauvegarder l'état async actuel

    try {
      if (isAsync) {
        final completer = Completer<Object?>();

        // Déterminer le premier état (nœud AST)
        AstNode? initialStateIdentifier;
        final bodyToExecute = _body;
        if (!redirected) {
          if (bodyToExecute is BlockFunctionBody) {
            initialStateIdentifier = bodyToExecute.block.statements.firstOrNull;
          } else if (bodyToExecute is ExpressionFunctionBody) {
            initialStateIdentifier = bodyToExecute.expression;
          } else if (bodyToExecute is EmptyFunctionBody) {
            initialStateIdentifier =
                null; // Fonction vide, se complète immédiatement
          } else {
            throw StateError(
                "Unhandled function body type for async state machine: ${bodyToExecute.runtimeType}");
          }
        } else {
          // Constructeur redirigé, se complète avec 'this'
          initialStateIdentifier = null;
        }

        // Créer l'état initial
        final asyncState = AsyncExecutionState(
          environment: executionEnvironment,
          completer: completer,
          nextStateIdentifier: initialStateIdentifier,
          function: this,
        );

        // Gérer les cas où la fonction se termine immédiatement
        if (initialStateIdentifier == null) {
          if (redirected) {
            completer.complete(executionEnvironment.get('this'));
          } else {
            completer.complete(null); // Fonction vide
          }
        } else {
          // Le moteur prendra en charge la planification (ex: via Future.microtask)
          // Mettre le visiteur dans l'état initial pour le moteur
          visitor.currentAsyncState = asyncState;
          _startAsyncStateMachine(visitor, asyncState);
        }

        // Retourner immédiatement le Future
        return completer.future;
      } else {
        Object? syncResult;
        final previousVisitorEnv = visitor.environment; // Save env
        try {
          if (isAbstract) {
            throw RuntimeError(
                "Cannot call abstract method '${_name ?? '<abstract>'}'.");
          }

          final bodyToExecute = _body;

          if (!redirected) {
            if (bodyToExecute is BlockFunctionBody) {
              syncResult = visitor.executeBlock(
                  bodyToExecute.block.statements, executionEnvironment);
            } else if (bodyToExecute is ExpressionFunctionBody) {
              visitor.environment = executionEnvironment;
              syncResult = bodyToExecute.expression.accept<Object?>(visitor);
            } else if (bodyToExecute is EmptyFunctionBody) {
              if (!isInitializer && _name != null) {
                throw RuntimeError(
                    "Cannot execute non-constructor function $_name' with empty body.");
              }
              syncResult = null;
            } else {
              throw StateError(
                  "Unhandled function body type: ${bodyToExecute.runtimeType}");
            }
          } else {
            Logger.debug(
                " [InterpretedFunction.call sync] Body skipped due to redirecting constructor for $_name");
            // If redirected, the value is 'this'
            syncResult = _closure.get('this');
          }
        } on ReturnException catch (returnExc) {
          syncResult = returnExc.value;
        } finally {
          visitor.currentFunction = previousCurrentFunction; // Restore function
          visitor.environment = previousVisitorEnv; // Restore environment
        }

        // For initializers (constructors), always return 'this'
        if (isInitializer) {
          try {
            return _closure.get('this');
          } catch (_) {
            throw StateError(
                "Internal error: 'this' not found in bound constructor environment.");
          }
        } else {
          // Check if the synchronous execution resulted in a suspension (shouldn't happen if await is blocked)
          if (syncResult is AsyncSuspensionRequest) {
            throw StateError(
                "Internal error: Synchronous function returned SuspendedState.");
          }
          return syncResult; // Return sync result
        }
      }
    } on ReturnException catch (e) {
      // Catch return from synchronous functions
      return e.value;
    } finally {
      visitor.currentFunction = previousCurrentFunction; // Restore previous

      // Restaurer l'état asynchrone précédent au lieu de l'écraser
      visitor.currentAsyncState = previousAsyncState;
      Logger.debug(
          " [InterpretedFunction.call FINALLY] Restored currentFunction and currentAsyncState. AsyncState is now: ${visitor.currentAsyncState?.hashCode}");
    }
  }

  // Moteur principal de la machine à états asynchrone
  // Planifié via Future.microtask pour démarrer l'exécution
  static Future<void> _runStateMachine(
      InterpreterVisitor visitor, AsyncExecutionState currentState) async {
    Object? lastResult;
    AstNode? currentNode = currentState.nextStateIdentifier;

    // Boucle principale d'exécution des états
    while (currentNode != null) {
      // Sauvegarder l'environnement visiteur actuel (au cas où)
      final originalVisitorEnv = visitor.environment;
      final previousAsyncState = visitor.currentAsyncState;

      // Configurer le visiteur pour l'état courant
      // Utiliser l'environnement de la boucle FOR si on est dedans, sinon l'environnement principal de l'état
      visitor.environment =
          currentState.forLoopEnvironment ?? currentState.environment;
      visitor.currentAsyncState = currentState;
      // currentFunction is already defined by the call method

      Logger.debug(
          " [StateMachine] Executing state: ${currentNode.runtimeType} in state env ${currentState.environment.hashCode}, loop env ${currentState.forLoopEnvironment?.hashCode}. Visitor env set to: ${visitor.environment.hashCode}");

      try {
        // Cas: Boucle While
        if (currentNode is WhileStatement) {
          final whileNode = currentNode;
          Logger.debug("[StateMachine] Handling WhileStatement condition.");
          // Évaluer la condition
          final conditionResult = whileNode.condition.accept<Object?>(visitor);

          if (conditionResult is AsyncSuspensionRequest) {
            // La condition elle-même est asynchrone, suspendre
            Logger.debug(
                " [StateMachine] While condition suspended. Waiting...");
            lastResult =
                conditionResult; // Mettre à jour lastResult pour le traitement ci-dessous
          } else if (conditionResult is bool) {
            // Condition synchrone
            if (conditionResult) {
              // Condition vraie: le prochain état est le corps de la boucle
              Logger.debug(
                  "[StateMachine] While condition TRUE. Next node is body: ${whileNode.body.runtimeType}");
              // Si le corps est un bloc, prendre la première instruction
              if (whileNode.body is Block) {
                currentNode = (whileNode.body as Block).statements.firstOrNull;
              } else {
                currentNode = whileNode.body;
              }
              currentState.nextStateIdentifier = currentNode;
              continue; // Relancer la boucle while de la machine à états avec le nouveau nœud
            } else {
              // Condition fausse: sauter la boucle, trouver le nœud suivant après le while
              Logger.debug(
                  "[StateMachine] While condition FALSE. Finding node after while.");
              currentNode = _findNextSequentialNode(visitor, whileNode);
              currentState.nextStateIdentifier = currentNode;
              continue; // Relancer la boucle while de la machine à états
            }
          } else {
            // La condition n'a retourné ni booléen ni suspension
            throw RuntimeError(
                "While loop condition must evaluate to a boolean, but got ${conditionResult?.runtimeType}.");
          }
        } else if (currentNode is DoStatement) {
          final doNode = currentNode;
          // La logique du DoStatement est particulière:
          // 1. Si on arrive sur le DoStatement la *première fois* (ou après une condition vraie),
          //    il faut exécuter le corps.
          // 2. Si on arrive sur le DoStatement après avoir exécuté la *dernière* instruction du corps
          //    (détecté par _findNextSequentialNode retournant le DoStatement),
          //    il faut évaluer la condition.

          // Pour différencier, on peut regarder l'état précédent ou ajouter un flag dans AsyncExecutionState.
          // Approche simple: si l'état actuel pointe vers DoStatement, on suppose qu'on doit évaluer la condition
          // car _findNextSequentialNode nous y a mené depuis la fin du corps.
          // Si on entrait directement dans la boucle par un autre moyen (non standard), cela pourrait échouer.

          Logger.debug(
              "[StateMachine] Handling DoStatement. Evaluating condition.");
          // Évaluer la condition
          final conditionResult = doNode.condition.accept<Object?>(visitor);

          if (conditionResult is AsyncSuspensionRequest) {
            // La condition est asynchrone, suspendre
            Logger.debug(
                " [StateMachine] DoWhile condition suspended. Waiting...");
            lastResult =
                conditionResult; // Mettre à jour lastResult pour le traitement ci-dessous
          } else if (conditionResult is bool) {
            // Condition synchrone
            if (conditionResult) {
              // Condition vraie: le prochain état est le début du corps de la boucle
              Logger.debug(
                  "[StateMachine] DoWhile condition TRUE. Next node is body: ${doNode.body.runtimeType}");
              if (doNode.body is Block) {
                currentNode = (doNode.body as Block).statements.firstOrNull;
              } else {
                currentNode = doNode.body;
              }
              currentState.nextStateIdentifier = currentNode;
              continue; // Relancer la boucle de la machine à états avec le début du corps
            } else {
              // Condition fausse: sortir de la boucle, trouver le nœud suivant après le do-while
              Logger.debug(
                  "[StateMachine] DoWhile condition FALSE. Finding node after do-while.");
              currentNode = _findNextSequentialNode(visitor, doNode);
              currentState.nextStateIdentifier = currentNode;
              continue; // Relancer la boucle de la machine à états
            }
          } else {
            // La condition n'a retourné ni booléen ni suspension
            throw RuntimeError(
                "DoWhile loop condition must evaluate to a boolean, but got ${conditionResult?.runtimeType}.");
          }
          // Si la condition était suspendue, lastResult contient AsyncSuspensionRequest
          // et sera géré par la logique de suspension plus bas.
        } else if (currentNode is ForStatement &&
            currentNode.forLoopParts is ForEachParts) {
          final forNode = currentNode;
          final parts = forNode.forLoopParts as ForEachParts;

          Iterator<Object?>? iterator = currentState.currentForInIterator;

          // Première fois ou reprise après le corps?
          if (iterator == null) {
            // Première fois: évaluer l'iterable et créer l'itérateur
            Logger.debug(
                " [StateMachine] Handling ForIn: Evaluating iterable.");
            final iterableResult = parts.iterable.accept<Object?>(visitor);

            // Gérer si l'évaluation de l'iterable suspend
            if (iterableResult is AsyncSuspensionRequest) {
              Logger.debug(
                  "[StateMachine] ForIn iterable suspended. Waiting...");
              lastResult = iterableResult;
              // La logique de suspension ci-dessous s'en chargera.
            } else if (iterableResult is Iterable) {
              iterator = iterableResult.iterator;
              currentState.currentForInIterator =
                  iterator; // Sauvegarder l'itérateur
              Logger.debug("[StateMachine] ForIn: Iterator created.");
            } else {
              throw RuntimeError(
                  "The value iterate over in a for-in loop must be an Iterable, but got ${iterableResult?.runtimeType}.");
            }
          }

          // Si on a un itérateur (soit créé, soit repris), on continue la boucle
          if (iterator != null && lastResult is! AsyncSuspensionRequest) {
            bool hasNext;
            try {
              hasNext = iterator.moveNext();
            } catch (e, s) {
              Logger.warn(
                  "[StateMachine] Error during iterator.moveNext(): $e\n$s");
              throw RuntimeError("Error during iteration: $e");
            }

            if (hasNext) {
              // Élément suivant disponible
              final currentItem = iterator.current;
              Logger.debug("[StateMachine] ForIn: Got next item: $currentItem");

              if (parts is ForEachPartsWithDeclaration) {
                final loopVariable = parts.loopVariable;
                // Créer un environnement dédié à la boucle si ce n'est pas déjà fait
                currentState.forLoopEnvironment ??=
                    Environment(enclosing: currentState.environment);
                visitor.environment = currentState.forLoopEnvironment!;
                // Définir la variable de boucle dans cet environnement
                currentState.forLoopEnvironment!
                    .define(loopVariable.name.lexeme, currentItem);
              } else if (parts is ForEachPartsWithIdentifier) {
                // Pas de déclaration, on assigne dans l'environnement courant
                currentState.environment
                    .assign(parts.identifier.name, currentItem);
                // S'assurer qu'on n'utilise pas un environnement de boucle résiduel
                currentState.forLoopEnvironment = null;
                visitor.environment = currentState.environment;
              } else {
                throw StateError(
                    "Unknown ForEachParts type: \\${parts.runtimeType}");
              }

              // Le prochain état est le corps de la boucle
              Logger.debug(
                  "[StateMachine] ForIn: Next node is body: \\${forNode.body.runtimeType}");
              if (forNode.body is Block) {
                currentNode = (forNode.body as Block).statements.firstOrNull;
              } else {
                currentNode = forNode.body;
              }
              currentState.nextStateIdentifier = currentNode;
              continue; // Relancer la boucle de la machine à états avec le début du corps
            } else {
              // Fin de l'itération
              Logger.debug(
                  "[StateMachine] ForIn: Iteration finished. Finding node after loop. (forNode: \\${forNode.runtimeType}, parent: \\${forNode.parent?.runtimeType}, env: \\${visitor.environment.hashCode})");
              currentState.currentForInIterator = null; // Nettoyer l'itérateur
              // Nettoyer l'environnement de boucle s'il y en avait un
              currentState.forLoopEnvironment = null;
              visitor.environment = currentState.environment;
              currentNode = _findNextSequentialNode(visitor, forNode);
              Logger.debug(
                  "[StateMachine] ForIn: After _findNextSequentialNode, currentNode: \\${currentNode?.runtimeType}, parent: \\${currentNode?.parent?.runtimeType}");
              currentState.nextStateIdentifier = currentNode;
              continue; // Relancer la boucle de la machine à états
            }
          }
          // Si l'évaluation de l'iterable a été suspendue, lastResult contient
          // AsyncSuspensionRequest et sera géré par la logique ci-dessous.
        } else if (currentNode is ForStatement &&
            (currentNode.forLoopParts is ForPartsWithDeclarations ||
                currentNode.forLoopParts is ForPartsWithExpression)) {
          final forNode = currentNode;
          final parts = forNode.forLoopParts;
          bool cameFromBody =
              false; // Flag pour savoir si on vient de terminer le corps

          // Déterminer si on vient de terminer le corps de la boucle
          // (Approximation: si le nœud actuel est ForStatement et qu'on a un environnement de boucle)
          if (currentState.forLoopEnvironment != null &&
              currentState.forLoopInitialized &&
              !currentState.resumedFromInitializer) {
            // On vient du corps si l'env existe, est initialisé, ET on ne reprend pas de l'init
            cameFromBody = true;
          }
          // Réinitialiser le flag après l'avoir utilisé
          currentState.resumedFromInitializer = false;

          if (!currentState.forLoopInitialized) {
            Logger.debug(" [StateMachine] Handling For: Initializing.");
            // Créer l'environnement de boucle une seule fois
            currentState.forLoopEnvironment =
                Environment(enclosing: currentState.environment);
            visitor.environment =
                currentState.forLoopEnvironment!; // Utiliser l'env de la boucle

            AstNode? initNode;
            if (parts is ForPartsWithDeclarations) {
              initNode = parts.variables;
            } else if (parts is ForPartsWithExpression) {
              initNode = parts.initialization;
            }

            if (initNode != null) {
              lastResult = initNode
                  .accept<Object?>(visitor); // Exécute dans forLoopEnvironment

              if (lastResult is AsyncSuspensionRequest) {
                // Suspendu pendant l'initialisation
                Logger.debug(
                    "[StateMachine] For loop initialization suspended. Will resume.");
                // Marquer comme initialisé pour que la reprise passe à la condition
                currentState.forLoopInitialized = true;
                // Laisser lastResult tel quel, la logique de suspension générale le gérera
                // Ne PAS continuer vers la condition ou les updaters maintenant.
                // Le 'finally' restaurera l'env, et la reprise via .then() relancera _runStateMachine.
              } else {
                // Initialisation synchrone terminée
                currentState.forLoopInitialized = true;
                cameFromBody = false; // Ne pas aller aux updaters
                // Continuer vers la condition DANS CETTE MEME ITERATION de la boucle while
              }
            } else {
              // Pas d'initialisation
              currentState.forLoopInitialized = true;
              cameFromBody = false;
            }
            // Ne pas restaurer l'environnement ici, on en aura besoin pour la condition/updater
            // visitor.environment = currentState.environment; // Ne pas restaurer ici
          }

          // S'exécute seulement si on n'est pas suspendu par l'initialisation
          if (cameFromBody &&
              currentState.forLoopInitialized &&
              lastResult is! AsyncSuspensionRequest) {
            Logger.debug(" [StateMachine] Handling For: Running updaters.");
            visitor.environment =
                currentState.forLoopEnvironment!; // Utiliser l'env de la boucle
            NodeList<Expression>? updaters;
            if (parts is ForPartsWithDeclarations) {
              updaters = parts.updaters;
            } else if (parts is ForPartsWithExpression) {
              updaters = parts.updaters;
            }

            if (updaters != null) {
              for (final updateExpr in updaters) {
                lastResult = updateExpr.accept<Object?>(
                    visitor); // Exécute dans forLoopEnvironment
                if (lastResult is AsyncSuspensionRequest) {
                  // Suspendu pendant la mise à jour
                  Logger.debug("[StateMachine] For loop updater suspended.");
                  // Garder l'environnement pour la reprise
                  break; // Sortir de la boucle des updaters, la suspension sera gérée
                }
              }
            }
            // Ne pas restaurer l'environnement ici, on en aura besoin pour la condition
            // visitor.environment = currentState.environment;
            // Après les updaters (ou s'il n'y en a pas), on passe à la condition
            cameFromBody =
                false; // Ne plus considérer qu'on vient du corps pour la condition
          }

          // Condition (si initialisation terminée et pas suspendu pendant init/updater)\
          // S'exécute après init (si sync) ou après updater (si sync)
          if (currentState.forLoopInitialized &&
              lastResult is! AsyncSuspensionRequest) {
            Logger.debug(" [StateMachine] Handling For: Evaluating condition.");
            visitor.environment =
                currentState.forLoopEnvironment!; // Utiliser l'env de la boucle
            Expression? condition;
            if (parts is ForPartsWithDeclarations) {
              condition = parts.condition;
            } else if (parts is ForPartsWithExpression) {
              condition = parts.condition;
            }

            bool conditionValue = true; // La condition est vraie si absente
            if (condition != null) {
              lastResult = condition
                  .accept<Object?>(visitor); // Exécute dans forLoopEnvironment
              if (lastResult is AsyncSuspensionRequest) {
                // Suspendu pendant la condition
                Logger.debug("[StateMachine] For loop condition suspended.");
                // Garder l'environnement pour la reprise
              } else if (lastResult is bool) {
                conditionValue = lastResult;
              } else {
                // Restaurer l'environnement avant de lever l'erreur
                visitor.environment = currentState.environment;
                throw RuntimeError(
                    "For loop condition must be a boolean, but got ${lastResult?.runtimeType}");
              }
            }
            // Ne pas restaurer l'environnement ici si on continue dans le corps

            // Décision basée sur la condition (si pas suspendu)\
            if (lastResult is! AsyncSuspensionRequest) {
              if (conditionValue) {
                // Condition vraie: le prochain état est le corps
                Logger.debug(
                    "[StateMachine] For condition TRUE. Next node is body: ${forNode.body.runtimeType}");
                // L'environnement de la boucle reste actif pour l'exécution du corps
                if (forNode.body is Block) {
                  currentNode = (forNode.body as Block).statements.firstOrNull;
                } else {
                  currentNode = forNode.body;
                }
                // Si le corps est vide, on va boucler directement vers les updaters
                if (currentNode == null) {
                  Logger.debug(
                      "[StateMachine] For loop body is empty. Proceeding to updaters/condition.");
                  // Simuler qu'on vient du corps pour déclencher les updaters
                  visitor.environment =
                      currentState.environment; // Restaurer avant de continuer
                  currentState.nextStateIdentifier =
                      forNode; // Revenir au ForStatement
                  continue;
                } else {
                  currentState.nextStateIdentifier = currentNode;
                  // Ne pas restaurer l'environnement, le corps s'exécute dedans
                  continue; // Relancer la boucle de la machine à états avec le corps
                }
              } else {
                // Condition fausse: sortir de la boucle
                Logger.debug(
                    "[StateMachine] For condition FALSE. Finding node after loop.");
                // Nettoyer l'état de la boucle for
                currentState.forLoopInitialized = false;
                currentState.forLoopEnvironment = null;
                visitor.environment =
                    currentState.environment; // Restaurer l'environnement
                currentNode = _findNextSequentialNode(visitor, forNode);
                currentState.nextStateIdentifier = currentNode;
                continue; // Relancer la boucle de la machine à états avec le nœud suivant
              }
            }
          }
          // Si on est suspendu (lastResult is AsyncSuspensionRequest), la logique de suspension générale prend le relais.
          // L'environnement du visiteur doit être restauré dans le finally de la boucle principale.
        } else if (currentNode is TryStatement) {
          // Lorsqu'on entre dans un TryStatement, on l'enregistre
          currentState.activeTryStatement = currentNode;
          Logger.debug(
              "[StateMachine] Entering TryStatement: ${currentNode.offset}. Proceeding to body.");
          // Le prochain état est la première instruction du bloc try
          currentNode = currentNode.body.statements.firstOrNull;
          // Si le bloc try est vide, chercher le noeud suivant après le try
          if (currentNode == null) {
            Logger.debug(
                " [StateMachine] Try block is empty. Finding node after TryStatement.");
            // Y a-t-il un finally? Si oui, y aller.
            if (currentState.activeTryStatement?.finallyBlock != null) {
              Logger.debug(
                  "[StateMachine] Empty try block, jumping to finally.");
              currentState.pendingFinallyBlock =
                  currentState.activeTryStatement!.finallyBlock;
              currentNode =
                  currentState.pendingFinallyBlock!.statements.firstOrNull;
              currentState.pendingFinallyBlock =
                  null; // Le finally est maintenant en cours
            } else {
              // Pas de finally, trouver le noeud après le Try
              currentNode = _findNextSequentialNode(
                  visitor, currentState.activeTryStatement!);
              currentState.activeTryStatement = null; // Fin du try
            }
          }
          currentState.nextStateIdentifier = currentNode;
          continue; // Continuer avec le premier état du try (ou du finally ou après)
        } else if (currentNode is IfStatement) {
          final ifNode = currentNode;
          Logger.debug("[StateMachine] Handling IfStatement condition.");
          // Évaluer la condition
          final conditionResult = ifNode.expression.accept<Object?>(visitor);

          if (conditionResult is AsyncSuspensionRequest) {
            // La condition est asynchrone, suspendre
            Logger.debug(" [StateMachine] If condition suspended. Waiting...");
            lastResult =
                conditionResult; // Mettre à jour lastResult pour le traitement ci-dessous
            // La logique de suspension générale gérera l'attente et la reprise
          } else if (conditionResult is bool) {
            // Condition synchrone
            if (conditionResult) {
              // Condition vraie: le prochain état est la branche 'then'
              Logger.debug(
                  "[StateMachine] If condition TRUE. Next node is thenBranch: ${ifNode.thenStatement.runtimeType}");
              // Si then est un bloc, prendre la première instruction
              if (ifNode.thenStatement is Block) {
                currentNode =
                    (ifNode.thenStatement as Block).statements.firstOrNull;
              } else {
                currentNode = ifNode.thenStatement;
              }
              // Si la branche then est vide, passer à l'instruction suivante
              if (currentNode == null) {
                Logger.debug(
                    "[StateMachine] If 'then' branch is empty. Finding node after IfStatement.");
                currentNode = _findNextSequentialNode(visitor, ifNode);
              }
              currentState.nextStateIdentifier = currentNode;
              continue; // Relancer la boucle while de la machine à états avec le nouveau nœud
            } else {
              // Condition fausse: vérifier la branche 'else'
              if (ifNode.elseStatement != null) {
                Logger.debug(
                    "[StateMachine] If condition FALSE. Next node is elseBranch: ${ifNode.elseStatement?.runtimeType}");
                // Si else est un bloc, prendre la première instruction
                if (ifNode.elseStatement is Block) {
                  currentNode =
                      (ifNode.elseStatement as Block).statements.firstOrNull;
                } else {
                  currentNode = ifNode.elseStatement;
                }
                // Si la branche else est vide, passer à l'instruction suivante
                if (currentNode == null) {
                  Logger.debug(
                      "[StateMachine] If 'else' branch is empty. Finding node after IfStatement.");
                  currentNode = _findNextSequentialNode(visitor, ifNode);
                }
              } else {
                // Pas de branche else, trouver l'instruction suivante après le if
                Logger.debug(
                    "[StateMachine] If condition FALSE, no else branch. Finding node after IfStatement.");
                currentNode = _findNextSequentialNode(visitor, ifNode);
              }
              currentState.nextStateIdentifier = currentNode;
              continue; // Relancer la boucle while de la machine à états
            }
          } else {
            // La condition n'a retourné ni booléen ni suspension
            throw RuntimeError(
                "If condition must evaluate to a boolean, but got ${conditionResult?.runtimeType}.");
          }
          // Si la condition était suspendue, lastResult contient AsyncSuspensionRequest
          // et sera géré par la logique de suspension plus bas.
        } else {
          if (currentNode is ReturnStatement) {
            try {
              final checkX = visitor.environment.get('x');
              Logger.debug(
                  "[StateMachine] BEFORE ACCEPT ReturnStatement: env=${visitor.environment.hashCode}, x=$checkX (${checkX?.runtimeType})");
            } catch (_) {/* ignore if x not defined */}
          } else if (currentNode is SimpleIdentifier &&
              currentNode.name == 'x') {
            try {
              final checkX = visitor.environment.get('x');
              Logger.debug(
                  "[StateMachine] BEFORE ACCEPT SimpleIdentifier('x'): env=${visitor.environment.hashCode}, x=$checkX (${checkX?.runtimeType})");
            } catch (_) {/* ignore */}
          }
          Logger.debug(
              "[StateMachine] About to accept node ${currentNode.runtimeType}. Visitor env: ${visitor.environment.hashCode}, State env: ${currentState.environment.hashCode}");
          try {
            lastResult = currentNode.accept<Object?>(visitor);
          } on ReturnException {
            rethrow; // Relancer pour que le catch ReturnException plus bas gère le retour
          } catch (error, stackTrace) {
            Logger.debug(
                " [StateMachine] Caught SYNC error during accept(): $error");
            // Erreur synchrone: stocker et tenter de gérer
            currentState.currentError = error;
            currentState.currentStackTrace = stackTrace;
            _handleAsyncError(visitor, currentState, currentNode);
            return; // Sortir, _handleAsyncError s'occupe de la suite
          }
        }

        // Analyser le résultat (peut venir de accept() ou de l'évaluation de condition while)
        if (lastResult is AsyncSuspensionRequest) {
          // Vérifier si accept() a retourné une suspension
          final AsyncSuspensionRequest suspension = lastResult;

          Logger.debug(
              "[StateMachine] Suspension requested (from ${currentNode.runtimeType}). Waiting for Future...");

          // Attacher les callbacks au Future
          suspension.future.then((futureResult) {
            Logger.debug(
                " [StateMachine] Future completed successfully with: $futureResult");
            // Mettre à jour l'état avec le résultat
            currentState.lastAwaitResult = futureResult;
            currentState.lastAwaitError = null;
            currentState.lastAwaitStackTrace = null;
            currentState.currentError = null; // Clear any previous error state
            currentState.currentStackTrace = null;

            if (currentState.pendingFinallyBlock != null) {
              Logger.debug(
                  "[StateMachine] Resuming after await, pending finally found. Executing finally block first.");
              // Le prochain état est le début du bloc finally
              final finallyBlock = currentState.pendingFinallyBlock!;
              currentState.pendingFinallyBlock = null; // Consommé
              currentState.nextStateIdentifier =
                  finallyBlock.statements.firstOrNull;
              if (currentState.nextStateIdentifier == null) {
                // Le bloc finally est vide, trouver le noeud après le try
                Logger.debug(
                    "[StateMachine] Pending finally block was empty. Finding node after TryStatement.");
                if (currentState.activeTryStatement != null) {
                  currentState.nextStateIdentifier = _findNextSequentialNode(
                      visitor, currentState.activeTryStatement!);
                  currentState.activeTryStatement =
                      null; // Fin de la gestion du try
                } else {
                  Logger.warn(
                      "[StateMachine] Cannot find node after empty finally block without active TryStatement.");
                  currentState.nextStateIdentifier = null; // Arrêt prudent
                }
              }
              _scheduleStateMachineRun(visitor, currentState);
              return; // Ne pas déterminer le prochain nœud normalement
            }

            // Determine the next state based on the AST context
            AstNode? nextNodeAfterAwait = _determineNextNodeAfterAwait(
                visitor,
                currentState,
                currentNode!); // The node that caused the suspension
            currentState.nextStateIdentifier = nextNodeAfterAwait;

            // Replanifier l'exécution de la machine à états
            _scheduleStateMachineRun(visitor, currentState);
          }).catchError((Object error, StackTrace stackTrace) {
            Logger.debug(
                " [StateMachine] Future completed with ERROR: $error"); // Ne pas afficher stackTrace ici, trop long
            // Stocker l'erreur et la stack trace dans l'état
            currentState.lastAwaitError = error; // Pour info si qqn l'utilise
            currentState.lastAwaitStackTrace = stackTrace;
            currentState.currentError = error; // Erreur active à gérer
            currentState.currentStackTrace = stackTrace;
            currentState.lastAwaitResult = null; // Pas de résultat valide

            // Essayer de gérer l'erreur (trouver catch/finally)
            _handleAsyncError(visitor, currentState, currentNode!);
            // _handleAsyncError se chargera soit de trouver un catch/finally et de replanifier,
            // soit de compléter le completer avec l'erreur.
          });

          // IMPORTANT: Sortir de la fonction _runStateMachine.
          // L'exécution reprendra dans le .then() ou _handleAsyncError
          return;
        } else {
          // Clear error state if we executed successfully
          currentState.currentError = null;
          currentState.currentStackTrace = null;

          // Déterminer le prochain état séquentiel normal
          // Utiliser _findNextSequentialNode qui gère maintenant try/catch/finally
          final nextNode = _findNextSequentialNode(visitor, currentNode);
          Logger.debug(
              "[StateMachine] Sync execution finished. Next node from _findNext: ${nextNode?.runtimeType}");
          currentNode = nextNode;
          currentState.nextStateIdentifier = currentNode;
        }
      } on ReturnException catch (e) {
        // La fonction a retourné une valeur
        Logger.debug(
            " [StateMachine] Caught ReturnException. Completing with: ${e.value}");
        TryStatement? currentTry =
            currentState.activeTryStatement; // Utiliser currentState
        if (currentTry != null && currentTry.finallyBlock != null) {
          // Vérifier currentTry != null
          Logger.debug(
              "[StateMachine] Return caught inside try with finally. Executing finally first.");
          currentState.returnAfterFinally = e.value; // Utiliser currentState
          currentNode =
              currentTry.finallyBlock!.statements.firstOrNull; // Maintenant sûr
          currentState.nextStateIdentifier =
              currentNode; // Utiliser currentState
          continue; // Exécuter le finally
        }
        if (!currentState.completer.isCompleted) {
          currentState.completer.complete(e.value);
        }
        return; // Arrêter la machine à états
      } catch (error, stackTrace) {
        // Autre erreur pendant l'exécution de l'état (SYNCHRONE)
        Logger.debug(
            " [StateMachine] Caught SYNC Error during non-accept state execution: $error\n$stackTrace");
        // Tenter de gérer via le mécanisme try/catch/finally standard
        currentState.currentError = error; // Utiliser currentState
        currentState.currentStackTrace = stackTrace;
        _handleAsyncError(
            visitor,
            currentState,
            currentNode ??
                currentState.function._body); // Utiliser currentState
        return; // Sortir, _handleAsyncError s'occupe de la suite
      } finally {
        // Restore the visitor environment if it was changed
        visitor.environment = originalVisitorEnv;
        visitor.currentAsyncState = previousAsyncState;
        Logger.debug(
            " [StateMachine] Restored visitor env (${originalVisitorEnv.hashCode}) and async state in finally block.");
      }
    }

    // Gérer un retour qui a été suspendu par un finally
    if (currentState.returnAfterFinally != null &&
        !currentState.completer.isCompleted) {
      Logger.debug(
          " [StateMachine] Completing with stored return value after finally: ${currentState.returnAfterFinally}");
      currentState.completer.complete(currentState.returnAfterFinally);
      return;
    }

    // Si la boucle se termine et qu'une erreur était en cours (non interceptée mais après un finally exécuté)
    if (currentState.currentError != null &&
        !currentState.completer.isCompleted) {
      Logger.debug(
          " [StateMachine] Loop finished, propagating unhandled error after finally: ${currentState.currentError}");
      currentState.completer.completeError(
          currentState.currentError ?? Exception("Unknown error after finally"),
          currentState.currentStackTrace);
    }
    // Si la boucle se termine normally (plus de nœuds à exécuter)
    else if (!currentState.completer.isCompleted) {
      Logger.debug(
          " [StateMachine] Loop finished normally. Completing with last result: $lastResult (State has await result: ${currentState.lastAwaitResult})");

      Object? finalCompletionValue = lastResult;
      if (lastResult == null && currentState.lastAwaitResult != null) {
        finalCompletionValue = currentState.lastAwaitResult;
        Logger.debug(
            " [StateMachine] Loop finished after await. Using await result for completion: $finalCompletionValue");
      }
      currentState.completer.complete(finalCompletionValue);
    }
  }

  // Planifie l'exécution de la machine à états via microtask
  static void _scheduleStateMachineRun(
      InterpreterVisitor visitor, AsyncExecutionState state) {
    // Vérifier si le completer est déjà terminé pour éviter des exécutions inutiles
    if (state.completer.isCompleted) {
      Logger.debug(
          " [_scheduleStateMachineRun] Completer already completed. Skipping schedule.");
      return;
    }
    Future.microtask(() => _runStateMachine(visitor, state))
        .catchError((error, stackTrace) {
      // Catch errors non interceptées par la logique interne de _runStateMachine
      if (!state.completer.isCompleted) {
        Logger.error(
            "[StateMachine] Uncaught async error in microtask: $error\n$stackTrace");
        state.completer.completeError(error, stackTrace);
      }
    });
  }

  static void _handleAsyncError(InterpreterVisitor visitor,
      AsyncExecutionState state, AstNode nodeWhereErrorOccurred) {
    Object? error = state.currentError;
    if (error is InternalInterpreterException) {
      error = error.originalThrownValue;
    }
    final stackTrace = state.currentStackTrace;

    Logger.debug(
        "[_handleAsyncError] Handling error: $error from node: ${nodeWhereErrorOccurred.toSource()}");

    // 1. Rechercher un TryStatement englobant
    TryStatement? enclosingTry =
        _findEnclosingTryStatement(nodeWhereErrorOccurred);

    CatchClause? matchingCatchClause;
    if (enclosingTry != null) {
      Logger.debug(
          " [_handleAsyncError] Found enclosing TryStatement: ${enclosingTry.offset}");
      state.activeTryStatement = enclosingTry; // Marquer comme actif

      // 2. Rechercher une clause Catch correspondante (simplifié: prend la première)
      if (enclosingTry.catchClauses.isNotEmpty) {
        matchingCatchClause = enclosingTry.catchClauses.first;
        Logger.debug(
            " [_handleAsyncError] Found matching CatchClause (simplified: first one).");
      } else {
        Logger.debug(
            " [_handleAsyncError] No CatchClauses found in the TryStatement.");
      }
    }

    if (matchingCatchClause != null && enclosingTry != null) {
      // 3. Erreur interceptée: Préparer le saut vers le bloc Catch
      state.nextStateIdentifier = matchingCatchClause
          .body.statements.firstOrNull; // Début du bloc catch
      // state.pendingFinallyBlock =
      //     enclosingTry.finallyBlock; // Marquer le finally si présent

      // Définir la variable d'exception dans l'environnement du catch
      // Pour l'instant, définissons dans l'environnement actuel (peut causer des collisions)
      final exceptionParameter = matchingCatchClause.exceptionParameter;
      if (exceptionParameter != null) {
        final varName = exceptionParameter.name.lexeme;
        // Utiliser l'environnement de l'état pour définir les variables du catch
        state.environment.define(varName, error);
        Logger.debug(
            " [_handleAsyncError] Defined exception variable '$varName' in environment.");

        // Gérer le paramètre de stack trace s'il existe
        final stackTraceParameter = matchingCatchClause.stackTraceParameter;
        if (stackTraceParameter != null) {
          final stackVarName = stackTraceParameter.name.lexeme;
          state.environment.define(stackVarName, stackTrace);
          Logger.debug(
              "[_handleAsyncError] Defined stack trace variable '$stackVarName' in environment.");
        }
      }

      // Effacer l'état d'erreur car elle est gérée
      state.currentError = null;
      state.currentStackTrace = null;

      // Replanifier l'exécution pour commencer le bloc catch
      Logger.debug(
          " [_handleAsyncError] Scheduling run for CatchClause block.");
      _scheduleStateMachineRun(visitor, state);
    } else {
      // 4. Erreur non interceptée ou pas de try:
      //    a) Vérifier s'il y a un finally à exécuter malgré tout
      if (enclosingTry != null && enclosingTry.finallyBlock != null) {
        Logger.debug(
            " [_handleAsyncError] Error not caught, but finally block exists. Jumping to finally.");
        // Le prochain état est le début du bloc finally
        state.nextStateIdentifier =
            enclosingTry.finallyBlock!.statements.firstOrNull;

        // IMPORTANT: L'erreur reste dans state.currentError pour être relancée APRES le finally.
        // _findNextSequentialNode gèrera la transition *après* le finally.
        // La boucle principale de la machine à états vérifiera state.currentError à la fin.
        _scheduleStateMachineRun(visitor, state);
      } else {
        //    b) Propager l'erreur en complétant le Future principal
        Logger.debug(
            " [_handleAsyncError] Error not caught and no finally block. Propagating error.");
        if (!state.completer.isCompleted) {
          state.completer
              .completeError(error ?? Exception("Unknown error"), stackTrace);
        }
      }
    }
  }

  static TryStatement? _findEnclosingTryStatement(AstNode? node) {
    AstNode? current = node;
    while (current != null) {
      if (current is TryStatement) {
        return current;
      }
      // Ne pas chercher au-delà de la limite de la fonction actuelle
      if (current is FunctionBody) {
        return null;
      }
      current = current.parent;
    }
    return null;
  }

  // Détermine le prochain nœud AST à exécuter après la résolution d'un Future attendu.
  static AstNode? _determineNextNodeAfterAwait(InterpreterVisitor visitor,
      AsyncExecutionState state, AstNode nodeThatCausedSuspension) {
    Object? futureResult = state.lastAwaitResult;
    final currentExecutionEnvironment =
        state.forLoopEnvironment ?? state.environment;
    Logger.debug(
        "[_determineNextNodeAfterAwait] Modifying environment: ${currentExecutionEnvironment.hashCode} (state.environment: ${state.environment.hashCode}, state.forLoopEnvironment: ${state.forLoopEnvironment?.hashCode})");

    Logger.debug(
        "[_determineNextNodeAfterAwait] Resuming after await. Node causing suspension: ${nodeThatCausedSuspension.runtimeType}, Result: $futureResult");

    // Le nœud qui a causé la suspension est soit l'AwaitExpression elle-même,
    // soit un nœud parent (comme WhileStatement) si l'await était dans sa condition.

    // Déterminer le contexte réel de l'await.
    AstNode awaitContextNode;
    Expression? awaitExpression;

    if (nodeThatCausedSuspension is AwaitExpression) {
      awaitExpression = nodeThatCausedSuspension;
      awaitContextNode = nodeThatCausedSuspension.parent ??
          nodeThatCausedSuspension; // Utiliser le parent comme contexte
    } else if (nodeThatCausedSuspension is ExpressionStatement &&
        nodeThatCausedSuspension.expression is AwaitExpression) {
      // Cas où l'await était directement l'expression d'une ExpressionStatement
      awaitExpression = nodeThatCausedSuspension.expression as AwaitExpression;
      awaitContextNode = nodeThatCausedSuspension;
    } else if (nodeThatCausedSuspension is WhileStatement &&
        nodeThatCausedSuspension.condition is AwaitExpression) {
      // Cas spécial: l'await était directement la condition du while
      awaitContextNode =
          nodeThatCausedSuspension; // Le WhileStatement est le contexte
      awaitExpression = nodeThatCausedSuspension.condition as AwaitExpression;
    } else if (nodeThatCausedSuspension is DoStatement &&
        nodeThatCausedSuspension.condition is AwaitExpression) {
      // Cas spécial: l'await était directement la condition du do-while
      awaitContextNode =
          nodeThatCausedSuspension; // Le DoStatement est le contexte
      awaitExpression = nodeThatCausedSuspension.condition as AwaitExpression;
    } else {
      // On ne sait pas comment extraire l'await, utiliser le nœud directement
      // (peut mener à des erreurs si la logique ci-dessous ne gère pas ce nœud)
      awaitContextNode = nodeThatCausedSuspension;
      awaitExpression = null; // On ne sait pas où était l'await exact
      Logger.warn(
          "[_determineNextNodeAfterAwait] Could not determine exact await context for node type ${nodeThatCausedSuspension.runtimeType}. Using node as context.");
    }

    Logger.debug(
        "[_determineNextNodeAfterAwait] Determined await context: ${awaitContextNode.runtimeType}");

    // Logique basée sur le type du nœud qui contenait l'await (awaitContextNode)

    // Cas 1: Déclaration de variable (var x = await f();)
    if (awaitContextNode is VariableDeclarationStatement) {
      // This case handles when the await occurs directly in the initializer.
      // It's triggered when `visitVariableDeclarationList` returns the suspension.
      // Assign the result to the variable(s)
      final varList = awaitContextNode.variables;
      // Find the *specific* variable whose initializer was the awaitExpression
      // Note: awaitExpression might be null if context couldn't be refined.
      // We assume the *first* variable in the list if awaitExpression is null or not found directly.
      // This might be fragile if multiple variables have initializers.
      VariableDeclaration? targetVar = varList.variables.firstWhereOrNull((v) =>
          v.initializer == awaitExpression ||
          (v.initializer is ParenthesizedExpression &&
              (v.initializer as ParenthesizedExpression).expression ==
                  awaitExpression));
      targetVar ??= varList.variables.first; // Fallback to first
      if (targetVar.initializer is PropertyAccess) {
        final propertyAccess = targetVar.initializer as PropertyAccess;
        if (propertyAccess.target is ParenthesizedExpression) {
          // On veut accéder à la propriété sur la valeur résolue du Future
          final propertyName = propertyAccess.propertyName.name;
          final (bridgedInstance, isBridgedInstance) =
              visitor.toBridgedInstance(futureResult);
          if (isBridgedInstance) {
            final getterAdapter = bridgedInstance!.bridgedClass
                .findInstanceGetterAdapter(propertyName);
            if (getterAdapter != null) {
              final getterResult =
                  getterAdapter(visitor, bridgedInstance.nativeObject);

              futureResult = getterResult;
            }

            final methodAdapter = bridgedInstance.bridgedClass
                .findInstanceMethodAdapter(propertyName);
            if (methodAdapter != null) {
              // Return a callable bound to the instance
              final boundCallable = BridgedMethodCallable(
                  bridgedInstance, methodAdapter, propertyName);

              futureResult = boundCallable;
            }
          }
        }
      }
      currentExecutionEnvironment.define(targetVar.name.lexeme, futureResult);
      Logger.debug(
          " [_determineNextNodeAfterAwait] Defined awaited result for variable '${targetVar.name.lexeme}' = $futureResult in env ${currentExecutionEnvironment.hashCode} (Case 1). Finding next node.");
      Logger.debug(
          " [_determineNextNodeAfterAwait] Assigned awaited result to variable '${targetVar.name.lexeme}' (Case 1). Finding next node.");

      if (visitor.environment != currentExecutionEnvironment) {
        Logger.debug(
            " [_determineNextNodeAfterAwait] Updating visitor environment from ${visitor.environment.hashCode} to ${currentExecutionEnvironment.hashCode}");
        visitor.environment = currentExecutionEnvironment;
      }

      // Trouver le prochain nœud séquentiel à exécuter APRES le nœud de contexte de l'await.
      return _findNextSequentialNode(visitor, awaitContextNode);
    }

    // NOUVEAU CAS 1.5: Reprise après await dans l'initialiseur d'une déclaration DANS un bloc.
    // Ceci arrive quand le `nodeThatCausedSuspension` est l'ExpressionStatement ou le VariableDeclarationStatement lui-même,
    // mais `_determineNextNodeAfterAwait` est appelé *après* que le Future se résolve.
    else if (nodeThatCausedSuspension is VariableDeclarationStatement) {
      final varDeclStatement = nodeThatCausedSuspension;
      final varList = varDeclStatement.variables;
      // Comme dans le Cas 1, trouver la variable qui attendait.
      VariableDeclaration? targetVar = varList.variables.firstWhereOrNull(
          (v) => v.initializer is AwaitExpression
          // We need a better way to link the suspension back to the AwaitExpression node
          // For now, assume the FIRST variable with an AwaitExpression initializer in this statement
          );
      targetVar ??=
          varList.variables.first; // Fallback: assume it was the first variable

      // Utiliser define() car la variable n'a pas été définie lors de la visite initiale
      currentExecutionEnvironment.define(targetVar.name.lexeme, futureResult);
      // SPECULATIVE FIX: Try assigning immediately after defining
      try {
        currentExecutionEnvironment.assign(targetVar.name.lexeme, futureResult);
      } catch (assignError) {
        Logger.warn(
            "[_determineNextNodeAfterAwait] Speculative assign after define failed: $assignError");
      }
      // ADD DEBUG:
      try {
        final checkValue =
            currentExecutionEnvironment.get(targetVar.name.lexeme);
        Logger.debug(
            " [_determineNextNodeAfterAwait] Check after define+assign: '${targetVar.name.lexeme}' in env ${currentExecutionEnvironment.hashCode} is $checkValue (${checkValue?.runtimeType}) <Expected: $futureResult>");
      } catch (e) {
        Logger.debug(
            " [_determineNextNodeAfterAwait] Check after define+assign FAILED for '${targetVar.name.lexeme}': $e");
      }
      // END ADD DEBUG
      Logger.debug(
          " [_determineNextNodeAfterAwait] Defined/Assigned variable '${targetVar.name.lexeme}' = $futureResult (Case 1.5). Finding next node.");

      // Trouver l'instruction suivante APRES cette déclaration
      return _findNextSequentialNode(visitor, varDeclStatement);
    }

    // Cas 2: Instruction d'expression (await f(); ou var x = await f(); ou x = await f(); etc.)
    else if (awaitContextNode is ExpressionStatement) {
      // Check the type of expression inside the statement
      final expression = awaitContextNode.expression;

      if (expression is AwaitExpression) {
        // Simple case: await f(); The result is ignored.
        Logger.debug(
            " [_determineNextNodeAfterAwait] Resumed from ExpressionStatement (AwaitExpression). Finding next sequential node.");
        return _findNextSequentialNode(visitor, awaitContextNode);
      } else if (expression is VariableDeclarationList) {
        // Case: var awaitedValue = await getValue(i);
        // The suspension actually happened *during* the visitVariableDeclarationList call,
        // but _determineNextNodeAfterAwait sees the ExpressionStatement as the context.
        Logger.debug(
            " [_determineNextNodeAfterAwait] Resumed from ExpressionStatement (VariableDeclarationList). Defining variable.");

        // Cast expression to VariableDeclarationList to access variables
        final varList = expression as VariableDeclarationList;

        // Find the variable that had the await (assuming first with AwaitExpression initializer)
        VariableDeclaration? targetVar = varList.variables
            .firstWhereOrNull((v) => v.initializer is AwaitExpression
                // Need a reliable way to know which specific await finished
                // Fallback: assume first variable if none match perfectly
                );
        targetVar ??= varList.variables.first;

        // Assign the result in the correct environment (the loop environment if inside one)
        final currentEnv =
            state.forLoopEnvironment ?? currentExecutionEnvironment;
        // Utiliser define() car la variable n'a pas été définie lors de la visite initiale
        currentEnv.define(targetVar.name.lexeme, futureResult);
        // SPECULATIVE FIX: Try assigning immediately after defining
        try {
          currentEnv.assign(targetVar.name.lexeme, futureResult);
        } catch (assignError) {
          Logger.warn(
              "[_determineNextNodeAfterAwait] Speculative assign after define failed (VarDeclList): $assignError");
        }
        // ADD DEBUG:
        try {
          final checkValue2 = currentEnv.get(targetVar.name.lexeme);
          Logger.debug(
              "[_determineNextNodeAfterAwait] Check after define+assign: '${targetVar.name.lexeme}' in env ${currentEnv.hashCode} is $checkValue2 (${checkValue2?.runtimeType}) <Expected: $futureResult>");
        } catch (e) {
          Logger.debug(
              "[_determineNextNodeAfterAwait] Check after define+assign FAILED for '${targetVar.name.lexeme}': $e");
        }
        // END ADD DEBUG
        Logger.debug(
            " [_determineNextNodeAfterAwait] Defined/Assigned variable '${targetVar.name.lexeme}' = $futureResult (Case 2 - VarDecl). Finding next node.");

        // Find the next statement after this ExpressionStatement
        return _findNextSequentialNode(visitor, awaitContextNode);
      } else if (expression is AssignmentExpression) {
        // Case: x += await f(); or x = await f();
        // This is the primary handler now as the context is the ExpressionStatement.
        final assignmentNode = expression; // Already cast
        final resolvedRhs = state.lastAwaitResult; // La valeur résolue
        final operatorType = assignmentNode.operator.type;
        final lhs = assignmentNode.leftHandSide;
        final currentEnv =
            state.forLoopEnvironment ?? currentExecutionEnvironment;

        Logger.debug(
            " [_determineNextNodeAfterAwait] Resuming ExpressionStatement(AssignmentExpression Op: $operatorType). RHS: $resolvedRhs (${resolvedRhs?.runtimeType})");

        // Déterminer le nœud suivant APRÈS l'ExpressionStatement
        final AstNode? nextNode =
            _findNextSequentialNode(visitor, awaitContextNode);

        if (operatorType == TokenType.EQ) {
          if (lhs is SimpleIdentifier) {
            final varName = lhs.name;
            try {
              currentEnv.assign(varName, resolvedRhs);
              Logger.debug(
                  "[_determineNextNodeAfterAwait] Assigned $varName = $resolvedRhs (Case 2 - Simple Assign)");
            } catch (e) {
              Logger.error("Assigning simple await result: $e");
            }
          } else {
            Logger.warn(
                "[_determineNextNodeAfterAwait] Resumption for simple assignment to complex LHS not implemented (Case 2).");
            // Tentative: Ré-exécuter l'assignation maintenant que RHS est connu (peut échouer)
            // Cette approche est risquée car elle ré-évalue le LHS.
            final originalVisitorEnv = visitor.environment;
            try {
              visitor.environment = currentEnv;
              assignmentNode
                  .accept(visitor); // Might re-trigger await if LHS is complex?
            } catch (e) {
              Logger.warn("Re-visiting simple assignment failed: $e");
            } finally {
              visitor.environment = originalVisitorEnv;
            }
          }
        } else {
          final originalVisitorEnv = visitor.environment;
          Object? lhsValue;
          try {
            visitor.environment = currentEnv; // Use correct scope
            // IMPORTANT: Re-evaluating LHS here. Assumes it's safe/idempotent.
            lhsValue = lhs.accept<Object?>(visitor);
            Logger.debug(
                " [_determineNextNodeAfterAwait] Re-evaluated LHS for compound assign to: $lhsValue (${lhsValue?.runtimeType})");
          } catch (e, s) {
            Logger.error("Re-evaluating LHS for compound assign: $e\n$s");
            if (!state.completer.isCompleted) {
              state.completer.completeError(e, s);
            }
            return null; // Stop
          } finally {
            visitor.environment = originalVisitorEnv;
          }

          // Calculate the result
          Object? resultValue;
          try {
            // Call computeCompoundValue from the visitor instance
            resultValue = visitor.computeCompoundValue(
                lhsValue, resolvedRhs, operatorType);
            Logger.debug(
                " [_determineNextNodeAfterAwait] Computed compound value: $resultValue");
          } catch (e, s) {
            Logger.error("Computing compound value after await: $e\n$s");
            if (!state.completer.isCompleted) {
              state.completer.completeError(e, s);
            }
            return null; // Stop
          }

          // Assign the computed result back
          if (lhs is SimpleIdentifier) {
            final varName = lhs.name;
            try {
              currentEnv.assign(varName, resultValue);
              Logger.debug(
                  "[_determineNextNodeAfterAwait] Assigned $varName = $resultValue (Case 2 - Compound Assign)");
            } catch (e) {
              Logger.error("Assigning compound await result: $e");
            }
          } else {
            Logger.warn(
                "[_determineNextNodeAfterAwait] Resumption for compound assignment to complex LHS not implemented (Case 2).");
          }
        }
        // Return the next node found earlier
        return nextNode;
      } else {
        // Other expression types within ExpressionStatement after await?
        Logger.warn(
            "[_determineNextNodeAfterAwait] Resumed from ExpressionStatement with unexpected inner expression: ${expression.runtimeType}. Finding next sequential node.");
        return _findNextSequentialNode(visitor, awaitContextNode);
      }
    }

    // Cas 3: Instruction return (return await f();)
    else if (awaitContextNode is ReturnStatement && awaitExpression != null) {
      // ... (logique inchangée) ...
    }

    // Cas 4: Corps de fonction expression (=> await f();)
    else if (awaitContextNode is ExpressionFunctionBody &&
        awaitExpression != null) {
      // ... (logique inchangée) ...
    }

    // Cas 5: Assignation (x = await f(); ou x += await f();)
    else if (awaitContextNode is AssignmentExpression) {
      final assignmentNode = awaitContextNode;
      final resolvedRhs = state.lastAwaitResult; // La valeur résolue du Future
      final operatorType = assignmentNode.operator.type;
      final lhs = assignmentNode.leftHandSide;
      // Utiliser l'environnement correct (celui de la boucle si applicable)
      final currentEnv =
          state.forLoopEnvironment ?? currentExecutionEnvironment;

      Logger.debug(
          " [_determineNextNodeAfterAwait] Resuming AssignmentExpression (Operator: $operatorType). RHS resolved to: $resolvedRhs (${resolvedRhs?.runtimeType})");

      // Déterminer le prochain nœud AVANT de faire l'assignation (car _findNext peut dépendre du parent)
      AstNode? parentStatement = assignmentNode;
      while (parentStatement != null && parentStatement is! Statement) {
        parentStatement = parentStatement.parent;
      }
      final AstNode? nextNode = (parentStatement is Statement)
          ? _findNextSequentialNode(visitor, parentStatement)
          : null; // Si on ne trouve pas le statement parent, on arrêtera

      if (operatorType == TokenType.EQ) {
        if (lhs is SimpleIdentifier) {
          final varName = lhs.name;
          try {
            currentEnv.assign(varName, resolvedRhs);
            Logger.debug(
                " [_determineNextNodeAfterAwait] Assigned $varName = $resolvedRhs (Simple Assign)");
          } catch (e) {
            Logger.error("Assigning simple await result: $e");
          }
        } else {
          Logger.warn(
              "[_determineNextNodeAfterAwait] Resumption for simple assignment to complex LHS not fully implemented. Trying standard assign visit.");

          final originalVisitorEnv = visitor.environment;
          try {
            visitor.environment = currentEnv;
            assignmentNode
                .accept(visitor); // Might re-trigger await if LHS is complex?
          } catch (e) {
            Logger.error("Re-visiting simple assignment failed: $e");
          } finally {
            visitor.environment = originalVisitorEnv;
          }
        }
      } else {
        final originalVisitorEnv = visitor.environment;
        Object? lhsValue;
        try {
          visitor.environment = currentEnv; // Use correct scope for LHS
          lhsValue = lhs.accept<Object?>(visitor);
          Logger.debug(
              "[_determineNextNodeAfterAwait] Re-evaluated LHS for compound assignment to: $lhsValue (${lhsValue?.runtimeType})");
        } catch (e, s) {
          Logger.error("Re-evaluating LHS for compound assign: $e\n$s");
          // Cannot proceed without LHS value
          if (!state.completer.isCompleted) state.completer.completeError(e, s);
          return null; // Stop
        } finally {
          visitor.environment = originalVisitorEnv;
        }

        // Calculate the result using computeCompoundValue
        Object? resultValue;
        try {
          // computeCompoundValue needs the visitor for potential extension methods
          resultValue =
              visitor.computeCompoundValue(lhsValue, resolvedRhs, operatorType);
        } catch (e, s) {
          Logger.error("Computing compound value after await: $e\n$s");
          if (!state.completer.isCompleted) state.completer.completeError(e, s);
          return null; // Stop
        }

        // Assign the computed result back to the LHS target
        if (lhs is SimpleIdentifier) {
          final varName = lhs.name;
          try {
            currentEnv.assign(varName, resultValue);
            Logger.debug(
                " [_determineNextNodeAfterAwait] Assigned $varName = $resultValue (Compound Assign)");
          } catch (e) {
            Logger.error("Assigning compound await result: $e");
          }
        } else {
          Logger.warn(
              "[_determineNextNodeAfterAwait] Resumption for compound assignment to complex LHS not fully implemented. Trying standard assign visit.");
          // Tentative: Ré-exécuter l'assignation avec la valeur calculée (peut échouer)
          // Need to fake the RHS with the computed value somehow? This is hard.
          // For now, let it fail or proceed without assigning complex LHS.
        }
      }

      // Return the next node determined earlier
      if (nextNode == null && parentStatement is! Statement) {
        Logger.warn(
            "[_determineNextNodeAfterAwait] Could not find parent statement or next node for AssignmentExpression after await. Stopping.");
      }
      return nextNode;
    }

    // Cas 6: Condition If (if (await f()))
    else if (awaitContextNode is IfStatement && awaitExpression != null) {
      // ... (logique inchangée, mais s'assurer qu'elle utilise awaitContextNode) ...
    } else if (awaitContextNode is WhileStatement) {
      // L'await était dans la condition
      final conditionResult = state.lastAwaitResult;
      Logger.debug(
          " [_determineNextNodeAfterAwait] Resuming While condition with awaited result: $conditionResult");

      if (conditionResult is! bool) {
        final error = RuntimeError(
            "While condition (after await) must evaluate to a boolean, but got ${conditionResult?.runtimeType}.");
        if (!state.completer.isCompleted) {
          state.completer.completeError(error);
        }
        return null;
      }

      if (conditionResult) {
        // Condition vraie: le prochain état est le corps de la boucle
        Logger.debug(
            " [_determineNextNodeAfterAwait] While condition TRUE. Next node is body: ${awaitContextNode.body.runtimeType}");
        if (awaitContextNode.body is Block) {
          return (awaitContextNode.body as Block).statements.firstOrNull;
        } else {
          return awaitContextNode.body;
        }
      } else {
        // Condition fausse: trouver l'instruction suivante après le while
        Logger.debug(
            " [_determineNextNodeAfterAwait] While condition FALSE. Finding node after while.");
        return _findNextSequentialNode(visitor, awaitContextNode);
      }
    } else if (awaitContextNode is DoStatement) {
      // L'await était dans la condition
      final conditionResult = state.lastAwaitResult;
      Logger.debug(
          " [_determineNextNodeAfterAwait] Resuming DoWhile condition with awaited result: $conditionResult");

      if (conditionResult is! bool) {
        final error = RuntimeError(
            "DoWhile condition (after await) must evaluate to a boolean, but got ${conditionResult?.runtimeType}.");
        if (!state.completer.isCompleted) {
          state.completer.completeError(error);
        }
        return null;
      }

      if (conditionResult) {
        // Condition vraie: le prochain état est le début du corps de la boucle
        Logger.debug(
            " [_determineNextNodeAfterAwait] DoWhile condition TRUE. Next node is body: ${awaitContextNode.body.runtimeType}");
        if (awaitContextNode.body is Block) {
          return (awaitContextNode.body as Block).statements.firstOrNull;
        } else {
          return awaitContextNode.body;
        }
      } else {
        // Condition fausse: trouver l'instruction suivante après le do-while
        Logger.debug(
            " [_determineNextNodeAfterAwait] DoWhile condition FALSE. Finding node after do-while.");
        return _findNextSequentialNode(visitor, awaitContextNode);
      }
    } else if (awaitContextNode is IfStatement) {
      // L'await était dans la condition
      final ifNode = awaitContextNode;
      final conditionResult = state.lastAwaitResult;
      Logger.debug(
          " [_determineNextNodeAfterAwait] Resuming If condition with awaited result: $conditionResult");

      if (conditionResult is! bool) {
        final error = RuntimeError(
            "If condition (after await) must evaluate to a boolean, but got ${conditionResult?.runtimeType}.");
        if (!state.completer.isCompleted) {
          state.completer.completeError(error);
        }
        return null; // Arrêter
      }

      if (conditionResult) {
        // Condition vraie: le prochain état est la branche 'then'
        Logger.debug(
            " [_determineNextNodeAfterAwait] If condition TRUE. Next node is thenBranch: ${ifNode.thenStatement.runtimeType}");
        if (ifNode.thenStatement is Block) {
          return (ifNode.thenStatement as Block).statements.firstOrNull;
        } else {
          return ifNode.thenStatement;
        }
      } else {
        // Condition fausse: vérifier la branche 'else'
        if (ifNode.elseStatement != null) {
          Logger.debug(
              "[_determineNextNodeAfterAwait] If condition FALSE. Next node is elseBranch: ${ifNode.elseStatement?.runtimeType}");
          if (ifNode.elseStatement is Block) {
            return (ifNode.elseStatement as Block).statements.firstOrNull;
          } else {
            return ifNode.elseStatement;
          }
        } else {
          // Pas de branche else, trouver l'instruction suivante après le if
          Logger.debug(
              "[_determineNextNodeAfterAwait] If condition FALSE, no else branch. Finding node after IfStatement.");
          return _findNextSequentialNode(visitor, ifNode);
        }
      }
    } else if (awaitContextNode is ForStatement &&
        (awaitContextNode.forLoopParts is ForPartsWithDeclarations ||
            awaitContextNode.forLoopParts is ForPartsWithExpression)) {
      final forNode = awaitContextNode;
      // Utiliser nodeThatCausedSuspension pour trouver où l'await s'est produit
      // AstNode? nodeThatContainedAwait = nodeThatCausedSuspension; // Peut être AwaitExpression ou ForStatement si await dans condition/updater
      final awaitResult = state.lastAwaitResult;

      Logger.debug(
          " [_determineNextNodeAfterAwait] Resuming For loop. Suspension node: ${nodeThatCausedSuspension.runtimeType}, Context node: ${awaitContextNode.runtimeType}, Result: $awaitResult");

      // Check if we are resuming specifically from initializer suspension
      // We know we suspended during initialization if:
      // 1. The context node is the ForStatement itself.
      // 2. The loop environment exists (currentState.forLoopEnvironment != null).
      // 3. The loop is marked as initialized (currentState.forLoopInitialized == true)
      //    (because the SM marks it initialized *before* waiting on the init suspension).
      // 4. We haven't already processed the initializer resumption (currentState.resumedFromInitializer == false).
      bool resumingFromInitializer = (awaitContextNode ==
              forNode) && // Suspended *while processing* the ForStatement node
          state.forLoopEnvironment != null &&
          state.forLoopInitialized && // Was set before waiting
          !state.resumedFromInitializer; // Haven't resumed the init part yet

      if (resumingFromInitializer) {
        Logger.debug(
            " [_determineNextNodeAfterAwait] Detected resumption from For initializer. Assigning result and proceeding to condition.");

        // Assign the result to the loop variable
        if (state.forLoopEnvironment == null) {
          throw StateError(
              "Internal error: For loop environment null after initializer await resumption.");
        }
        final parts = forNode.forLoopParts;
        if (parts is ForPartsWithDeclarations) {
          // Assuming a single variable declaration for now, as before
          if (parts.variables.variables.length == 1) {
            final loopVarName = parts.variables.variables.first.name.lexeme;
            // Assign the actual result now. The var was defined as null previously by visitVariableDeclarationList.
            state.forLoopEnvironment!.assign(loopVarName, awaitResult);
            Logger.debug(
                " [_determineNextNodeAfterAwait] Assigned awaited result $awaitResult to for loop variable '$loopVarName' in env ${currentExecutionEnvironment.hashCode}.");
          } else {
            throw UnimplementedError(
                "Async initialization for multiple variables in a single 'for' declaration not yet supported.");
          }
        } else if (parts is ForPartsWithExpression) {
          // If init is an expression like `i = await f()`, AssignmentExpression should handle it.
          // If init is just `await f()`, the result is discarded, just proceed.
          Logger.debug(
              "[_determineNextNodeAfterAwait] Resumed from ForPartsWithExpression initializer (await result ignored or handled by AssignmentExpression).");
        }

        // Mark that we have now processed the initializer resumption
        state.resumedFromInitializer = true;

        // Next state is the ForStatement itself to evaluate the condition
        return forNode;
      } else {
        // Resumption wasn't from initializer, try condition/updater/body logic
        AstNode? nodeThatContainedAwait =
            nodeThatCausedSuspension; // Where did the await physically occur?
        bool inCondition = false;
        bool inUpdater = false;
        final parts = forNode.forLoopParts;

        // Try detecting condition await more reliably
        if ((parts is ForPartsWithDeclarations &&
                parts.condition == nodeThatContainedAwait) ||
            (parts is ForPartsWithExpression &&
                parts.condition == nodeThatContainedAwait)) {
          inCondition = true;
        }
        // Try detecting updater await more reliably
        else if ((parts is ForPartsWithDeclarations) ||
            (parts is ForPartsWithExpression)) {
          final NodeList<Expression> currentUpdaters =
              (parts is ForPartsWithDeclarations)
                  ? parts.updaters
                  : (parts as ForPartsWithExpression).updaters;
          AstNode? current = nodeThatContainedAwait;
          while (current != null &&
              !(current.parent is NodeList<Expression> &&
                  (current.parent as NodeList<Expression>) ==
                      currentUpdaters)) {
            current = current.parent;
          }
          if (current != null) {
            // Found the await expression within the updaters list
            inUpdater = true;
          }
        }

        if (inCondition) {
          Logger.debug(
              "[_determineNextNodeAfterAwait] Resumed from For condition. Result: $awaitResult");
          if (awaitResult is! bool) {
            final error = RuntimeError(
                "For loop condition (after await) must be a boolean, but got ${awaitResult?.runtimeType}");
            if (!state.completer.isCompleted) {
              state.completer.completeError(error);
            }
            return null; // Arrêter
          }
          if (awaitResult) {
            // Condition vraie -> Aller au corps
            Logger.debug(
                " [_determineNextNodeAfterAwait] For condition TRUE. Next node is body.");
            if (forNode.body is Block) {
              return (forNode.body as Block).statements.firstOrNull;
            } else {
              return forNode.body;
            }
          } else {
            // Condition fausse -> Sortir de la boucle
            Logger.debug(
                " [_determineNextNodeAfterAwait] For condition FALSE. Finding node after loop.");
            state.forLoopInitialized = false; // Nettoyer état
            state.forLoopEnvironment = null;
            return _findNextSequentialNode(visitor, forNode);
          }
        } else if (inUpdater) {
          Logger.debug(
              "[_determineNextNodeAfterAwait] Resumed from For updater. Proceeding to condition check.");
          // After updater, always go back to ForStatement for condition check
          return forNode;
        } else {
          // If not initializer, condition, or updater, assume it was in the body.
          Logger.debug(
              "[_determineNextNodeAfterAwait] Assuming await was in For loop body. Finding next node after suspension point: ${nodeThatCausedSuspension.runtimeType}. Visitor env: ${visitor.environment.hashCode}");
          // Reset the initializer flag just in case
          state.resumedFromInitializer = false;
          // Find the node *after* the statement that contained the await
          AstNode? parentStatement = nodeThatCausedSuspension;
          // Climb up until we find the Statement that is a direct child of the loop's body Block,
          // or the body itself if it's not a Block.
          while (parentStatement != null &&
              parentStatement.parent !=
                  forNode
                      .body && // Stop if parent is the body itself (non-block)
              !(parentStatement.parent is Block &&
                  parentStatement.parent ==
                      forNode.body)) // Stop if parent is the body block
          {
            parentStatement = parentStatement.parent;
          }

          if (parentStatement != null && parentStatement is Statement) {
            // Found the statement within the body that contained the await
            AstNode? nextInBody =
                _findNextSequentialNode(visitor, parentStatement);
            Logger.debug(
                " [_determineNextNodeAfterAwait] Found parent statement in body: ${parentStatement.runtimeType}. Next sequential node is: ${nextInBody?.runtimeType}");
            // If _findNextSequentialNode returns the ForStatement, it means we finished the body
            return nextInBody;
          } else {
            // Could not find the statement in the body, maybe await was the body itself?
            if (forNode.body == nodeThatCausedSuspension) {
              Logger.debug(
                  "[_determineNextNodeAfterAwait] Await was the single statement body of the For loop.");
              // After single statement body, go back to ForStatement for updater/condition
              return forNode;
            } else {
              // Fallback / Error case
              Logger.warn(
                  "[_determineNextNodeAfterAwait] Could not determine sequence after await in For loop body. Context: ${awaitContextNode.runtimeType}, Suspension: ${nodeThatCausedSuspension.runtimeType}. Stopping.");
              state.forLoopInitialized = false;
              state.forLoopEnvironment = null;
              return null;
            }
          }
        }
      }
    }

    Logger.warn(
        "_determineNextNodeAfterAwait - Unhandled await context: ${awaitContextNode.runtimeType} (suspension from: ${nodeThatCausedSuspension.runtimeType}). Stopping state machine.");
    return null; // Arrête la machine par défaut
  }

  // Implémentation de la logique pour trouver le prochain nœud séquentiel
  static AstNode? _findNextSequentialNode(
      InterpreterVisitor visitor, AstNode currentNode) {
    AstNode? parent = currentNode.parent;
    AsyncExecutionState? state =
        visitor.currentAsyncState; // Peut être null si non async

    Logger.debug(
        "[_findNextSequentialNode] Finding next node after: ${currentNode.runtimeType} (parent: ${parent?.runtimeType})");

    // Gérer la fin d'une instruction dans un bloc
    if (currentNode is Statement && parent is Block) {
      final block = parent;
      final index = block.statements.indexOf(currentNode);
      bool isLastStatement =
          (index != -1 && index == block.statements.length - 1);

      if (!isLastStatement && index != -1) {
        // Cas simple : instruction suivante dans le même bloc
        Logger.debug(
            " [_findNextSequentialNode] Next sequential node in block: ${block.statements[index + 1].runtimeType}");
        return block.statements[index + 1];
      } else if (isLastStatement) {
        // C'était la dernière instruction du bloc. Que faire ensuite ?
        Logger.debug(" [_findNextSequentialNode] Reached end of a Block.");

        AstNode? blockParent = block.parent;

        // Cas 1: Fin d'un bloc Try
        if (blockParent is TryStatement && blockParent.body == block) {
          Logger.debug("[_findNextSequentialNode] End of Try block.");
          // Y a-t-il des clauses Catch ?
          if (blockParent.catchClauses.isNotEmpty) {
            // S'il y a des clauses catch, l'exécution NORMALE les saute.
            // Elles ne sont atteintes que par une exception gérée par _handleAsyncError.
            // Donc, après le try, on cherche le finally ou le code suivant.
            Logger.debug(
                " [_findNextSequentialNode] Try block finished normally, skipping catches.");
          }
          // Vérifier s'il y a un bloc finally
          if (blockParent.finallyBlock != null) {
            Logger.debug(
                " [_findNextSequentialNode] Found finally block after Try. Jumping to finally.");
            // Prochain noeud est le début du finally
            final firstFinallyStmt =
                blockParent.finallyBlock!.statements.firstOrNull;
            if (firstFinallyStmt != null) {
              return firstFinallyStmt;
            } else {
              // Bloc finally vide, trouver ce qui suit le TryStatement
              Logger.debug(
                  "[_findNextSequentialNode] Finally block is empty. Finding node after TryStatement.");
              if (state != null) {
                state.activeTryStatement = null; // Fin de la gestion du try
              }
              return _findNextSequentialNode(visitor, blockParent);
            }
          } else {
            // Pas de catch (normalement sauté) et pas de finally, sauter après le TryStatement entier
            Logger.debug(
                " [_findNextSequentialNode] No finally block after Try. Finding node after TryStatement.");
            if (state != null) {
              state.activeTryStatement = null; // Fin de la gestion du try
            }
            return _findNextSequentialNode(visitor, blockParent);
          }
        }
        // Cas 2: Fin d'un bloc Catch
        else if (blockParent is CatchClause) {
          Logger.debug("[_findNextSequentialNode] End of Catch block.");
          TryStatement? tryStatement = _findEnclosingTryStatement(blockParent);
          // Après un catch, on doit TOUJOURS exécuter le finally s'il existe
          if (tryStatement != null && tryStatement.finallyBlock != null) {
            Logger.debug(
                " [_findNextSequentialNode] Found finally block after Catch. Jumping to finally.");
            // Prochain noeud est le début du finally
            final firstFinallyStmt =
                tryStatement.finallyBlock!.statements.firstOrNull;
            if (firstFinallyStmt != null) {
              return firstFinallyStmt;
            } else {
              // Bloc finally vide, trouver ce qui suit le TryStatement
              Logger.debug(
                  "[_findNextSequentialNode] Finally block is empty (after catch). Finding node after TryStatement.");
              if (state != null) {
                state.activeTryStatement = null; // Fin de la gestion du try
              }
              return _findNextSequentialNode(visitor, tryStatement);
            }
          } else {
            // Pas de finally, sauter après le TryStatement entier
            Logger.debug(
                " [_findNextSequentialNode] No finally block after Catch. Finding node after TryStatement.");
            if (state != null) {
              state.activeTryStatement = null; // Fin de la gestion du try
            }
            return _findNextSequentialNode(
                visitor,
                tryStatement ??
                    blockParent); // Remonter depuis le Try ou le Catch
          }
        }
        // Cas 3: Fin d'un bloc Finally
        else if (blockParent is TryStatement &&
            blockParent.finallyBlock == block) {
          Logger.debug("[_findNextSequentialNode] End of Finally block.");
          // Après un finally, on cherche le noeud suivant après le TryStatement entier
          // Si une erreur était en cours, elle sera relancée par la boucle principale.
          if (state != null) {
            state.activeTryStatement = null; // Fin de la gestion du try
          }
          return _findNextSequentialNode(visitor, blockParent);
        }
        // Cas 4: Fin d'un bloc dans une boucle (While, DoWhile, For, ForIn)
        else if (blockParent is WhileStatement && blockParent.body == block) {
          Logger.debug(
              "[_findNextSequentialNode] End of While body Block. Returning WhileStatement node.");
          return blockParent; // Revenir au WhileStatement pour réévaluer la condition
        } else if (blockParent is DoStatement && blockParent.body == block) {
          Logger.debug(
              "[_findNextSequentialNode] End of DoWhile body Block. Returning DoStatement node.");
          return blockParent; // Revenir au DoStatement pour évaluer la condition
        } else if (blockParent is ForStatement && blockParent.body == block) {
          // S'applique aux For standard et For-In
          Logger.debug(
              "[_findNextSequentialNode] End of For/For-In body Block. Returning ForStatement node.");
          return blockParent; // Revenir au ForStatement pour l'itération/condition suivante
        }

        // Cas 5: Fin d'un bloc If/Else
        else if (blockParent is IfStatement) {
          // Que ce soit la fin du 'then' ou du 'else', on cherche après le IfStatement entier
          Logger.debug(
              "[_findNextSequentialNode] End of If/Else Block. Finding node after IfStatement.");
          return _findNextSequentialNode(visitor, blockParent);
        }

        // Cas générique: fin d'un bloc non géré spécifiquement ci-dessus
        else {
          Logger.debug(
              "[_findNextSequentialNode] End of generic Block (parent: ${blockParent?.runtimeType}). Finding node after parent Block.");
          // Remonter au parent du bloc pour trouver la suite
          return _findNextSequentialNode(visitor, block);
        }
      }
      // Si index == -1 (ne devrait pas arriver sauf erreur interne), remonter
      else {
        Logger.warn(
            "[_findNextSequentialNode] Statement not found in parent block? Finding node after parent block.");
        return _findNextSequentialNode(visitor, parent);
      }
    }

    AstNode? currentSearchNode = currentNode;
    while (currentSearchNode != null) {
      parent = currentSearchNode.parent;

      // Gérer la fin du corps (instruction unique) d'une boucle While
      if (currentSearchNode is Statement &&
          parent is WhileStatement &&
          parent.body == currentSearchNode) {
        Logger.debug(
            " [_findNextSequentialNode] End of While body (single statement). Returning WhileStatement node.");
        return parent;
      }

      // Gérer la fin du corps (instruction unique) d'une boucle DoWhile
      if (currentSearchNode is Statement &&
          parent is DoStatement &&
          parent.body == currentSearchNode) {
        Logger.debug(
            " [_findNextSequentialNode] End of DoWhile body (single statement). Returning DoStatement node.");
        return parent;
      }

      // Gérer la fin du corps (instruction unique) d'une boucle For standard ou For-In
      if (currentSearchNode is Statement &&
          parent is ForStatement &&
          parent.body == currentSearchNode) {
        Logger.debug(
            " [_findNextSequentialNode] End of standard For/For-In body (single statement). Returning ForStatement node.");
        return parent;
      }

      // Gérer la fin de la branche 'then' (instruction unique) d'un IfStatement
      if (currentSearchNode is Statement &&
          parent is IfStatement &&
          parent.thenStatement == currentSearchNode) {
        // S'il y a une branche 'else', on ne fait RIEN (l'exécution s'arrête là pour cette branche)
        // S'il n'y a PAS de branche 'else', on cherche l'instruction APRÈS le IfStatement.
        if (parent.elseStatement == null) {
          Logger.debug(
              "[_findNextSequentialNode] End of If 'then' (single statement, no else). Finding node after IfStatement.");
          return _findNextSequentialNode(visitor, parent);
        } else {
          Logger.debug(
              "[_findNextSequentialNode] End of If 'then' (single statement, with else). Stopping this path.");
          // Il n'y a pas de "prochain noeud séquentiel" après le then s'il y a un else.
          return null;
        }
      }

      // Gérer la fin de la branche 'else' (instruction unique) d'un IfStatement
      if (currentSearchNode is Statement &&
          parent is IfStatement &&
          parent.elseStatement == currentSearchNode) {
        // Après le 'else', on cherche toujours l'instruction APRÈS le IfStatement entier.
        Logger.debug(
            " [_findNextSequentialNode] End of If 'else' (single statement). Finding node after IfStatement.");
        return _findNextSequentialNode(visitor, parent);
      }

      // Si on n'a pas trouvé de structure de contrôle parente spécifique,
      // on regarde si le parent est une instruction qui peut être séquencée.

      if (parent is Block) {
        // Si le parent est un Block, la logique au début (gestion de bloc) s'applique.
        // On appelle récursivement pour que cette logique prenne le relais.
        Logger.debug(
            " [_findNextSequentialNode] Ascending into a Block. Re-evaluating block logic for the parent Block.");
        return _findNextSequentialNode(visitor, parent);
      } else if (parent is Statement) {
        // Si le parent est une autre instruction, on continue de remonter
        // pour trouver le bloc ou la fonction englobante.
        Logger.debug(
            " [_findNextSequentialNode] Ascending from Statement (${currentSearchNode.runtimeType}) to parent (${parent.runtimeType}).");
        currentSearchNode = parent;
      } else if (parent is FunctionBody || parent is CompilationUnit) {
        // Atteint la limite de la fonction ou du fichier
        Logger.debug(
            " [_findNextSequentialNode] Reached FunctionBody or CompilationUnit. Returning null.");
        return null;
      } else if (parent == null) {
        // Atteint la racine de l'AST
        Logger.debug(
            " [_findNextSequentialNode] Reached top level (null parent). Returning null.");
        return null;
      } else {
        // Parent non géré (Expression, etc.) - remonter encore
        Logger.debug(
            " [_findNextSequentialNode] Ascending from non-statement parent (${parent.runtimeType}).");
        currentSearchNode = parent;
      }
    }

    Logger.debug(
        "[_findNextSequentialNode] Could not determine next sequential node (fell through). Returning null.");
    return null; // Fallback
  }

  // Remplacer l'ancien placeholder _startAsyncStateMachine
  void _startAsyncStateMachine(
      InterpreterVisitor visitor, AsyncExecutionState initialState) {
    Logger.debug(
        "[_startAsyncStateMachine] Scheduling state machine run for initial state: ${initialState.nextStateIdentifier?.runtimeType}");
    _scheduleStateMachineRun(visitor, initialState);
  }

  @override
  String toString() => '<fn ${_name ?? '<anonymous>'}>';

  // Helper to evaluate arguments for constructor/super/this invocations
  (List<Object?>, Map<String, Object?>) _evaluateArgumentsForInvocation(
      InterpreterVisitor visitor,
      ArgumentList argumentList,
      String invocationType // e.g., "super()", "this()"
      ) {
    final List<Object?> positionalArgs = [];
    final Map<String, Object?> namedArgs = {};
    bool namedArgsEncountered = false;

    for (final arg in argumentList.arguments) {
      // Evaluate argument, disallow await
      final argValue = arg.accept<Object?>(visitor);
      if (argValue is AsyncSuspensionRequest) {
        throw UnimplementedError(
            "'await' is not supported within $invocationType call arguments.");
      }

      if (arg is NamedExpression) {
        namedArgsEncountered = true;
        final name = arg.name.label.name;
        final value = arg.expression
            .accept<Object?>(visitor); // Evaluate the expression part
        Logger.debug(
            " [_evalArgs] Evaluated NAMED arg expression '$name' = $value (${value?.runtimeType})");
        if (value is AsyncSuspensionRequest) {
          throw UnimplementedError(
              "'await' is not supported within $invocationType call arguments.");
        }
        if (namedArgs.containsKey(name)) {
          throw RuntimeError(
              "Named argument '$name' provided multiple times to $invocationType.");
        }
        namedArgs[name] = value;
      } else {
        if (namedArgsEncountered) {
          throw RuntimeError(
              "Positional arguments cannot follow named arguments in $invocationType.");
        }
        positionalArgs.add(argValue);
        Logger.debug(
            " [_evalArgs] Evaluated POSITIONAL arg = $argValue (${argValue?.runtimeType})");
        if (argValue is AsyncSuspensionRequest) {
          throw UnimplementedError(
              "'await' is not supported within $invocationType call arguments.");
        }
      }
    }
    return (positionalArgs, namedArgs);
  }
}

// Represents a function implemented natively in the interpreter host (Dart)
typedef NativeFunctionImpl = Object? Function(
    InterpreterVisitor visitor,
    List<Object?> arguments,
    Map<String, Object?> namedArguments,
    List<RuntimeType>? typeArguments);

class NativeFunction implements Callable, RuntimeType {
  final NativeFunctionImpl _function;
  @override
  final int arity;
  final String _name;

  NativeFunction(this._function, {required this.arity, String? name})
      : _name = name ?? "<native>";

  @override
  Object? call(InterpreterVisitor visitor, List<Object?> positionalArguments,
      [Map<String, Object?> namedArguments = const {},
      List<RuntimeType>? typeArguments]) {
    return _function(
        visitor, positionalArguments, namedArguments, typeArguments);
  }

  @override
  String toString() => '<native fn $_name>';

  @override
  bool isSubtypeOf(RuntimeType other) {
    final f1 = _function;
    if (other is NativeFunction) {
      final f2 = other._function;
      if (name == 'num') {
        final isSubtype = switch (other._name) {
          'num' => true,
          'int' => true,
          'double' => true,
          _ => false,
        };
        return isSubtype;
      }
      return f1 == f2;
    }

    return false;
  }

  @override
  String get name => _name;
}

// Représente une méthode d'instance d'une classe pontée qui a été liée à une instance spécifique.
class BridgedMethodCallable implements Callable {
  final BridgedInstance _instance; // L'instance native cible
  final BridgedMethodAdapter _adapter; // La fonction d'adaptation
  final String _methodName;

  BridgedMethodCallable(this._instance, this._adapter, this._methodName);

  @override
  int get arity {
    // L'arité est complexe à déterminer statiquement pour les adaptateurs natifs.
    // Pour l'instant, on retourne 0, mais l'adaptateur lui-même fera la validation.
    // On pourrait améliorer cela si les adaptateurs fournissent des métadonnées.
    return 0;
  }

  @override
  Object? call(InterpreterVisitor visitor, List<Object?> positionalArguments,
      [Map<String, Object?> namedArguments = const {},
      List<RuntimeType>? typeArguments]) {
    try {
      // Appeler l'adaptateur avec l'objet natif de l'instance et les arguments
      return _adapter(
          visitor, _instance.nativeObject, positionalArguments, namedArguments);
    } on ArgumentError catch (e) {
      // Convertir ArgumentError natif en RuntimeError
      throw RuntimeError(
          "Invalid arguments for bridged method '${_instance.bridgedClass.name}.$_methodName': ${e.message}");
    } catch (e, s) {
      // Gérer d'autres erreurs natives
      Logger.error(
          "[BridgedMethodCallable] Native exception during call to '${_instance.bridgedClass.name}.$_methodName': $e\n$s");
      throw RuntimeError(
          "Native error in bridged method '${_instance.bridgedClass.name}.$_methodName': $e");
    }
  }

  @override
  String toString() =>
      '<bridged method ${_instance.bridgedClass.name}.$_methodName>';
}

// Represents an extension method during interpretation.
class InterpretedExtensionMethod implements Callable {
  final MethodDeclaration declaration; // The AST node for the method
  final Environment closure; // Environment where the extension was declared
  // Store the 'on' type to potentially check 'this' type during call?
  final RuntimeType onType;

  InterpretedExtensionMethod(this.declaration, this.closure, this.onType);

  // Add getters for method type
  bool get isGetter => declaration.isGetter;
  bool get isSetter => declaration.isSetter;
  bool get isOperator => declaration.isOperator;

  @override
  int get arity =>
      // Arity is based on the *declared* parameters, not including implicit 'this'
      declaration.parameters?.parameters.length ?? 0;

  @override
  Object? call(InterpreterVisitor visitor, List<Object?> positionalArguments,
      [Map<String, Object?> namedArguments = const {},
      List<RuntimeType>? typeArguments]) {
    // 1. Extraire l'instance cible (premier argument)
    if (positionalArguments.isEmpty) {
      throw RuntimeError(
          "Internal error: Extension method '${declaration.name.lexeme}' called without target instance ('this').");
    }
    final targetInstance =
        positionalArguments.removeAt(0); // Consomme le premier argument

    // 2. Créer l'environnement d'exécution
    final executionEnvironment = Environment(enclosing: closure);
    // Définir 'this' dans cet environnement
    executionEnvironment.define('this', targetInstance);
    Logger.debug(
        "[InterpretedExtensionMethod.call] Created execution env (${executionEnvironment.hashCode}) for '${declaration.name.lexeme}', defining 'this'=${targetInstance?.runtimeType}");

    // 3. Lier les paramètres déclarés (arguments explicites)
    final params = declaration.parameters?.parameters;
    int positionalArgIndex = 0;
    final providedNamedArgs = namedArguments;
    final processedParamNames = <String>{};

    if (params != null) {
      for (final param in params) {
        String? paramName;
        Expression? defaultValueExpr;
        bool isRequired = false;
        bool isOptionalPositional = false;
        bool isNamed = false;
        bool isRequiredNamed = false;

        // Déterminer les infos du paramètre (copié depuis InterpretedFunction)
        FormalParameter actualParam = param;
        if (param is DefaultFormalParameter) {
          defaultValueExpr = param.defaultValue;
          actualParam = param.parameter;
        }
        if (actualParam is NormalFormalParameter) {
          paramName = actualParam.name?.lexeme;
          isRequired = actualParam.isRequiredPositional;
          isOptionalPositional = actualParam.isOptionalPositional;
          isNamed = actualParam.isNamed;
          isRequiredNamed = actualParam.isRequiredNamed;
        } else {
          throw UnimplementedError(
              "Unsupported parameter kind in extension method: ${actualParam.runtimeType}");
        }
        if (paramName == null) {
          throw StateError("Extension parameter missing name");
        }
        processedParamNames.add(paramName);

        // Trouver l'argument correspondant et la valeur
        Object? valueToDefine;
        bool argumentProvided = false;
        if (isOptionalPositional || isRequired) {
          if (positionalArgIndex < positionalArguments.length) {
            valueToDefine = positionalArguments[positionalArgIndex++];
            argumentProvided = true;
          }
        } else if (isNamed) {
          if (providedNamedArgs.containsKey(paramName)) {
            valueToDefine = providedNamedArgs[paramName];
            argumentProvided = true;
          }
        }

        // Gérer les valeurs par défaut et les vérifications required
        if (!argumentProvided) {
          if (defaultValueExpr != null) {
            final previousVisitorEnv = visitor.environment;
            try {
              visitor.environment =
                  closure; // Defaults evaluated in declaration scope
              valueToDefine = defaultValueExpr.accept<Object?>(visitor);
            } finally {
              visitor.environment = previousVisitorEnv;
            }
          } else if (isRequired || isRequiredNamed) {
            throw RuntimeError(
                "Missing required ${isNamed ? 'named' : ''} argument for '$paramName' in extension method '${declaration.name.lexeme}'.");
          } else {
            valueToDefine = null;
          }
        }
        // Définir la variable dans l'environnement d'exécution
        executionEnvironment.define(paramName, valueToDefine);
        Logger.debug(
            " [InterpretedExtensionMethod.call] Bound param '$paramName' = $valueToDefine");
      }

      // Vérifications finales des arguments (copiées depuis InterpretedFunction)
      final int totalPositionalDeclared =
          params.where((p) => p.isPositional).length;
      if (positionalArgIndex < positionalArguments.length) {
        throw RuntimeError(
            "Too many positional arguments for extension method '${declaration.name.lexeme}'. Expected at most $totalPositionalDeclared, got ${positionalArguments.length}.");
      }
      for (final providedName in providedNamedArgs.keys) {
        if (!processedParamNames.contains(providedName)) {
          throw RuntimeError(
              "Extension method '${declaration.name.lexeme}' does not have a parameter named '$providedName'.");
        }
      }
    } else if (positionalArguments.isNotEmpty || providedNamedArgs.isNotEmpty) {
      throw RuntimeError(
          "Extension method '${declaration.name.lexeme}' takes no arguments (besides 'this'), but arguments were provided.");
    }

    // 4. Exécuter le corps dans le nouvel environnement
    final previousEnvironment = visitor.environment;
    final previousFunction = visitor.currentFunction;
    // visitor.currentFunction = ???;
    visitor.environment =
        executionEnvironment; // UTILISER LE NOUVEL ENVIRONNEMENT
    Logger.debug(
        "[InterpretedExtensionMethod.call] Set visitor environment to executionEnvironment (${executionEnvironment.hashCode}) before executing body.");

    try {
      final body = declaration.body;
      if (body is BlockFunctionBody) {
        // executeBlock gère déjà ReturnException correctement
        return visitor.executeBlock(
            body.block.statements, executionEnvironment);
      } else if (body is ExpressionFunctionBody) {
        // Pour un corps d'expression, évaluer et retourner la valeur
        final result = body.expression.accept<Object?>(visitor);
        // Pas besoin de lever ReturnException ici, on retourne directement
        return result;
      } else if (body is EmptyFunctionBody) {
        throw RuntimeError(
            "Cannot execute empty body for extension method '${declaration.name.lexeme}'.");
      } else {
        throw UnimplementedError(
            'Function body type not handled in extension method: ${body.runtimeType}');
      }
    } on ReturnException catch (e) {
      // Attraper au cas où executeBlock (ou autre) lèverait encore ReturnException
      Logger.debug(
          " [InterpretedExtensionMethod.call] Caught ReturnException, returning value: ${e.value}");
      return e.value;
    } finally {
      Logger.debug(
          " [InterpretedExtensionMethod.call] Restoring visitor environment from (${visitor.environment.hashCode}) to (${previousEnvironment.hashCode}).");
      visitor.environment = previousEnvironment;
      visitor.currentFunction =
          previousFunction; // Restaurer aussi currentFunction
    }
  }
}

/// Représente une méthode d'extension liée à une instance cible.
///
/// Stocke l'instance (`target`) et la méthode d'extension (`extensionMethod`).
/// Lorsque `call` est invoqué, elle appelle la méthode d'extension sous-jacente,
/// en insérant automatiquement l'instance cible comme premier argument positionnel.
class BoundExtensionMethodCallable implements Callable {
  final Object? target; // L'instance 'this' à laquelle la méthode est liée.
  final InterpretedExtensionMethod extensionMethod;

  BoundExtensionMethodCallable(this.target, this.extensionMethod);

  // L'arité de la méthode liée est l'arité de la méthode d'extension originale.
  @override
  int get arity => extensionMethod.arity;

  @override
  Object? call(InterpreterVisitor visitor, List<Object?> positionalArguments,
      [Map<String, Object?> namedArguments = const {},
      List<RuntimeType>? typeArguments = const []]) {
    // Préparer les arguments pour l'appel réel à l'InterpretedExtensionMethod:
    // Le premier argument est TOUJOURS l'instance cible.
    final actualPositionalArgs = [target, ...positionalArguments];

    Logger.debug(
        "[BoundExtensionMethodCallable] Calling extension method '${extensionMethod.declaration.name.lexeme}' bound to ${target?.runtimeType}");

    // Appeler la méthode d'extension originale avec les arguments ajustés.
    // Elle gérera les exceptions ReturnException, etc.
    return extensionMethod.call(
        visitor, actualPositionalArgs, namedArguments, typeArguments);
  }
}
