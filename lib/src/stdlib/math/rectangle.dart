import 'dart:math';
import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';

class RectangleMath implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'Rectangle',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          if (arguments.length != 4 ||
              arguments[0] is! num ||
              arguments[1] is! num ||
              arguments[2] is! num ||
              arguments[3] is! num) {
            throw RuntimeError(
                'Rectangle constructor requires 4 numeric arguments (left, top, width, height).');
          }
          // Consider adding factory constructors like fromPoints if needed
          return Rectangle(
            arguments[0] as num,
            arguments[1] as num,
            arguments[2] as num,
            arguments[3] as num,
          );
        }, arity: 4, name: 'Rectangle'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is Rectangle) {
      switch (name) {
        case 'left':
          return target.left;
        case 'top':
          return target.top;
        case 'width':
          return target.width;
        case 'height':
          return target.height;
        case 'right':
          return target.right;
        case 'bottom':
          return target.bottom;
        case 'topLeft':
          return target.topLeft;
        case 'topRight':
          return target.topRight;
        case 'bottomLeft':
          return target.bottomLeft;
        case 'bottomRight':
          return target.bottomRight;
        case 'containsPoint':
          return target.containsPoint(arguments[0] as Point);
        case 'containsRectangle':
          return target.containsRectangle(arguments[0] as Rectangle);
        case 'intersects':
          return target.intersects(arguments[0] as Rectangle);
        case 'intersection':
          return target.intersection(arguments[0] as Rectangle);
        case 'boundingBox':
          return target.boundingBox(arguments[0] as Rectangle);
        case 'hashCode':
          return target.hashCode;
        case 'toString':
          return target.toString();
        default:
          throw RuntimeError(
              'Rectangle has no instance method/getter mapping for "$name"');
      }
    } else {
      // No static methods defined for Rectangle in dart:math
      throw RuntimeError(
          'Invalid target for Rectangle method call: ${target?.runtimeType}');
    }
  }
}
