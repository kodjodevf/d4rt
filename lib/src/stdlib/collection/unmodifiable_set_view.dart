import 'dart:collection';
import 'package:d4rt/d4rt.dart';

class UnmodifiableSetViewCollection {
  static BridgedClass get definition => BridgedClass(
        nativeType: UnmodifiableSetView,
        name: 'UnmodifiableSetView',
        typeParameterCount: 1,
        isSubtypeOfFunc: (value) => value is UnmodifiableSetView,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            final set = positionalArgs[0] as Set;
            return UnmodifiableSetView<dynamic>(set.cast<dynamic>());
          },
        },
        methods: {
          'contains': (visitor, target, positionalArgs, namedArgs) {
            return (target as UnmodifiableSetView).contains(positionalArgs[0]);
          },
          'lookup': (visitor, target, positionalArgs, namedArgs) {
            return (target as UnmodifiableSetView).lookup(positionalArgs[0]);
          },
          'toSet': (visitor, target, positionalArgs, namedArgs) {
            return (target as UnmodifiableSetView).toSet();
          },
          'toList': (visitor, target, positionalArgs, namedArgs) {
            final growable = namedArgs['growable'] as bool? ?? true;
            return (target as UnmodifiableSetView).toList(growable: growable);
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as UnmodifiableSetView).toString();
          },
        },
        getters: {
          'length': (visitor, target) => (target as UnmodifiableSetView).length,
          'isEmpty': (visitor, target) => (target as UnmodifiableSetView).isEmpty,
          'isNotEmpty': (visitor, target) =>
              (target as UnmodifiableSetView).isNotEmpty,
          'first': (visitor, target) => (target as UnmodifiableSetView).first,
          'last': (visitor, target) => (target as UnmodifiableSetView).last,
          'iterator': (visitor, target) =>
              (target as UnmodifiableSetView).iterator,
          'hashCode': (visitor, target) =>
              (target as UnmodifiableSetView).hashCode,
          'runtimeType': (visitor, target) =>
              (target as UnmodifiableSetView).runtimeType,
        },
      );
}
