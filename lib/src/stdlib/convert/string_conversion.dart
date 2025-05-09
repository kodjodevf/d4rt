import 'dart:convert';

import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';

class StringConversionConvert implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'StringConversionSink',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          return StringConversionSink;
        }, arity: 0, name: 'StringConversionSink'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    // StringConversionSink is abstract, but we handle methods defined on it.
    // Target must be an instance of a class implementing it.
    if (target is StringConversionSink) {
      switch (name) {
        case 'add':
          if (arguments.length != 1) {
            throw RuntimeError(
                'StringConversionSink.add requires one argument.');
          }
          // Ensure the argument is a String
          if (arguments[0] is! String) {
            throw RuntimeError(
                'StringConversionSink.add requires a String argument.');
          }
          target.add(arguments[0] as String); // Argument type T is dynamic
          return null;
        case 'addSlice':
          if (arguments.length != 4 ||
              arguments[0] is! String ||
              arguments[1] is! int ||
              arguments[2] is! int ||
              arguments[3] is! bool) {
            throw RuntimeError(
                'StringConversionSink.addSlice requires arguments (String, int, int, bool).');
          }
          target.addSlice(arguments[0] as String, arguments[1] as int,
              arguments[2] as int, arguments[3] as bool);
          return null;
        case 'close':
          if (arguments.isNotEmpty || namedArguments.isNotEmpty) {
            throw RuntimeError(
                'StringConversionSink.close takes no arguments.');
          }
          target.close();
          return null;
        // Methods inherited from Sink<T>
        case 'toString': // From Object
          return target.toString();
        case 'hashCode': // From Object
          return target.hashCode;
        default:
          throw RuntimeError(
              'StringConversionSink has no method mapping for "$name"');
      }
    } else {
      switch (name) {
        case 'withCallback':
          if (arguments.length != 1 || arguments[0] is! InterpretedFunction) {
            throw RuntimeError(
                'StringConversionSink.withCallback requires one Function argument.');
          }
          final callback = arguments[0] as InterpretedFunction;
          return StringConversionSink.withCallback((accumulated) {
            callback.call(visitor, [accumulated]);
          });
        default:
          throw RuntimeError(
              'StringConversionSink has no method mapping for "$name"');
      }
    }
  }
}
