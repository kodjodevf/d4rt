import 'dart:math';
import 'package:d4rt/d4rt.dart';

Point<num> _unwrapPoint(Object? obj) {
  if (obj is BridgedInstance) {
    return obj.nativeObject as Point<num>;
  }
  if (obj is Point<num>) {
    return obj;
  }
  throw RuntimeError('Expected a Point, got ${obj?.runtimeType}');
}

class PointMath {
  static BridgedClass get definition => BridgedClass(
        nativeType: Point,
        name: 'Point',
        typeParameterCount: 1, // Point<T extends num>
        isSubtypeOfFunc: (value) => value is Point,
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
            final other = _unwrapPoint(positionalArgs[0]);
            return (target as Point).distanceTo(other);
          },
          'squaredDistanceTo': (visitor, target, positionalArgs, namedArgs) {
            final other = _unwrapPoint(positionalArgs[0]);
            return (target as Point).squaredDistanceTo(other);
          },
          '+': (visitor, target, positionalArgs, namedArgs) {
            final other = _unwrapPoint(positionalArgs[0]);
            return (target as Point) + other;
          },
          '-': (visitor, target, positionalArgs, namedArgs) {
            final other = _unwrapPoint(positionalArgs[0]);
            return (target as Point) - other;
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
