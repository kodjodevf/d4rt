import 'dart:async';
import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';
import 'package:d4rt/src/utils/extensions/list.dart';

class CompleterAsync implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'Completer',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          // Default constructor takes no arguments
          if (arguments.isNotEmpty || namedArguments.isNotEmpty) {
            throw RuntimeError('Completer constructor takes no arguments.');
          }
          return Completer<dynamic>();
        }, arity: 0, name: 'Completer'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is Completer) {
      switch (name) {
        case 'complete':
          target.complete(arguments.get<dynamic>(0));
          return null;
        case 'completeError':
          final error = arguments[0];
          if (error == null) {
            // Add null check for error
            throw RuntimeError(
                'Completer.completeError requires a non-null error object.');
          }
          target.completeError(error, arguments.get<StackTrace?>(1));
          return null;
        case 'future':
          return target.future;
        case 'isCompleted':
          return target.isCompleted;
        default:
          throw RuntimeError(
              'Completer has no instance method/getter mapping for "$name"');
      }
    } else {
      switch (name) {
        case 'sync':
          return Completer<dynamic>.sync();
        default:
          throw RuntimeError(
              'Completer has no instance static method mapping for "$name"');
      }
    }
  }
}
