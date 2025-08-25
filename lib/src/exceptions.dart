/// Custom exception for runtime errors during interpretation.
///
/// This exception is thrown when the interpreter encounters an error
/// during code execution, such as accessing undefined variables,
/// calling non-existent methods, or type mismatches.
class RuntimeError implements Exception {
  /// The error message describing what went wrong.
  final String message;

  /// Creates a new runtime error with the given message.
  RuntimeError(this.message);

  @override
  String toString() => 'Runtime Error: $message';
}

/// Internal exception used to unwind the stack during a 'return' statement.
///
/// This exception is used internally by the interpreter to implement
/// return statement control flow. It carries the return value up the call stack.
class ReturnException implements Exception {
  /// The value being returned from the function.
  final Object? value;

  /// Creates a new return exception with the given return value.
  const ReturnException(this.value);
}

/// Internal exception used to unwind the stack during a 'break' statement.
///
/// This exception is used internally by the interpreter to implement
/// break statement control flow in loops and switch statements.
class BreakException implements Exception {
  /// Optional label for labeled break statements.
  final String? label;

  /// Creates a new break exception, optionally with a label.
  const BreakException([this.label]);

  @override
  String toString() => 'BreakException(label: $label)';
}

/// Internal exception used to unwind the stack during a 'continue' statement.
///
/// This exception is used internally by the interpreter to implement
/// continue statement control flow in loops.
class ContinueException implements Exception {
  /// Optional label for labeled continue statements.
  final String? label;

  /// Creates a new continue exception, optionally with a label.
  const ContinueException([this.label]);

  @override
  String toString() => 'ContinueException(label: $label)';
}

/// Exception thrown when there's an issue with the source code itself,
/// like parsing errors or missing files.
///
/// This exception indicates problems with the Dart source code being
/// interpreted, such as syntax errors, missing imports, or invalid URIs.
class SourceCodeException implements Exception {
  /// The error message describing the source code problem.
  final String message;

  /// Creates a new source code exception with the given message.
  SourceCodeException(this.message);

  @override
  String toString() => 'SourceCodeException: $message';
}

/// Internal exception wrapper for user-thrown exceptions.
///
/// This helps distinguish between user 'throw x' exceptions and internal
/// interpreter control flow exceptions like Return/Break/Continue.
/// It wraps the original thrown value for proper exception handling.
class InternalInterpreterException implements Exception {
  /// The original value that was thrown by user code.
  final Object? originalThrownValue;
  // StackTrace could be stored here if needed directly,
  // but catch in visitTryStatement already gets it.

  /// Creates a new internal interpreter exception wrapping the original thrown value.
  InternalInterpreterException(this.originalThrownValue);

  @override
  String toString() {
    // Provide a meaningful representation if needed,
    // but primarily used internally.
    return 'InternalInterpreterException(originalThrownValue: $originalThrownValue)';
  }
}

/// Exception specifically for pattern matching failures.
///
/// This exception is thrown when pattern matching operations fail
/// to match the expected pattern against the actual value.
class PatternMatchException implements Exception {
  /// The error message describing the pattern match failure.
  final String message;

  /// Creates a new pattern match exception with the given message.
  PatternMatchException(this.message);

  @override
  String toString() => "PatternMatchException: $message";
}
