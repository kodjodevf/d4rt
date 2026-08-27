// ignore_for_file: deprecated_member_use

import 'dart:collection';
import 'package:d4rt/d4rt.dart';

class HasNextIteratorCollection {
  static BridgedClass get definition => BridgedClass(
        nativeType: HasNextIterator,
        name: 'HasNextIterator',
        typeParameterCount: 1,
        isSubtypeOfFunc: (value) => value is HasNextIterator,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty || positionalArgs[0] is! Iterator) {
              throw RuntimeError(
                  'HasNextIterator constructor requires an Iterator argument.');
            }
            final iterator = positionalArgs[0] as Iterator;
            return HasNextIterator<dynamic>(iterator);
          },
        },
        methods: {
          'next': (visitor, target, positionalArgs, namedArgs) {
            if (target is HasNextIterator) {
              return target.next();
            }
            throw RuntimeError('Target is not a HasNextIterator for next().');
          },
        },
        getters: {
          'hasNext': (visitor, target) {
            if (target is HasNextIterator) {
              return target.hasNext;
            }
            throw RuntimeError('Target is not a HasNextIterator for hasNext.');
          },
          'hashCode': (visitor, target) =>
              (target as HasNextIterator).hashCode,
          'runtimeType': (visitor, target) =>
              (target as HasNextIterator).runtimeType,
        },
      );
}
