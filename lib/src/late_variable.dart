import 'package:d4rt/d4rt.dart';

/// Represents a late variable that supports lazy initialization
class LateVariable {
  bool _isInitialized = false;
  Object? _value;
  final Object? Function()? _initializer;
  final String _name;
  final bool _isFinal;

  LateVariable(this._name, this._initializer, {bool isFinal = false})
      : _isFinal = isFinal;

  /// Gets the value of the late variable, initializing it if necessary
  Object? get value {
    if (!_isInitialized) {
      if (_initializer != null) {
        // Lazy initialization
        _value = _initializer();
        _isInitialized = true;
        Logger.debug(
            "[LateVariable] Lazy initialized '$_name' with value: $_value");
      } else {
        // Late variable without initializer accessed before assignment
        throw LateInitializationError(
            "LateInitializationError: Late variable '$_name' without initializer is accessed before being assigned.");
      }
    }
    return _value;
  }

  /// Assigns a value to the late variable
  void assign(Object? value) {
    if (_isFinal && _isInitialized) {
      throw LateInitializationError(
          "LateInitializationError: Late final variable '$_name' has already been assigned.");
    }
    _value = value;
    _isInitialized = true;
    Logger.debug("[LateVariable] Assigned '$_name' = $value");
  }

  /// Set the value
  set value(Object? newValue) {
    if (_isInitialized && _isFinal) {
      throw LateInitializationError(
          "LateInitializationError: Field '$_name' has already been initialized.");
    }
    _value = newValue;
    _isInitialized = true;
  }

  /// Check if the variable has been initialized
  bool get isInitialized => _isInitialized;

  @override
  String toString() =>
      'LateVariable($_name, initialized: $_isInitialized, value: $_value)';
}

/// Exception thrown when accessing an uninitialized late variable
class LateInitializationError extends RuntimeError {
  LateInitializationError(super.message);
}
