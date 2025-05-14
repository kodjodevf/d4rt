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
        visitor.currentAsyncState; // Save current async state

    try {
      if (isAsync) {
        final completer = Completer<Object?>();

        // Determine the first state (AST node)
        AstNode? initialStateIdentifier;
        final bodyToExecute = _body;
        if (!redirected) {
          if (bodyToExecute is BlockFunctionBody) {
            initialStateIdentifier = bodyToExecute.block.statements.firstOrNull;
          } else if (bodyToExecute is ExpressionFunctionBody) {
            initialStateIdentifier = bodyToExecute.expression;
          } else if (bodyToExecute is EmptyFunctionBody) {
            initialStateIdentifier =
                null; // Empty function, completes immediately
          } else {
            throw StateError(
                "Unhandled function body type for async state machine: ${bodyToExecute.runtimeType}");
          }
        } else {
          // Redirecting constructor, completes with 'this'
          initialStateIdentifier = null;
        }

        // Create the initial state
        final asyncState = AsyncExecutionState(
          environment: executionEnvironment,
          completer: completer,
          nextStateIdentifier: initialStateIdentifier,
          function: this,
        );

        // Handle cases where the function completes immediately
        if (initialStateIdentifier == null) {
          if (redirected) {
            completer.complete(executionEnvironment.get('this'));
          } else {
            completer.complete(null); // Empty function
          }
        } else {
          // The engine will take care of scheduling (ex: via Future.microtask)
          // Put the visitor in the initial state for the engine
          visitor.currentAsyncState = asyncState;
          _startAsyncStateMachine(visitor, asyncState);
        }

        // Return immediately the Future
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

  // Main engine of the async state machine
  // Scheduled via Future.microtask to start execution
  static Future<void> _runStateMachine(
      InterpreterVisitor visitor, AsyncExecutionState currentState) async {
    Object? lastResult;
    AstNode? currentNode = currentState.nextStateIdentifier;

    // Main loop of state machine execution
    while (currentNode != null) {
      // Save current visitor environment (in case of error)
      final originalVisitorEnv = visitor.environment;
      final previousAsyncState = visitor.currentAsyncState;

      // Configure the visitor for the current state
      // Use the loop environment for FOR loops, otherwise the state environment
      visitor.environment =
          currentState.forLoopEnvironment ?? currentState.environment;
      visitor.currentAsyncState = currentState;
      // currentFunction is already defined by the call method

      Logger.debug(
          " [StateMachine] Executing state: ${currentNode.runtimeType} in state env ${currentState.environment.hashCode}, loop env ${currentState.forLoopEnvironment?.hashCode}. Visitor env set to: ${visitor.environment.hashCode}");

      try {
        // Case: While loop
        if (currentNode is WhileStatement) {
          final whileNode = currentNode;
          Logger.debug("[StateMachine] Handling WhileStatement condition.");
          // Evaluate the condition
          final conditionResult = whileNode.condition.accept<Object?>(visitor);

          if (conditionResult is AsyncSuspensionRequest) {
            // The condition itself is asynchronous, suspend
            Logger.debug(
                " [StateMachine] While condition suspended. Waiting...");
            lastResult =
                conditionResult; // Update lastResult for the processing below
          } else if (conditionResult is bool) {
            // Synchronous condition
            if (conditionResult) {
              // True condition: the next state is the body of the loop
              Logger.debug(
                  "[StateMachine] While condition TRUE. Next node is body: ${whileNode.body.runtimeType}");
              // If the body is a block, take the first statement
              if (whileNode.body is Block) {
                currentNode = (whileNode.body as Block).statements.firstOrNull;
              } else {
                currentNode = whileNode.body;
              }
              currentState.nextStateIdentifier = currentNode;
              continue; // Restart the while loop of the state machine with the new node
            } else {
              // False condition: skip the loop, find the next node after the while
              Logger.debug(
                  "[StateMachine] While condition FALSE. Finding node after while.");
              currentNode = _findNextSequentialNode(visitor, whileNode);
              currentState.nextStateIdentifier = currentNode;
              continue; // Restart the while loop of the state machine
            }
          } else {
            // The condition did not return a boolean or suspension
            throw RuntimeError(
                "While loop condition must evaluate to a boolean, but got ${conditionResult?.runtimeType}.");
          }
        } else if (currentNode is DoStatement) {
          final doNode = currentNode;
          // The logic of DoStatement is particular:
          // 1. If we arrive on the DoStatement the *first time* (or after a true condition),
          //    we need to execute the body.
          // 2. If we arrive on the DoStatement after having executed the *last* instruction of the body
          //    (detected by _findNextSequentialNode returning the DoStatement),
          //    we need to evaluate the condition.

          // To differentiate, we can look at the previous state or add a flag in AsyncExecutionState.
          // Simple approach: if the current state points to DoStatement, we assume we need to evaluate the condition
          // because _findNextSequentialNode led us to the DoStatement from the end of the body.
          // If we entered the loop in a non-standard way, this could fail.

          Logger.debug(
              "[StateMachine] Handling DoStatement. Evaluating condition.");
          // Evaluate the condition
          final conditionResult = doNode.condition.accept<Object?>(visitor);

          if (conditionResult is AsyncSuspensionRequest) {
            // The condition is asynchronous, suspend
            Logger.debug(
                " [StateMachine] DoWhile condition suspended. Waiting...");
            lastResult =
                conditionResult; // Update lastResult for the processing below
          } else if (conditionResult is bool) {
            // Synchronous condition
            if (conditionResult) {
              // True condition: the next state is the beginning of the loop body
              Logger.debug(
                  "[StateMachine] DoWhile condition TRUE. Next node is body: ${doNode.body.runtimeType}");
              if (doNode.body is Block) {
                currentNode = (doNode.body as Block).statements.firstOrNull;
              } else {
                currentNode = doNode.body;
              }
              currentState.nextStateIdentifier = currentNode;
              continue; // Restart the state machine loop with the beginning of the body
            } else {
              // False condition: exit the loop, find the next node after the do-while
              Logger.debug(
                  "[StateMachine] DoWhile condition FALSE. Finding node after do-while.");
              currentNode = _findNextSequentialNode(visitor, doNode);
              currentState.nextStateIdentifier = currentNode;
              continue; // Restart the state machine loop
            }
          } else {
            // The condition did not return a boolean or suspension
            throw RuntimeError(
                "DoWhile loop condition must evaluate to a boolean, but got ${conditionResult?.runtimeType}.");
          }
          // If the condition was suspended, lastResult contains AsyncSuspensionRequest
          // and will be handled by the suspension logic below.
        } else if (currentNode is ForStatement &&
            currentNode.forLoopParts is ForEachParts) {
          final forNode = currentNode;
          final parts = forNode.forLoopParts as ForEachParts;

          Iterator<Object?>? iterator = currentState.currentForInIterator;

          // First time or resumed after the body?
          if (iterator == null) {
            // First time: evaluate the iterable and create the iterator
            Logger.debug(
                " [StateMachine] Handling ForIn: Evaluating iterable.");
            final iterableResult = parts.iterable.accept<Object?>(visitor);

            // Handle if the iterable evaluation is suspended
            if (iterableResult is AsyncSuspensionRequest) {
              Logger.debug(
                  "[StateMachine] ForIn iterable suspended. Waiting...");
              lastResult = iterableResult;
              // The suspension logic below will handle it.
            } else if (iterableResult is Iterable) {
              iterator = iterableResult.iterator;
              currentState.currentForInIterator = iterator; // Save the iterator
              Logger.debug("[StateMachine] ForIn: Iterator created.");
            } else {
              throw RuntimeError(
                  "The value iterate over in a for-in loop must be an Iterable, but got ${iterableResult?.runtimeType}.");
            }
          }

          // If we have an iterator (either created or resumed), we continue the loop
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
              // Next item available
              final currentItem = iterator.current;
              Logger.debug("[StateMachine] ForIn: Got next item: $currentItem");

              if (parts is ForEachPartsWithDeclaration) {
                final loopVariable = parts.loopVariable;
                // Create a dedicated environment for the loop if it hasn't been done yet
                currentState.forLoopEnvironment ??=
                    Environment(enclosing: currentState.environment);
                visitor.environment = currentState.forLoopEnvironment!;
                // Define the loop variable in this environment
                currentState.forLoopEnvironment!
                    .define(loopVariable.name.lexeme, currentItem);
              } else if (parts is ForEachPartsWithIdentifier) {
                // No declaration, assign in the current environment
                currentState.environment
                    .assign(parts.identifier.name, currentItem);
                // Ensure we don't use a residual loop environment
                currentState.forLoopEnvironment = null;
                visitor.environment = currentState.environment;
              } else {
                throw StateError(
                    "Unknown ForEachParts type: \\${parts.runtimeType}");
              }

              // The next state is the body of the loop
              Logger.debug(
                  "[StateMachine] ForIn: Next node is body: \\${forNode.body.runtimeType}");
              if (forNode.body is Block) {
                currentNode = (forNode.body as Block).statements.firstOrNull;
              } else {
                currentNode = forNode.body;
              }
              currentState.nextStateIdentifier = currentNode;
              continue; // Restart the state machine loop with the beginning of the body
            } else {
              // End of iteration
              Logger.debug(
                  "[StateMachine] ForIn: Iteration finished. Finding node after loop. (forNode: \\${forNode.runtimeType}, parent: \\${forNode.parent?.runtimeType}, env: \\${visitor.environment.hashCode})");
              currentState.currentForInIterator = null; // Clean the iterator
              // Clean the loop environment if it existed
              currentState.forLoopEnvironment = null;
              visitor.environment = currentState.environment;
              currentNode = _findNextSequentialNode(visitor, forNode);
              Logger.debug(
                  "[StateMachine] ForIn: After _findNextSequentialNode, currentNode: \\${currentNode?.runtimeType}, parent: \\${currentNode?.parent?.runtimeType}");
              currentState.nextStateIdentifier = currentNode;
              continue; // Restart the state machine loop
            }
          }
          // If the iterable evaluation was suspended, lastResult contains
          // AsyncSuspensionRequest and will be handled by the logic below.
        } else if (currentNode is ForStatement &&
            (currentNode.forLoopParts is ForPartsWithDeclarations ||
                currentNode.forLoopParts is ForPartsWithExpression)) {
          final forNode = currentNode;
          final parts = forNode.forLoopParts;
          bool cameFromBody = false; // Flag to know if we came from the body

          // Determine if we came from the body of the loop
          // (Approximation: if the current node is ForStatement and we have a loop environment)
          if (currentState.forLoopEnvironment != null &&
              currentState.forLoopInitialized &&
              !currentState.resumedFromInitializer) {
            // We came from the body if the env exists, is initialized, and we didn't resume from the initializer
            cameFromBody = true;
          }
          // Reset the flag after having used it
          currentState.resumedFromInitializer = false;

          if (!currentState.forLoopInitialized) {
            Logger.debug(" [StateMachine] Handling For: Initializing.");
            // Create the loop environment once
            currentState.forLoopEnvironment =
                Environment(enclosing: currentState.environment);
            visitor.environment =
                currentState.forLoopEnvironment!; // Use the loop env

            AstNode? initNode;
            if (parts is ForPartsWithDeclarations) {
              initNode = parts.variables;
            } else if (parts is ForPartsWithExpression) {
              initNode = parts.initialization;
            }

            if (initNode != null) {
              lastResult = initNode
                  .accept<Object?>(visitor); // Execute in forLoopEnvironment

              if (lastResult is AsyncSuspensionRequest) {
                // Suspended during initialization
                Logger.debug(
                    "[StateMachine] For loop initialization suspended. Will resume.");
                // Mark as initialized so the suspension logic will resume
                currentState.forLoopInitialized = true;
                // Leave lastResult as is, the general suspension logic will handle it
                // Do NOT continue to the condition or updaters now.
                // The 'finally' will restore the env, and the .then() will restart _runStateMachine.
              } else {
                // Synchronous initialization completed
                currentState.forLoopInitialized = true;
                cameFromBody = false; // Do NOT go to updaters
                // Continue to the condition IN THIS SAME ITERATION of the loop
              }
            } else {
              // No initialization
              currentState.forLoopInitialized = true;
              cameFromBody = false;
            }
            // Do NOT restore the environment here, we will need it for the condition/updaters
            // visitor.environment = currentState.environment; // Do NOT restore here
          }

          // Runs only if we are not suspended by the initialization
          if (cameFromBody &&
              currentState.forLoopInitialized &&
              lastResult is! AsyncSuspensionRequest) {
            Logger.debug(" [StateMachine] Handling For: Running updaters.");
            visitor.environment =
                currentState.forLoopEnvironment!; // Use the loop env
            NodeList<Expression>? updaters;
            if (parts is ForPartsWithDeclarations) {
              updaters = parts.updaters;
            } else if (parts is ForPartsWithExpression) {
              updaters = parts.updaters;
            }

            if (updaters != null) {
              for (final updateExpr in updaters) {
                lastResult = updateExpr
                    .accept<Object?>(visitor); // Execute in forLoopEnvironment
                if (lastResult is AsyncSuspensionRequest) {
                  // Suspended during the update
                  Logger.debug("[StateMachine] For loop updater suspended.");
                  // Keep the environment for the suspension logic
                  break; // Exit the updaters loop, the suspension will be handled
                }
              }
            }
            // Do NOT restore the environment here, we will need it for the condition
            // visitor.environment = currentState.environment;
            // After the updaters (or if there are no updaters), we go to the condition
            cameFromBody =
                false; // Do NOT consider we came from the body for the condition
          }

          // Condition (if initialized and not suspended during init/updater)\
          // Runs after init (if sync) or after updater (if sync)
          if (currentState.forLoopInitialized &&
              lastResult is! AsyncSuspensionRequest) {
            Logger.debug(" [StateMachine] Handling For: Evaluating condition.");
            visitor.environment =
                currentState.forLoopEnvironment!; // Use the loop env
            Expression? condition;
            if (parts is ForPartsWithDeclarations) {
              condition = parts.condition;
            } else if (parts is ForPartsWithExpression) {
              condition = parts.condition;
            }

            bool conditionValue = true; // The condition is true if absent
            if (condition != null) {
              lastResult = condition
                  .accept<Object?>(visitor); // Execute in forLoopEnvironment
              if (lastResult is AsyncSuspensionRequest) {
                // Suspended during the condition
                Logger.debug("[StateMachine] For loop condition suspended.");
                // Keep the environment for the suspension logic
              } else if (lastResult is bool) {
                conditionValue = lastResult;
              } else {
                // Restore the environment before throwing the error
                visitor.environment = currentState.environment;
                throw RuntimeError(
                    "For loop condition must be a boolean, but got ${lastResult?.runtimeType}");
              }
            }
            // Do NOT restore the environment here if we continue in the body

            // Decision based on the condition (if not suspended)\
            if (lastResult is! AsyncSuspensionRequest) {
              if (conditionValue) {
                // Condition true: the next state is the body
                Logger.debug(
                    "[StateMachine] For condition TRUE. Next node is body: ${forNode.body.runtimeType}");
                // The loop environment remains active for the body execution
                if (forNode.body is Block) {
                  currentNode = (forNode.body as Block).statements.firstOrNull;
                } else {
                  currentNode = forNode.body;
                }
                // If the body is empty, we loop directly to the updaters
                if (currentNode == null) {
                  Logger.debug(
                      "[StateMachine] For loop body is empty. Proceeding to updaters/condition.");
                  // Simulate that we came from the body to trigger the updaters
                  visitor.environment =
                      currentState.environment; // Restore before continuing
                  currentState.nextStateIdentifier =
                      forNode; // Go back to the ForStatement
                  continue;
                } else {
                  currentState.nextStateIdentifier = currentNode;
                  // Do NOT restore the environment, the body will execute in it
                  continue; // Restart the state machine loop with the body
                }
              } else {
                // Condition false: exit the loop
                Logger.debug(
                    "[StateMachine] For condition FALSE. Finding node after loop.");
                // Clean the loop state
                currentState.forLoopInitialized = false;
                currentState.forLoopEnvironment = null;
                visitor.environment =
                    currentState.environment; // Restore the environment
                currentNode = _findNextSequentialNode(visitor, forNode);
                currentState.nextStateIdentifier = currentNode;
                continue; // Restart the state machine loop with the next node
              }
            }
          }
          // If suspended (lastResult is AsyncSuspensionRequest), the general suspension logic takes over.
          // The visitor environment must be restored in the finally of the main loop.
        } else if (currentNode is TryStatement) {
          // When entering a TryStatement, register it
          currentState.activeTryStatement = currentNode;
          Logger.debug(
              "[StateMachine] Entering TryStatement: ${currentNode.offset}. Proceeding to body.");
          // The next state is the first instruction of the try block
          currentNode = currentNode.body.statements.firstOrNull;
          // If the try block is empty, find the next node after the try
          if (currentNode == null) {
            Logger.debug(
                " [StateMachine] Try block is empty. Finding node after TryStatement.");
            // Is there a finally? If yes, go to it.
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
              // No finally, find the node after the Try
              currentNode = _findNextSequentialNode(
                  visitor, currentState.activeTryStatement!);
              currentState.activeTryStatement = null; // End of try
            }
          }
          currentState.nextStateIdentifier = currentNode;
          continue; // Continue with the first state of the try (or finally or after)
        } else if (currentNode is IfStatement) {
          final ifNode = currentNode;
          Logger.debug("[StateMachine] Handling IfStatement condition.");
          // Evaluate the condition
          final conditionResult = ifNode.expression.accept<Object?>(visitor);

          if (conditionResult is AsyncSuspensionRequest) {
            // The condition is asynchronous, suspend
            Logger.debug(" [StateMachine] If condition suspended. Waiting...");
            lastResult =
                conditionResult; // Update lastResult for the processing below
            // The general suspension logic will handle the await and resume
          } else if (conditionResult is bool) {
            // Synchronous condition
            if (conditionResult) {
              // Condition true: the next state is the 'then' branch
              Logger.debug(
                  "[StateMachine] If condition TRUE. Next node is thenBranch: ${ifNode.thenStatement.runtimeType}");
              // If then is a block, take the first instruction
              if (ifNode.thenStatement is Block) {
                currentNode =
                    (ifNode.thenStatement as Block).statements.firstOrNull;
              } else {
                currentNode = ifNode.thenStatement;
              }
              // If the 'then' branch is empty, go to the next instruction
              if (currentNode == null) {
                Logger.debug(
                    "[StateMachine] If 'then' branch is empty. Finding node after IfStatement.");
                currentNode = _findNextSequentialNode(visitor, ifNode);
              }
              currentState.nextStateIdentifier = currentNode;
              continue; // Restart the state machine loop with the new node
            } else {
              // Condition false: check the 'else' branch
              if (ifNode.elseStatement != null) {
                Logger.debug(
                    "[StateMachine] If condition FALSE. Next node is elseBranch: ${ifNode.elseStatement?.runtimeType}");
                // If else is a block, take the first instruction
                if (ifNode.elseStatement is Block) {
                  currentNode =
                      (ifNode.elseStatement as Block).statements.firstOrNull;
                } else {
                  currentNode = ifNode.elseStatement;
                }
                // If the 'else' branch is empty, go to the next instruction
                if (currentNode == null) {
                  Logger.debug(
                      "[StateMachine] If 'else' branch is empty. Finding node after IfStatement.");
                  currentNode = _findNextSequentialNode(visitor, ifNode);
                }
              } else {
                // No 'else' branch, find the next instruction after the if
                Logger.debug(
                    "[StateMachine] If condition FALSE, no else branch. Finding node after IfStatement.");
                currentNode = _findNextSequentialNode(visitor, ifNode);
              }
              currentState.nextStateIdentifier = currentNode;
              continue; // Restart the state machine loop
            }
          } else {
            // The condition did not return a boolean or a suspension
            throw RuntimeError(
                "If condition must evaluate to a boolean, but got ${conditionResult?.runtimeType}.");
          }
          // If the condition was suspended, lastResult contains AsyncSuspensionRequest
          // and will be handled by the suspension logic below.
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
            rethrow; // Re-throw to be caught by the ReturnException catch below
          } catch (error, stackTrace) {
            if (error is InternalInterpreterException) {
              // This is an exception rethrown by rethrow. Propagate immediately.
              Logger.debug(
                  " [StateMachine] Caught InternalInterpreterException from accept()/rethrow. Propagating.");
              // Reset the rethrow state
              currentState.isHandlingErrorForRethrow = false;
              currentState.originalErrorForRethrow = null;
              if (!currentState.completer.isCompleted) {
                // Ensure the error is not null for completeError
                final errorToComplete = error.originalThrownValue ??
                    Exception('Unknown rethrown error during accept()');
                currentState.completer
                    .completeError(errorToComplete, stackTrace);
              }
              return; // Stop the state machine
            } else {
              // Standard synchronous error during accept(): store and try to handle
              Logger.debug(
                  " [StateMachine] Caught standard SYNC error during accept(): $error");
              currentState.currentError = error;
              currentState.currentStackTrace = stackTrace;
              _handleAsyncError(visitor, currentState, currentNode);
              return; // Exit, _handleAsyncError will take care of the rest
            }
          }
        }

        // Analyze the result (can come from accept() or from condition evaluation in while)
        if (lastResult is AsyncSuspensionRequest) {
          // Check if accept() returned a suspension
          final AsyncSuspensionRequest suspension = lastResult;

          Logger.debug(
              "[StateMachine] Suspension requested (from ${currentNode.runtimeType}). Waiting for Future...");

          // Attach the callbacks to the Future
          suspension.future.then((futureResult) {
            Logger.debug(
                " [StateMachine] Future completed successfully with: $futureResult");
            // Update the state with the result
            currentState.lastAwaitResult = futureResult;
            currentState.lastAwaitError = null;
            currentState.lastAwaitStackTrace = null;
            currentState.currentError = null; // Clear any previous error state
            currentState.currentStackTrace = null;

            if (currentState.pendingFinallyBlock != null) {
              Logger.debug(
                  "[StateMachine] Resuming after await, pending finally found. Executing finally block first.");
              // The next state is the beginning of the finally block
              final finallyBlock = currentState.pendingFinallyBlock!;
              currentState.pendingFinallyBlock = null; // Consumed
              currentState.nextStateIdentifier =
                  finallyBlock.statements.firstOrNull;
              if (currentState.nextStateIdentifier == null) {
                // The finally block is empty, find the node after the try
                Logger.debug(
                    "[StateMachine] Pending finally block was empty. Finding node after TryStatement.");
                if (currentState.activeTryStatement != null) {
                  currentState.nextStateIdentifier = _findNextSequentialNode(
                      visitor, currentState.activeTryStatement!);
                  currentState.activeTryStatement = null; // End of try handling
                } else {
                  Logger.warn(
                      "[StateMachine] Cannot find node after empty finally block without active TryStatement.");
                  currentState.nextStateIdentifier = null; // Safe stop
                }
              }
              _scheduleStateMachineRun(visitor, currentState);
              return; // Do not determine the next normal node
            }

            // Determine the next state based on the AST context
            AstNode? nextNodeAfterAwait = _determineNextNodeAfterAwait(
                visitor,
                currentState,
                currentNode!); // The node that caused the suspension
            currentState.nextStateIdentifier = nextNodeAfterAwait;

            // Reschedule the state machine execution
            _scheduleStateMachineRun(visitor, currentState);
          }).catchError((Object error, StackTrace stackTrace) {
            Logger.debug(
                " [StateMachine] Future completed with ERROR: $error"); // Do not display stackTrace here, too long
            // Store the error and stack trace in the state
            currentState.lastAwaitError = error; // For info if someone uses it
            currentState.lastAwaitStackTrace = stackTrace;
            currentState.currentError = error; // Active error to handle
            currentState.currentStackTrace = stackTrace;
            currentState.lastAwaitResult = null; // No valid result

            // Try to handle the error (find catch/finally)
            _handleAsyncError(visitor, currentState, currentNode!);
            // _handleAsyncError will either find a catch/finally and reschedule,
            // or complete the completer with the error.
          });

          // IMPORTANT: Exit the _runStateMachine function.
          // Execution will resume in the .then() or _handleAsyncError
          return;
        } else {
          // Clear error state if we executed successfully
          currentState.currentError = null;
          currentState.currentStackTrace = null;

          // Determine the next sequential normal state
          // Use _findNextSequentialNode which now handles try/catch/finally
          final nextNode = _findNextSequentialNode(visitor, currentNode);
          Logger.debug(
              "[StateMachine] Sync execution finished. Next node from _findNext: ${nextNode?.runtimeType}");
          currentNode = nextNode;
          currentState.nextStateIdentifier = currentNode;
        }
      } on ReturnException catch (e) {
        // The function returned a value
        Logger.debug(
            " [StateMachine] Caught ReturnException. Completing with: ${e.value}");
        TryStatement? currentTry =
            currentState.activeTryStatement; // Use currentState
        if (currentTry != null && currentTry.finallyBlock != null) {
          // Check currentTry != null
          Logger.debug(
              "[StateMachine] Return caught inside try with finally. Executing finally first.");
          currentState.returnAfterFinally = e.value; // Use currentState
          // Reset rethrow state if jumping to finally
          currentState.isHandlingErrorForRethrow = false;
          currentState.originalErrorForRethrow = null;
          currentNode =
              currentTry.finallyBlock!.statements.firstOrNull; // Now sure
          currentState.nextStateIdentifier = currentNode; // Use currentState
          continue; // Execute the finally
        }
        if (!currentState.completer.isCompleted) {
          currentState.completer.complete(e.value);
        }
        return; // Stop the state machine
      } catch (error, stackTrace) {
        // Other error during state execution (SYNC)

        // Check if the error comes from rethrow
        if (error is InternalInterpreterException) {
          // This is an exception rethrown by rethrow. Do not handle it here.
          // Propagate it by completing the Future with the original error.
          Logger.debug(
              " [StateMachine] Caught InternalInterpreterException from rethrow. Propagating.");
          // Reset rethrow state before completing with error
          currentState.isHandlingErrorForRethrow = false;
          currentState.originalErrorForRethrow = null;
          if (!currentState.completer.isCompleted) {
            // Propagate the original error and its associated stack trace (if available in the internal exception)
            // or the current stack trace if the internal one does not have one.
            // Note: InternalInterpreterException does not store the stack trace for now.
            // Using the captured stackTrace here is the best choice.
            currentState.completer
                .completeError(error.originalThrownValue!, stackTrace);
          }
          return; // Stop the state machine execution
        } else {
          // Standard synchronous error: Try to handle via internal try/catch/finally
          Logger.debug(
              " [StateMachine] Caught standard SYNC Error during non-accept state execution: $error\\n$stackTrace");
          currentState.currentError = error; // Utiliser currentState
          currentState.currentStackTrace = stackTrace;
          _handleAsyncError(visitor, currentState,
              currentNode ?? currentState.function._body); // Use currentState
          return; // Exit, _handleAsyncError will take care of the rest
        }
      } finally {
        // Restore the visitor environment if it was changed
        visitor.environment = originalVisitorEnv;
        visitor.currentAsyncState = previousAsyncState;
        Logger.debug(
            " [StateMachine] Restored visitor env (${originalVisitorEnv.hashCode}) and async state in finally block.");
      }
    }

    // Handle a return that was suspended by a finally
    if (currentState.returnAfterFinally != null &&
        !currentState.completer.isCompleted) {
      Logger.debug(
          " [StateMachine] Completing with stored return value after finally: ${currentState.returnAfterFinally}");
      // Reset rethrow state before completing
      currentState.isHandlingErrorForRethrow = false;
      currentState.originalErrorForRethrow = null;
      currentState.completer.complete(currentState.returnAfterFinally);
      return;
    }

    // If the loop ends and there was an error (not caught but after a finally executed)
    if (currentState.currentError != null &&
        !currentState.completer.isCompleted) {
      Logger.debug(
          " [StateMachine] Loop finished, propagating unhandled error after finally: ${currentState.currentError}");
      // Reset rethrow state before completing with error
      currentState.isHandlingErrorForRethrow = false;
      currentState.originalErrorForRethrow = null;
      currentState.completer.completeError(
          currentState.currentError ?? Exception("Unknown error after finally"),
          currentState.currentStackTrace);
    }
    // If the loop ends normally (no more nodes to execute)
    else if (!currentState.completer.isCompleted) {
      Logger.debug(
          " [StateMachine] Loop finished normally. Completing with last result: $lastResult (State has await result: ${currentState.lastAwaitResult})");
      // Reset rethrow state before completing normally
      currentState.isHandlingErrorForRethrow = false;
      currentState.originalErrorForRethrow = null;

      Object? finalCompletionValue = lastResult;
      if (lastResult == null && currentState.lastAwaitResult != null) {
        finalCompletionValue = currentState.lastAwaitResult;
        Logger.debug(
            " [StateMachine] Loop finished after await. Using await result for completion: $finalCompletionValue");
      }
      currentState.completer.complete(finalCompletionValue);
    }
  }

  // Schedule the state machine execution via microtask
  static void _scheduleStateMachineRun(
      InterpreterVisitor visitor, AsyncExecutionState state) {
    // Check if the completer is already completed to avoid unnecessary executions
    if (state.completer.isCompleted) {
      Logger.debug(
          " [_scheduleStateMachineRun] Completer already completed. Skipping schedule.");
      return;
    }
    Future.microtask(() => _runStateMachine(visitor, state))
        .catchError((error, stackTrace) {
      // Catch errors not caught by the internal logic of _runStateMachine
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

    // 1. Find an enclosing TryStatement
    TryStatement? enclosingTry =
        _findEnclosingTryStatement(nodeWhereErrorOccurred);

    CatchClause? matchingCatchClause;
    if (enclosingTry != null) {
      Logger.debug(
          " [_handleAsyncError] Found enclosing TryStatement: ${enclosingTry.offset}");
      state.activeTryStatement = enclosingTry; // Marquer comme actif

      // 2. Find a matching CatchClause (simplified: take the first one)
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
      // 3. Error caught: Prepare the jump to the Catch block
      state.nextStateIdentifier = matchingCatchClause
          .body.statements.firstOrNull; // Start of the catch block

      // Update the state for rethrow
      final internalError = InternalInterpreterException(
          error ?? Exception("Unknown error caught")); // Pass only the error
      state.originalErrorForRethrow = internalError;
      state.isHandlingErrorForRethrow = true;

      // Define the exception variable in the catch environment
      // For now, define in the current environment (can cause collisions)
      final exceptionParameter = matchingCatchClause.exceptionParameter;
      if (exceptionParameter != null) {
        final varName = exceptionParameter.name.lexeme;
        // Use the state environment to define the catch variables
        state.environment.define(varName, error);
        Logger.debug(
            " [_handleAsyncError] Defined exception variable '$varName' in environment.");

        // Handle the stack trace parameter if it exists
        final stackTraceParameter = matchingCatchClause.stackTraceParameter;
        if (stackTraceParameter != null) {
          final stackVarName = stackTraceParameter.name.lexeme;
          state.environment.define(stackVarName, stackTrace);
          Logger.debug(
              "[_handleAsyncError] Defined stack trace variable '$stackVarName' in environment.");
        }
      }

      // Clear the error state because it is handled
      state.currentError = null;
      state.currentStackTrace = null;

      // Reschedule the execution to start the catch block
      Logger.debug(
          " [_handleAsyncError] Scheduling run for CatchClause block.");
      _scheduleStateMachineRun(visitor, state);
    } else {
      // 4. Error not caught or no try:
      //    a) Check if there is a finally to execute anyway
      if (enclosingTry != null && enclosingTry.finallyBlock != null) {
        // Reset rethrow state if jumping to finally
        state.isHandlingErrorForRethrow = false;
        state.originalErrorForRethrow = null;

        Logger.debug(
            " [_handleAsyncError] Error not caught, but finally block exists. Jumping to finally.");
        // The next state is the start of the finally block
        state.nextStateIdentifier =
            enclosingTry.finallyBlock!.statements.firstOrNull;

        // IMPORTANT: The error remains in state.currentError to be rethrown AFTER the finally.
        // _findNextSequentialNode will handle the transition *after* the finally.
        // The main loop of the state machine will check state.currentError at the end.
        _scheduleStateMachineRun(visitor, state);
      } else {
        //    b) Propagate the error by completing the main Future
        // Reset rethrow state before propagating
        state.isHandlingErrorForRethrow = false;
        state.originalErrorForRethrow = null;

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
      // Do not search beyond the current function's limit
      if (current is FunctionBody) {
        return null;
      }
      current = current.parent;
    }
    return null;
  }

  // Determine the next AST node to execute after the resolution of an awaited Future.
  static AstNode? _determineNextNodeAfterAwait(InterpreterVisitor visitor,
      AsyncExecutionState state, AstNode nodeThatCausedSuspension) {
    Object? futureResult = state.lastAwaitResult;
    final currentExecutionEnvironment =
        state.forLoopEnvironment ?? state.environment;
    Logger.debug(
        "[_determineNextNodeAfterAwait] Modifying environment: ${currentExecutionEnvironment.hashCode} (state.environment: ${state.environment.hashCode}, state.forLoopEnvironment: ${state.forLoopEnvironment?.hashCode})");

    Logger.debug(
        "[_determineNextNodeAfterAwait] Resuming after await. Node causing suspension: ${nodeThatCausedSuspension.runtimeType}, Result: $futureResult");

    // The node that caused the suspension is either the AwaitExpression itself,
    // or a parent node (like WhileStatement) if the await was in its condition.

    // Determine the actual context of the await.
    AstNode awaitContextNode;
    Expression? awaitExpression;

    if (nodeThatCausedSuspension is AwaitExpression) {
      awaitExpression = nodeThatCausedSuspension;
      awaitContextNode = nodeThatCausedSuspension.parent ??
          nodeThatCausedSuspension; // Use the parent as context
    } else if (nodeThatCausedSuspension is ExpressionStatement &&
        nodeThatCausedSuspension.expression is AwaitExpression) {
      // Case where the await was directly the expression of an ExpressionStatement
      awaitExpression = nodeThatCausedSuspension.expression as AwaitExpression;
      awaitContextNode = nodeThatCausedSuspension;
    } else if (nodeThatCausedSuspension is WhileStatement &&
        nodeThatCausedSuspension.condition is AwaitExpression) {
      // Special case: the await was directly the condition of a WhileStatement
      awaitContextNode =
          nodeThatCausedSuspension; // The WhileStatement is the context
      awaitExpression = nodeThatCausedSuspension.condition as AwaitExpression;
    } else if (nodeThatCausedSuspension is DoStatement &&
        nodeThatCausedSuspension.condition is AwaitExpression) {
      // Special case: the await was directly the condition of a DoStatement
      awaitContextNode =
          nodeThatCausedSuspension; // The DoStatement is the context
      awaitExpression = nodeThatCausedSuspension.condition as AwaitExpression;
    } else {
      // We don't know how to extract the await, use the node directly
      // (may lead to errors if the logic below does not handle this node)
      awaitContextNode = nodeThatCausedSuspension;
      awaitExpression = null; // We don't know where the await was exactly
      Logger.warn(
          "[_determineNextNodeAfterAwait] Could not determine exact await context for node type ${nodeThatCausedSuspension.runtimeType}. Using node as context.");
    }

    Logger.debug(
        "[_determineNextNodeAfterAwait] Determined await context: ${awaitContextNode.runtimeType}");

    // Logic based on the type of node that contained the await (awaitContextNode)

    // Case 1: Variable declaration (var x = await f();)
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
          // We want to access the property on the resolved Future value
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

      // Find the next sequential node to execute AFTER the await context node.
      return _findNextSequentialNode(visitor, awaitContextNode);
    }

    // NEW CASE 1.5: Resume after await in the initializer of a declaration IN a block.
    // This happens when `nodeThatCausedSuspension` is the ExpressionStatement or VariableDeclarationStatement itself,
    // but `_determineNextNodeAfterAwait` is called *after* the Future resolves.
    else if (nodeThatCausedSuspension is VariableDeclarationStatement) {
      final varDeclStatement = nodeThatCausedSuspension;
      final varList = varDeclStatement.variables;
      // Like in Case 1, find the variable that awaited.
      VariableDeclaration? targetVar = varList.variables.firstWhereOrNull(
          (v) => v.initializer is AwaitExpression
          // We need a better way to link the suspension back to the AwaitExpression node
          // For now, assume the FIRST variable with an AwaitExpression initializer in this statement
          );
      targetVar ??=
          varList.variables.first; // Fallback: assume it was the first variable

      // Use define() because the variable was not defined during the initial visit
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

      // Find the next instruction AFTER this declaration
      return _findNextSequentialNode(visitor, varDeclStatement);
    }

    // Case 2: Expression statement (await f(); or var x = await f(); or x = await f(); etc.)
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
        // Use define() because the variable was not defined during the initial visit
        currentEnv.define(targetVar.name.lexeme, futureResult);
        // SPECULATIVE FIX: Try assigning immediately after defining
        try {
          currentEnv.assign(targetVar.name.lexeme, futureResult);
        } catch (assignError) {
          Logger.warn(
              "[_determineNextNodeAfterAwait] Speculative assign after define failed (VarDeclList): $assignError");
        }
        try {
          final checkValue2 = currentEnv.get(targetVar.name.lexeme);
          Logger.debug(
              "[_determineNextNodeAfterAwait] Check after define+assign: '${targetVar.name.lexeme}' in env ${currentEnv.hashCode} is $checkValue2 (${checkValue2?.runtimeType}) <Expected: $futureResult>");
        } catch (e) {
          Logger.debug(
              "[_determineNextNodeAfterAwait] Check after define+assign FAILED for '${targetVar.name.lexeme}': $e");
        }
        Logger.debug(
            " [_determineNextNodeAfterAwait] Defined/Assigned variable '${targetVar.name.lexeme}' = $futureResult (Case 2 - VarDecl). Finding next node.");

        // Find the next statement after this ExpressionStatement
        return _findNextSequentialNode(visitor, awaitContextNode);
      } else if (expression is AssignmentExpression) {
        // Case: x += await f(); or x = await f();
        // This is the primary handler now as the context is the ExpressionStatement.
        final assignmentNode = expression; // Already cast
        Object? resolvedRhs = state.lastAwaitResult; // La valeur résolue
        final operatorType = assignmentNode.operator.type;
        final lhs = assignmentNode.leftHandSide;
        final currentEnv =
            state.forLoopEnvironment ?? currentExecutionEnvironment;

        Logger.debug(
            " [_determineNextNodeAfterAwait] Resuming ExpressionStatement(AssignmentExpression Op: $operatorType). RHS: $resolvedRhs (${resolvedRhs?.runtimeType})");

        // Determine the next node AFTER the ExpressionStatement
        final AstNode? nextNode =
            _findNextSequentialNode(visitor, awaitContextNode);

        if (operatorType == TokenType.EQ) {
          if (lhs is SimpleIdentifier) {
            final propertyAccess = expression.childEntities.lastOrNull;
            if (propertyAccess != null && propertyAccess is PropertyAccess) {
              if (propertyAccess.target is ParenthesizedExpression) {
                // We want to access the property on the resolved Future value
                final propertyName = propertyAccess.propertyName.name;
                final (bridgedInstance, isBridgedInstance) =
                    visitor.toBridgedInstance(resolvedRhs);
                if (isBridgedInstance) {
                  final getterAdapter = bridgedInstance!.bridgedClass
                      .findInstanceGetterAdapter(propertyName);
                  if (getterAdapter != null) {
                    final getterResult =
                        getterAdapter(visitor, bridgedInstance.nativeObject);

                    resolvedRhs = getterResult;
                  }

                  final methodAdapter = bridgedInstance.bridgedClass
                      .findInstanceMethodAdapter(propertyName);
                  if (methodAdapter != null) {
                    // Return a callable bound to the instance
                    final boundCallable = BridgedMethodCallable(
                        bridgedInstance, methodAdapter, propertyName);

                    resolvedRhs = boundCallable;
                  }
                }
              }
            }
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
            // Attempt: Re-execute the assignment now that RHS is known (may fail)
            // This approach is risky because it re-evaluates the LHS.
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

    // Case 3: Return statement (return await f();)
    else if (awaitContextNode is ReturnStatement && awaitExpression != null) {
    }

    // Case 4: Function body expression (=> await f();)
    else if (awaitContextNode is ExpressionFunctionBody &&
        awaitExpression != null) {
    }

    // Case 5: Assignment (x = await f(); or x += await f();)
    else if (awaitContextNode is AssignmentExpression) {
      final assignmentNode = awaitContextNode;
      final resolvedRhs = state.lastAwaitResult; // The resolved Future value
      final operatorType = assignmentNode.operator.type;
      final lhs = assignmentNode.leftHandSide;
      // Use the correct environment (the loop environment if applicable)
      final currentEnv =
          state.forLoopEnvironment ?? currentExecutionEnvironment;

      Logger.debug(
          " [_determineNextNodeAfterAwait] Resuming AssignmentExpression (Operator: $operatorType). RHS resolved to: $resolvedRhs (${resolvedRhs?.runtimeType})");

      // Determine the next node BEFORE making the assignment (because _findNext may depend on the parent)
      AstNode? parentStatement = assignmentNode;
      while (parentStatement != null && parentStatement is! Statement) {
        parentStatement = parentStatement.parent;
      }
      final AstNode? nextNode = (parentStatement is Statement)
          ? _findNextSequentialNode(visitor, parentStatement)
          : null; // If we don't find the parent statement, we'll stop

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

    // Case 6: If condition (if (await f()))
    else if (awaitContextNode is IfStatement && awaitExpression != null) {
      // ... (unchanged logic, but ensure it uses awaitContextNode) ...
    } else if (awaitContextNode is WhileStatement) {
      // The await was in the condition
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
        // Condition true: the next state is the body of the loop
        Logger.debug(
            " [_determineNextNodeAfterAwait] While condition TRUE. Next node is body: ${awaitContextNode.body.runtimeType}");
        if (awaitContextNode.body is Block) {
          return (awaitContextNode.body as Block).statements.firstOrNull;
        } else {
          return awaitContextNode.body;
        }
      } else {
        // Condition false: find the next instruction after the while
        Logger.debug(
            " [_determineNextNodeAfterAwait] While condition FALSE. Finding node after while.");
        return _findNextSequentialNode(visitor, awaitContextNode);
      }
    } else if (awaitContextNode is DoStatement) {
      // The await was in the condition
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
        // Condition true: the next state is the beginning of the loop body
        Logger.debug(
            " [_determineNextNodeAfterAwait] DoWhile condition TRUE. Next node is body: ${awaitContextNode.body.runtimeType}");
        if (awaitContextNode.body is Block) {
          return (awaitContextNode.body as Block).statements.firstOrNull;
        } else {
          return awaitContextNode.body;
        }
      } else {
        // Condition false: find the next instruction after the do-while
        Logger.debug(
            " [_determineNextNodeAfterAwait] DoWhile condition FALSE. Finding node after do-while.");
        return _findNextSequentialNode(visitor, awaitContextNode);
      }
    } else if (awaitContextNode is IfStatement) {
      // The await was in the condition
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
        // Condition true: the next state is the 'then' branch
        Logger.debug(
            " [_determineNextNodeAfterAwait] If condition TRUE. Next node is thenBranch: ${ifNode.thenStatement.runtimeType}");
        if (ifNode.thenStatement is Block) {
          return (ifNode.thenStatement as Block).statements.firstOrNull;
        } else {
          return ifNode.thenStatement;
        }
      } else {
        // Condition false: check the 'else' branch
        if (ifNode.elseStatement != null) {
          Logger.debug(
              "[_determineNextNodeAfterAwait] If condition FALSE. Next node is elseBranch: ${ifNode.elseStatement?.runtimeType}");
          if (ifNode.elseStatement is Block) {
            return (ifNode.elseStatement as Block).statements.firstOrNull;
          } else {
            return ifNode.elseStatement;
          }
        } else {
          // No else branch, find the next instruction after the if
          Logger.debug(
              "[_determineNextNodeAfterAwait] If condition FALSE, no else branch. Finding node after IfStatement.");
          return _findNextSequentialNode(visitor, ifNode);
        }
      }
    } else if (awaitContextNode is ForStatement &&
        (awaitContextNode.forLoopParts is ForPartsWithDeclarations ||
            awaitContextNode.forLoopParts is ForPartsWithExpression)) {
      final forNode = awaitContextNode;
      // Use nodeThatCausedSuspension to find where the await occurred
      // AstNode? nodeThatContainedAwait = nodeThatCausedSuspension; // Can be AwaitExpression or ForStatement if await in condition/updater
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
            // Condition true -> Go to body
            Logger.debug(
                " [_determineNextNodeAfterAwait] For condition TRUE. Next node is body.");
            if (forNode.body is Block) {
              return (forNode.body as Block).statements.firstOrNull;
            } else {
              return forNode.body;
            }
          } else {
            // Condition false -> Exit loop
            Logger.debug(
                " [_determineNextNodeAfterAwait] For condition FALSE. Finding node after loop.");
            state.forLoopInitialized = false; // Clean up state
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
    return null; // Default stop state machine
  }

  // Implementation of the logic to find the next sequential node
  static AstNode? _findNextSequentialNode(
      InterpreterVisitor visitor, AstNode currentNode) {
    AstNode? parent = currentNode.parent;
    AsyncExecutionState? state =
        visitor.currentAsyncState; // Can be null if not async

    Logger.debug(
        "[_findNextSequentialNode] Finding next node after: ${currentNode.runtimeType} (parent: ${parent?.runtimeType})");

    // Handle the end of an instruction in a block
    if (currentNode is Statement && parent is Block) {
      final block = parent;
      final index = block.statements.indexOf(currentNode);
      bool isLastStatement =
          (index != -1 && index == block.statements.length - 1);

      if (!isLastStatement && index != -1) {
        // Simple case: next instruction in the same block
        Logger.debug(
            " [_findNextSequentialNode] Next sequential node in block: ${block.statements[index + 1].runtimeType}");
        return block.statements[index + 1];
      } else if (isLastStatement) {
        // It was the last instruction in the block. What next?
        Logger.debug(" [_findNextSequentialNode] Reached end of a Block.");

        AstNode? blockParent = block.parent;

        // Case 1: End of a Try block
        if (blockParent is TryStatement && blockParent.body == block) {
          Logger.debug("[_findNextSequentialNode] End of Try block.");
          // Are there any catch clauses?
          if (blockParent.catchClauses.isNotEmpty) {
            // If there are catch clauses, normal execution skips them.
            // They are only reached by an exception handled by _handleAsyncError.
            // So, after the try, we look for the finally or the next code.
            Logger.debug(
                " [_findNextSequentialNode] Try block finished normally, skipping catches.");
          }
          // Check if there is a finally block
          if (blockParent.finallyBlock != null) {
            Logger.debug(
                " [_findNextSequentialNode] Found finally block after Try. Jumping to finally.");
            // The next node is the beginning of the finally block
            final firstFinallyStmt =
                blockParent.finallyBlock!.statements.firstOrNull;
            if (firstFinallyStmt != null) {
              return firstFinallyStmt;
            } else {
              // Finally block is empty, find what follows the TryStatement
              Logger.debug(
                  "[_findNextSequentialNode] Finally block is empty. Finding node after TryStatement.");
              if (state != null) {
                state.activeTryStatement = null; // End of try handling
              }
              return _findNextSequentialNode(visitor, blockParent);
            }
          } else {
            // No catch (normally skipped) and no finally, skip after the TryStatement
            Logger.debug(
                " [_findNextSequentialNode] No finally block after Try. Finding node after TryStatement.");
            if (state != null) {
              state.activeTryStatement = null; // End of try handling
            }
            return _findNextSequentialNode(visitor, blockParent);
          }
        }
        // Case 2: End of a Catch block
        else if (blockParent is CatchClause) {
          Logger.debug("[_findNextSequentialNode] End of Catch block.");
          TryStatement? tryStatement = _findEnclosingTryStatement(blockParent);
          // After a catch, we must ALWAYS execute the finally if it exists
          if (tryStatement != null && tryStatement.finallyBlock != null) {
            Logger.debug(
                " [_findNextSequentialNode] Found finally block after Catch. Jumping to finally.");
            // The next node is the beginning of the finally block
            final firstFinallyStmt =
                tryStatement.finallyBlock!.statements.firstOrNull;
            if (firstFinallyStmt != null) {
              return firstFinallyStmt;
            } else {
              // Finally block is empty, find what follows the TryStatement
              Logger.debug(
                  "[_findNextSequentialNode] Finally block is empty (after catch). Finding node after TryStatement.");
              if (state != null) {
                state.activeTryStatement = null; // End of try handling
              }
              return _findNextSequentialNode(visitor, tryStatement);
            }
          } else {
            // No finally, skip after the TryStatement
            Logger.debug(
                " [_findNextSequentialNode] No finally block after Catch. Finding node after TryStatement.");
            if (state != null) {
              state.activeTryStatement = null; // End of try handling
            }
            return _findNextSequentialNode(visitor,
                tryStatement ?? blockParent); // Go back to the Try or Catch
          }
        }
        // Case 3: End of a Finally block
        else if (blockParent is TryStatement &&
            blockParent.finallyBlock == block) {
          Logger.debug("[_findNextSequentialNode] End of Finally block.");
          // After a finally, we look for the next node after the TryStatement
          // If an error was in progress, it will be rethrown by the main loop.
          if (state != null) {
            state.activeTryStatement = null; // End of try handling
          }
          return _findNextSequentialNode(visitor, blockParent);
        }
        // Case 4: End of a loop block (While, DoWhile, For, ForIn)
        else if (blockParent is WhileStatement && blockParent.body == block) {
          Logger.debug(
              "[_findNextSequentialNode] End of While body Block. Returning WhileStatement node.");
          return blockParent; // Go back to the WhileStatement to re-evaluate the condition
        } else if (blockParent is DoStatement && blockParent.body == block) {
          Logger.debug(
              "[_findNextSequentialNode] End of DoWhile body Block. Returning DoStatement node.");
          return blockParent; // Go back to the DoStatement to re-evaluate the condition
        } else if (blockParent is ForStatement && blockParent.body == block) {
          // Applies to both standard For and For-In
          Logger.debug(
              "[_findNextSequentialNode] End of For/For-In body Block. Returning ForStatement node.");
          return blockParent; // Go back to the ForStatement to evaluate the next iteration/condition
        }

        // Case 5: End of an If/Else block
        else if (blockParent is IfStatement) {
          // Whether it's the end of the 'then' or the 'else', we look after the entire IfStatement
          Logger.debug(
              "[_findNextSequentialNode] End of If/Else Block. Finding node after IfStatement.");
          return _findNextSequentialNode(visitor, blockParent);
        }

        // Generic case: end of an unhandled block
        else {
          Logger.debug(
              "[_findNextSequentialNode] End of generic Block (parent: ${blockParent?.runtimeType}). Finding node after parent Block.");
          // Go back to the parent of the block to find the next node
          return _findNextSequentialNode(visitor, block);
        }
      }
      // If index == -1 (should not happen unless internal error), go back
      else {
        Logger.warn(
            "[_findNextSequentialNode] Statement not found in parent block? Finding node after parent block.");
        return _findNextSequentialNode(visitor, parent);
      }
    }

    AstNode? currentSearchNode = currentNode;
    while (currentSearchNode != null) {
      parent = currentSearchNode.parent;

      // Handle the end of the body (single statement) of a While loop
      if (currentSearchNode is Statement &&
          parent is WhileStatement &&
          parent.body == currentSearchNode) {
        Logger.debug(
            " [_findNextSequentialNode] End of While body (single statement). Returning WhileStatement node.");
        return parent;
      }

      // Handle the end of the body (single statement) of a DoWhile loop
      if (currentSearchNode is Statement &&
          parent is DoStatement &&
          parent.body == currentSearchNode) {
        Logger.debug(
            " [_findNextSequentialNode] End of DoWhile body (single statement). Returning DoStatement node.");
        return parent;
      }

      // Handle the end of the body (single statement) of a standard For loop or For-In loop
      if (currentSearchNode is Statement &&
          parent is ForStatement &&
          parent.body == currentSearchNode) {
        Logger.debug(
            " [_findNextSequentialNode] End of standard For/For-In body (single statement). Returning ForStatement node.");
        return parent;
      }

      // Handle the end of the 'then' branch (single statement) of an IfStatement
      if (currentSearchNode is Statement &&
          parent is IfStatement &&
          parent.thenStatement == currentSearchNode) {
        // If there is an 'else' branch, do nothing (execution stops here for this branch)
        // If there is NO 'else' branch, find the node AFTER the IfStatement.
        if (parent.elseStatement == null) {
          Logger.debug(
              "[_findNextSequentialNode] End of If 'then' (single statement, no else). Finding node after IfStatement.");
          return _findNextSequentialNode(visitor, parent);
        } else {
          Logger.debug(
              "[_findNextSequentialNode] End of If 'then' (single statement, with else). Stopping this path.");
          // There is no "next sequential node" after the then if there is an else.
          return null;
        }
      }

      // Handle the end of the 'else' branch (single statement) of an IfStatement
      if (currentSearchNode is Statement &&
          parent is IfStatement &&
          parent.elseStatement == currentSearchNode) {
        // After the 'else', we always look for the node AFTER the entire IfStatement.
        Logger.debug(
            " [_findNextSequentialNode] End of If 'else' (single statement). Finding node after IfStatement.");
        return _findNextSequentialNode(visitor, parent);
      }

      // If we didn't find a specific control structure parent,
      // check if the parent is a statement that can be sequenced.

      if (parent is Block) {
        // If the parent is a Block, the logic at the beginning (block handling) applies.
        // Call recursively so that this logic takes over.
        Logger.debug(
            " [_findNextSequentialNode] Ascending into a Block. Re-evaluating block logic for the parent Block.");
        return _findNextSequentialNode(visitor, parent);
      } else if (parent is Statement) {
        // If the parent is another statement, continue ascending
        // to find the enclosing block or function.
        Logger.debug(
            " [_findNextSequentialNode] Ascending from Statement (${currentSearchNode.runtimeType}) to parent (${parent.runtimeType}).");
        currentSearchNode = parent;
      } else if (parent is FunctionBody || parent is CompilationUnit) {
        // Reached the limit of the function or file
        Logger.debug(
            " [_findNextSequentialNode] Reached FunctionBody or CompilationUnit. Returning null.");
        return null;
      } else if (parent == null) {
        // Reached the root of the AST
        Logger.debug(
            " [_findNextSequentialNode] Reached top level (null parent). Returning null.");
        return null;
      } else {
        // Unhandled parent (Expression, etc.) - continue ascending
        Logger.debug(
            " [_findNextSequentialNode] Ascending from non-statement parent (${parent.runtimeType}).");
        currentSearchNode = parent;
      }
    }

    Logger.debug(
        "[_findNextSequentialNode] Could not determine next sequential node (fell through). Returning null.");
    return null; // Fallback
  }

  // Replace the old placeholder _startAsyncStateMachine
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

// Represents a bridged instance method that has been bound to a specific instance.
class BridgedMethodCallable implements Callable {
  final BridgedInstance _instance; // The native target instance
  final BridgedMethodAdapter _adapter; // The adapter function
  final String _methodName;

  BridgedMethodCallable(this._instance, this._adapter, this._methodName);

  @override
  int get arity {
    // The arity is complex to determine statically for native adapters.
    // For now, return 0, but the adapter itself will do the validation.
    // We could improve this if the adapters provide metadata.
    return 0;
  }

  @override
  Object? call(InterpreterVisitor visitor, List<Object?> positionalArguments,
      [Map<String, Object?> namedArguments = const {},
      List<RuntimeType>? typeArguments]) {
    try {
      // Call the adapter with the native object of the instance and the arguments
      return _adapter(
          visitor, _instance.nativeObject, positionalArguments, namedArguments);
    } on ArgumentError catch (e) {
      // Convert native ArgumentError to RuntimeError
      throw RuntimeError(
          "Invalid arguments for bridged method '${_instance.bridgedClass.name}.$_methodName': ${e.message}");
    } catch (e, s) {
      // Handle other native errors
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
    // 1. Extract the target instance (first argument)
    if (positionalArguments.isEmpty) {
      throw RuntimeError(
          "Internal error: Extension method '${declaration.name.lexeme}' called without target instance ('this').");
    }
    final targetInstance =
        positionalArguments.removeAt(0); // Consomme le premier argument

    // 2. Create the execution environment
    final executionEnvironment = Environment(enclosing: closure);
    // Define 'this' in this environment
    executionEnvironment.define('this', targetInstance);
    Logger.debug(
        "[InterpretedExtensionMethod.call] Created execution env (${executionEnvironment.hashCode}) for '${declaration.name.lexeme}', defining 'this'=${targetInstance?.runtimeType}");

    // 3. Bind the declared parameters (explicit arguments)
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

        // Determine the parameter info (copied from InterpretedFunction)
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

        // Find the corresponding argument and value
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

        // Handle default values and required checks
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
        // Define the variable in the execution environment
        executionEnvironment.define(paramName, valueToDefine);
        Logger.debug(
            " [InterpretedExtensionMethod.call] Bound param '$paramName' = $valueToDefine");
      }

      // Final argument checks (copied from InterpretedFunction)
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

    // 4. Execute the body in the new environment
    final previousEnvironment = visitor.environment;
    final previousFunction = visitor.currentFunction;
    // visitor.currentFunction = ???;
    visitor.environment = executionEnvironment; // USE THE NEW ENVIRONMENT
    Logger.debug(
        "[InterpretedExtensionMethod.call] Set visitor environment to executionEnvironment (${executionEnvironment.hashCode}) before executing body.");

    try {
      final body = declaration.body;
      if (body is BlockFunctionBody) {
        // executeBlock already handles ReturnException correctly
        return visitor.executeBlock(
            body.block.statements, executionEnvironment);
      } else if (body is ExpressionFunctionBody) {
        // For an expression body, evaluate and return the value
        final result = body.expression.accept<Object?>(visitor);
        // No need to raise ReturnException here, we return directly
        return result;
      } else if (body is EmptyFunctionBody) {
        throw RuntimeError(
            "Cannot execute empty body for extension method '${declaration.name.lexeme}'.");
      } else {
        throw UnimplementedError(
            'Function body type not handled in extension method: ${body.runtimeType}');
      }
    } on ReturnException catch (e) {
      // Catch in case executeBlock (or other) still raises ReturnException
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

/// Represents an extension method bound to a target instance.
///
/// Stores the instance (`target`) and the extension method (`extensionMethod`).
/// When `call` is invoked, it calls the underlying extension method,
/// automatically inserting the target instance as the first positional argument.
class BoundExtensionMethodCallable implements Callable {
  final Object? target; // The 'this' instance to which the method is bound.
  final InterpretedExtensionMethod extensionMethod;

  BoundExtensionMethodCallable(this.target, this.extensionMethod);

  // The arity of the bound method is the arity of the original extension method.
  @override
  int get arity => extensionMethod.arity;

  @override
  Object? call(InterpreterVisitor visitor, List<Object?> positionalArguments,
      [Map<String, Object?> namedArguments = const {},
      List<RuntimeType>? typeArguments = const []]) {
    // Prepare the arguments for the actual call to the InterpretedExtensionMethod:
    // The first argument is ALWAYS the target instance.
    final actualPositionalArgs = [target, ...positionalArguments];

    Logger.debug(
        "[BoundExtensionMethodCallable] Calling extension method '${extensionMethod.declaration.name.lexeme}' bound to ${target?.runtimeType}");

    // Call the original extension method with the adjusted arguments.
    // It will handle ReturnException, etc.
    return extensionMethod.call(
        visitor, actualPositionalArgs, namedArguments, typeArguments);
  }
}
