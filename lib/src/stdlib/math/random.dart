import 'dart:math';
import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';
import 'package:d4rt/src/utils/extensions/list.dart';

class RandomMath implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'Random',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          final seed = arguments.get<int?>(0);
          return seed == null ? Random() : Random(seed);
        },
            arity: 1, // 0 or 1 argument
            name: 'Random'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is Random) {
      switch (name) {
        case 'nextInt':
          if (arguments.length != 1 || arguments[0] is! int) {
            throw RuntimeError(
                'Random.nextInt requires one int argument (max).');
          }
          return target.nextInt(arguments[0] as int);
        case 'nextDouble':
          if (arguments.isNotEmpty || namedArguments.isNotEmpty) {
            throw RuntimeError('Random.nextDouble takes no arguments.');
          }
          return target.nextDouble();
        case 'nextBool':
          if (arguments.isNotEmpty || namedArguments.isNotEmpty) {
            throw RuntimeError('Random.nextBool takes no arguments.');
          }
          return target.nextBool();
        case 'hashCode':
          return target.hashCode;
        case 'toString':
          return target.toString();
        default:
          throw RuntimeError(
              'Random has no instance method mapping for "$name"');
      }
    } else {
      switch (name) {
        case 'secure':
          if (arguments.isNotEmpty) {
            throw RuntimeError('Random.secure constructor takes no arguments.');
          }
          return Random.secure();

        default:
          throw RuntimeError(
              'Random has no instance method mapping for "$name"');
      }
    }
  }
}
