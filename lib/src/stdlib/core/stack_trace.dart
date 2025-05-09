import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';
import 'dart:core'; // For StackTrace type

class StackTraceCore implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    // StackTrace objects are typically obtained from exceptions, not constructed directly.
    // Define the type name.
    environment.define(
        'StackTrace',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          return StackTrace;
        }, arity: 0, name: 'StackTrace'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is! StackTrace) {
      throw RuntimeError(
          'Target for StackTrace method call must be a StackTrace, but was ${target?.runtimeType}');
    }

    switch (name) {
      case 'toString':
        if (arguments.isNotEmpty || namedArguments.isNotEmpty) {
          throw RuntimeError('StackTrace.toString expects no arguments.');
        }
        return target.toString();
      // Add hashCode if needed
      case 'hashCode':
        return target.hashCode;
      default:
        // Note: Dart's StackTrace has few public methods.
        throw RuntimeError('StackTrace has no method mapping for "$name"');
    }
  }
}
