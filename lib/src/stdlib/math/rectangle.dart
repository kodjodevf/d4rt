import 'dart:math';
import 'package:d4rt/d4rt.dart';

class RectangleMath {
  static BridgedClass get definition => BridgedClass(
        nativeType: Rectangle,
        name: 'Rectangle',
        typeParameterCount: 1, // Rectangle<T extends num>
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
        },
        methods: {
          'containsPoint': (visitor, target, positionalArgs, namedArgs) {
            return (target as Rectangle)
                .containsPoint(positionalArgs[0] as Point);
          },
          'containsRectangle': (visitor, target, positionalArgs, namedArgs) {
            return (target as Rectangle)
                .containsRectangle(positionalArgs[0] as Rectangle);
          },
          'intersects': (visitor, target, positionalArgs, namedArgs) {
            return (target as Rectangle)
                .intersects(positionalArgs[0] as Rectangle);
          },
          'intersection': (visitor, target, positionalArgs, namedArgs) {
            return (target as Rectangle)
                .intersection(positionalArgs[0] as Rectangle);
          },
          'boundingBox': (visitor, target, positionalArgs, namedArgs) {
            return (target as Rectangle)
                .boundingBox(positionalArgs[0] as Rectangle);
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
