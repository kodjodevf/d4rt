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

Rectangle<num> _unwrapRectangle(Object? obj) {
  if (obj is BridgedInstance) {
    return obj.nativeObject as Rectangle<num>;
  }
  if (obj is Rectangle<num>) {
    return obj;
  }
  throw RuntimeError('Expected a Rectangle, got ${obj?.runtimeType}');
}

class RectangleMath {
  static BridgedClass get definition => BridgedClass(
        nativeType: Rectangle,
        name: 'Rectangle',
        typeParameterCount: 1, // Rectangle<T extends num>
        isSubtypeOfFunc: (value) => value is Rectangle,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 4 ||
                positionalArgs[0] is! num ||
                positionalArgs[1] is! num ||
                positionalArgs[2] is! num ||
                positionalArgs[3] is! num) {
              throw RuntimeError(
                  'Rectangle constructor requires 4 numeric arguments (left, top, width, height).');
            }
            return Rectangle(
              positionalArgs[0] as num,
              positionalArgs[1] as num,
              positionalArgs[2] as num,
              positionalArgs[3] as num,
            );
          },
          'fromPoints': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 2) {
              throw RuntimeError(
                  'Rectangle.fromPoints requires 2 Point arguments.');
            }
            final a = _unwrapPoint(positionalArgs[0]);
            final b = _unwrapPoint(positionalArgs[1]);
            return Rectangle.fromPoints(a, b);
          },
        },
        methods: {
          'containsPoint': (visitor, target, positionalArgs, namedArgs) {
            final other = _unwrapPoint(positionalArgs[0]);
            return (target as Rectangle).containsPoint(other);
          },
          'containsRectangle': (visitor, target, positionalArgs, namedArgs) {
            final other = _unwrapRectangle(positionalArgs[0]);
            return (target as Rectangle).containsRectangle(other);
          },
          'intersects': (visitor, target, positionalArgs, namedArgs) {
            final other = _unwrapRectangle(positionalArgs[0]);
            return (target as Rectangle).intersects(other);
          },
          'intersection': (visitor, target, positionalArgs, namedArgs) {
            final other = _unwrapRectangle(positionalArgs[0]);
            return (target as Rectangle).intersection(other);
          },
          'boundingBox': (visitor, target, positionalArgs, namedArgs) {
            final other = _unwrapRectangle(positionalArgs[0]);
            return (target as Rectangle).boundingBox(other);
          },
        },
        getters: {
          'left': (visitor, target) => (target as Rectangle).left,
          'top': (visitor, target) => (target as Rectangle).top,
          'width': (visitor, target) => (target as Rectangle).width,
          'height': (visitor, target) => (target as Rectangle).height,
          'right': (visitor, target) => (target as Rectangle).right,
          'bottom': (visitor, target) => (target as Rectangle).bottom,
          'topLeft': (visitor, target) => (target as Rectangle).topLeft,
          'topRight': (visitor, target) => (target as Rectangle).topRight,
          'bottomLeft': (visitor, target) => (target as Rectangle).bottomLeft,
          'bottomRight': (visitor, target) => (target as Rectangle).bottomRight,
          'hashCode': (visitor, target) => (target as Rectangle).hashCode,
          'runtimeType': (visitor, target) => (target as Rectangle).runtimeType,
        },
      );
}
