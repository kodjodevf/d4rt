import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/exceptions.dart';

/// Represents the state of an ongoing asynchronous function execution.
/// This object tracks the progress and context needed for resumption.
class AsyncExecutionState {
  /// The unique environment for this specific function call.
  final Environment environment;

  /// The completer associated with the Future returned to the caller.
  final Completer<Object?> completer;

  /// An identifier for the next block of code (state) to execute.
  /// This could be an integer index, an AST node reference, etc.
  /// (Needs further definition based on the state machine implementation).
  AstNode? nextStateIdentifier;

  /// The result value from the most recently completed Future (from await).
  Object? lastAwaitResult;

  /// The error from the most recently completed Future (if it failed).
  Object? lastAwaitError;

  /// The stack trace from the most recently completed Future (if it failed).
  StackTrace? lastAwaitStackTrace;

  /// Optional: Store the iterator for ongoing for-in loops.
  Iterator<Object?>? currentForInIterator;

  /// Optional: Flag for standard for-loops.
  bool forLoopInitialized = true;

  /// Optional: Environment for the current standard for-loop scope.
  Environment? forLoopEnvironment;

  /// Stack of loop environments for nested loops
  final List<Environment> loopEnvironmentStack = [];

  /// Stack of initialization flags for nested loops
  final List<bool> loopInitializedStack = [];

  /// Stack of ForStatement nodes corresponding to the environments
  final List<ForStatement> loopNodeStack = [];

  /// Optional: A reference back to the function definition might be useful.
  final InterpretedFunction function;

  /// NEW FLAG
  bool resumedFromInitializer = false;

  /// Track pending finally block to execute after try/catch
  Block? pendingFinallyBlock;

  /// Track the error currently being handled (either from await or sync throw)
  Object? currentError;

  /// Track the stack trace currently being handled (either from await or sync throw)
  StackTrace? currentStackTrace;

  /// Track the TryStatement we are currently inside or handling
  TryStatement? activeTryStatement;

  /// Store return value if a return happens inside a try with a finally.
  Object? returnAfterFinally;

  /// Flag to indicate if we are currently executing a catch block body.
  bool isHandlingErrorForRethrow = false;

  /// Store the original exception wrapped for potential rethrow.
  InternalInterpreterException? originalErrorForRethrow;

  /// Flag to indicate if we are resuming an invocation with await in arguments
  /// When true, await expressions should return the last resolved value instead of suspending
  bool isInvocationResumptionMode = false;

  /// Fields for await for loop processing
  List<Object?>? currentAwaitForList;

  /// Current index when processing await for loops with stream conversion.
  /// Used to track position in the converted list from a stream.
  int? currentAwaitForIndex;

  /// Flag indicating if the interpreter is currently waiting for stream conversion.
  /// When true, indicates that a stream is being converted to a list for await-for processing.
  bool awaitingStreamConversion = false;

  /// Creates a new async execution state.
  ///
  /// [environment] The execution environment for the async function.
  /// [completer] The completer that will complete when the function finishes.
  /// [nextStateIdentifier] The AST node representing the next state to execute.
  /// [function] The interpreted function being executed asynchronously.
  AsyncExecutionState({
    required this.environment,
    required this.completer,
    required this.nextStateIdentifier,
    required this.function,
    this.lastAwaitResult,
    this.lastAwaitError,
    this.lastAwaitStackTrace,
    this.currentForInIterator,
    this.forLoopInitialized = false,
    this.forLoopEnvironment,
    this.pendingFinallyBlock,
    this.currentError,
    this.currentStackTrace,
    this.activeTryStatement,
    this.returnAfterFinally,
    this.isHandlingErrorForRethrow = false,
    this.originalErrorForRethrow,
  });
}

/// Represents a request to suspend execution and wait for a Future.
/// This object is returned by visitor methods when an await is encountered.
class AsyncSuspensionRequest {
  /// The Future that needs to be awaited.
  final Future<Object?> future;

  /// The state object associated with the execution that needs suspension.
  /// This is needed by the scheduler to know which execution to resume later.
  final AsyncExecutionState asyncState;

  /// Creates a new async suspension request.
  ///
  /// [future] The Future that the interpreter should wait for.
  /// [asyncState] The current execution state that will be resumed after the Future completes.
  AsyncSuspensionRequest(this.future, this.asyncState);
}
