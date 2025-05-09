import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';
import 'package:d4rt/src/utils/extensions/list.dart';

class ExceptionCore implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'Exception',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          return arguments.isEmpty
              ? Exception
              : Exception(arguments[0] as String);
        },
            arity: 0, // Arity is 0 positional, but named args are used
            name: 'Exception'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    throw RuntimeError('Exception has no instance method mapping for "$name"');
  }
}

class FormatExceptionCore implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'FormatException',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          return arguments.isEmpty
              ? FormatException
              : FormatException(arguments.get<String?>(0) ?? '',
                  arguments.get<dynamic>(1), arguments.get<int>(2));
        },
            arity: 0, // Arity is 0 positional, but named args are used
            name: 'FormatException'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is FormatException) {
      switch (name) {
        case 'message':
          return target.message;
        case 'offset':
          return target.offset;
        case 'source':
          return target.source;
        default:
          throw RuntimeError(
              'FormatException has no instance method mapping for "$name"');
      }
    }
    throw RuntimeError('Exception has no instance method mapping for "$name"');
  }
}
