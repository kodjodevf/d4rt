import 'dart:math';
import 'package:d4rt/d4rt.dart';

class MutableRectangleMath {
  static BridgedClass get definition => BridgedClass(
        nativeType: MutableRectangle,
        name: 'MutableRectangle',
        typeParameterCount: 1, // MutableRectangle<T extends num>
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 4 ||
                positionalArgs[0] is! num ||
                positionalArgs[1] is! num ||
                positionalArgs[2] is! num ||
                positionalArgs[3] is! num) {
              throw RuntimeError(
                  'MutableRectangle constructor requires 4 numeric arguments (left, top, width, height).');
            }
            return MutableRectangle<num>(
              positionalArgs[0] as num,
              positionalArgs[1] as num,
              positionalArgs[2] as num,
              positionalArgs[3] as num,
            );
          },
          'fromPoints': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 2 ||
                positionalArgs[0] is! Point ||
                positionalArgs[1] is! Point) {
              throw RuntimeError(
                  'MutableRectangle.fromPoints requires 2 Point arguments.');
            }
            return MutableRectangle<num>.fromPoints(
              positionalArgs[0] as Point<num>,
              positionalArgs[1] as Point<num>,
            );
          },
        },
        methods: {
          'containsPoint': (visitor, target, positionalArgs, namedArgs) {
            return (target as MutableRectangle)
                .containsPoint(positionalArgs[0] as Point);
          },
          'containsRectangle': (visitor, target, positionalArgs, namedArgs) {
            return (target as MutableRectangle)
                .containsRectangle(positionalArgs[0] as Rectangle);
          },
          'intersects': (visitor, target, positionalArgs, namedArgs) {
            return (target as MutableRectangle)
                .intersects(positionalArgs[0] as Rectangle);
          },
          'intersection': (visitor, target, positionalArgs, namedArgs) {
            return (target as MutableRectangle)
                .intersection(positionalArgs[0] as Rectangle);
          },
          'boundingBox': (visitor, target, positionalArgs, namedArgs) {
            return (target as MutableRectangle)
                .boundingBox(positionalArgs[0] as Rectangle);
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as MutableRectangle).toString();
          },
        },
        getters: {
          'left': (visitor, target) => (target as MutableRectangle).left,
          'top': (visitor, target) => (target as MutableRectangle).top,
          'width': (visitor, target) => (target as MutableRectangle).width,
          'height': (visitor, target) => (target as MutableRectangle).height,
          'right': (visitor, target) => (target as MutableRectangle).right,
          'bottom': (visitor, target) => (target as MutableRectangle).bottom,
          'topLeft': (visitor, target) => (target as MutableRectangle).topLeft,
          'topRight': (visitor, target) =>
              (target as MutableRectangle).topRight,
          'bottomLeft': (visitor, target) =>
              (target as MutableRectangle).bottomLeft,
          'bottomRight': (visitor, target) =>
              (target as MutableRectangle).bottomRight,
          'hashCode': (visitor, target) =>
              (target as MutableRectangle).hashCode,
          'runtimeType': (visitor, target) =>
              (target as MutableRectangle).runtimeType,
        },
        setters: {
          'left': (visitor, target, value) {
            (target as MutableRectangle).left = value as num;
          },
          'top': (visitor, target, value) {
            (target as MutableRectangle).top = value as num;
          },
          'width': (visitor, target, value) {
            (target as MutableRectangle).width = value as num;
          },
          'height': (visitor, target, value) {
            (target as MutableRectangle).height = value as num;
          },
        },
      );
}
