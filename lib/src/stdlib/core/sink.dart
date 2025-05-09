import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';
import 'dart:core';

class SinkCore implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    // Sink is an abstract class, usually implemented by others (like IOSink).
    // Define the type name.
    environment.define(
        'Sink',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          return Sink;
        }, arity: 0, name: 'Sink'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is! Sink) {
      // Or check for specific implementations if needed
      throw RuntimeError(
          'Target for Sink method call must be a Sink, but was ${target?.runtimeType}');
    }

    switch (name) {
      case 'add':
        if (arguments.length != 1) {
          throw RuntimeError('Sink.add requires exactly one argument.');
        }
        // Casting to Sink<dynamic> might be safer depending on target type
        target.add(arguments[0]);
        return null;
      case 'close':
        if (arguments.isNotEmpty || namedArguments.isNotEmpty) {
          throw RuntimeError('Sink.close expects no arguments.');
        }
        target.close();
        return null;
      // Add hashCode, toString if needed
      case 'hashCode':
        return target.hashCode;
      case 'toString':
        return target.toString();
      default:
        throw RuntimeError('Sink has no method mapping for "$name"');
    }
  }
}
