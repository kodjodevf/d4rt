/// Custom exception for runtime errors during interpretation.
class RuntimeError implements Exception {
  final String message;
  RuntimeError(this.message);

  @override
  String toString() => 'Runtime Error: $message';
}

/// Internal exception used to unwind the stack during a 'return' statement.
class ReturnException implements Exception {
  final Object? value;
  const ReturnException(this.value);
}

/// Internal exception used to unwind the stack during a 'break' statement.
class BreakException implements Exception {
  final String? label;
  const BreakException([this.label]);

  @override
  String toString() => 'BreakException(label: $label)';
}

/// Internal exception used to unwind the stack during a 'continue' statement.
class ContinueException implements Exception {
  final String? label;
  const ContinueException([this.label]);

  @override
  String toString() => 'ContinueException(label: $label)';
}

/// Exception thrown when there's an issue with the source code itself,
/// like parsing errors or missing files.
class SourceCodeException implements Exception {
  final String message;

  SourceCodeException(this.message);

  @override
  String toString() => 'SourceCodeException: $message';
}

// This helps us distinguish between 'throw x' user exceptions and internal interpreter errors
// or control flow exceptions like Return/Break/Continue.
class InternalInterpreterException implements Exception {
  final Object? originalThrownValue;
  // StackTrace could be stored here if needed directly,
  // but catch in visitTryStatement already gets it.

  InternalInterpreterException(this.originalThrownValue);

  @override
  String toString() {
    // Provide a meaningful representation if needed,
    // but primarily used internally.
    return 'InternalInterpreterException(originalThrownValue: $originalThrownValue)';
  }
}

/// Exception specifically for pattern matching failures.
class PatternMatchException implements Exception {
  final String message;
  PatternMatchException(this.message);

  @override
  String toString() => "PatternMatchException: $message";
}
