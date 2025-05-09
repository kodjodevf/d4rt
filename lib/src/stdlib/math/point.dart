import 'dart:math';
import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';

class PointMath implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'Point',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          if (arguments.length != 2 ||
              arguments[0] is! num ||
              arguments[1] is! num) {
            throw RuntimeError(
                'Point constructor requires 2 numeric arguments (x, y).');
          }
          return Point(arguments[0] as num, arguments[1] as num);
        }, arity: 2, name: 'Point'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is Point) {
      switch (name) {
        case 'x':
          return target.x;
        case 'y':
          return target.y;
        case 'magnitude':
          return target.magnitude;
        case 'distanceTo':
          return target.distanceTo(arguments[0] as Point);
        case 'squaredDistanceTo':
          return target.squaredDistanceTo(arguments[0] as Point);
        // Operators: +, -, *
        case '+':
          if (arguments.length != 1 || arguments[0] is! Point) {
            throw RuntimeError('Operator + requires one Point argument.');
          }
          return target + (arguments[0] as Point);
        case '-':
          if (arguments.length != 1 || arguments[0] is! Point) {
            throw RuntimeError('Operator - requires one Point argument.');
          }
          return target - (arguments[0] as Point);
        case '*':
          if (arguments.length != 1 || arguments[0] is! num) {
            throw RuntimeError(
                'Operator * requires one numeric argument (factor).');
          }
          return target * (arguments[0] as num);
        case 'hashCode':
          return target.hashCode;
        case 'toString':
          return target.toString();
        default:
          throw RuntimeError(
              'Point has no instance method/getter mapping for "$name"');
      }
    } else {
      // No static methods defined for Point in dart:math
      throw RuntimeError(
          'Invalid target for Point method call: ${target?.runtimeType}');
    }
  }
}
