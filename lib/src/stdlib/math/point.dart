import 'dart:math';
import 'package:d4rt/d4rt.dart';

class PointMath {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        nativeType: Point,
        name: 'Point',
        typeParameterCount: 1, // Point<T extends num>
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 2 ||
                positionalArgs[0] is! num ||
                positionalArgs[1] is! num) {
              throw RuntimeError(
                  'Point constructor requires 2 numeric arguments (x, y).');
            }
            return Point(positionalArgs[0] as num, positionalArgs[1] as num);
          },
        },
        methods: {
          'distanceTo': (visitor, target, positionalArgs, namedArgs) {
            return (target as Point).distanceTo(positionalArgs[0] as Point);
          },
          'squaredDistanceTo': (visitor, target, positionalArgs, namedArgs) {
            return (target as Point)
                .squaredDistanceTo(positionalArgs[0] as Point);
          },
          '+': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! Point) {
              throw RuntimeError('Operator + requires one Point argument.');
            }
            return (target as Point) + (positionalArgs[0] as Point);
          },
          '-': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! Point) {
              throw RuntimeError('Operator - requires one Point argument.');
            }
            return (target as Point) - (positionalArgs[0] as Point);
          },
          '*': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! num) {
              throw RuntimeError(
                  'Operator * requires one numeric argument (factor).');
            }
            return (target as Point) * (positionalArgs[0] as num);
          },
        },
        getters: {
          'x': (visitor, target) => (target as Point).x,
          'y': (visitor, target) => (target as Point).y,
          'magnitude': (visitor, target) => (target as Point).magnitude,
          'hashCode': (visitor, target) => (target as Point).hashCode,
          'runtimeType': (visitor, target) => (target as Point).runtimeType,
        },
      );
}
