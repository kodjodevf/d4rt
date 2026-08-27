import 'dart:collection';
import 'package:d4rt/d4rt.dart';

class SplayTreeSetCollection {
  static BridgedClass get definition => BridgedClass(
        nativeType: SplayTreeSet,
        name: 'SplayTreeSet',
        typeParameterCount: 1,
        isSubtypeOfFunc: (value) => value is SplayTreeSet,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            InterpretedFunction? compareFn;
            if (positionalArgs.isNotEmpty && positionalArgs[0] != null) {
              if (positionalArgs[0] is InterpretedFunction) {
                compareFn = positionalArgs[0] as InterpretedFunction;
              } else {
                throw RuntimeError("The 'compare' argument must be a function.");
              }
            }

            int Function(dynamic, dynamic)? actualCompare;
            if (compareFn != null) {
              actualCompare = (k1, k2) {
                final result = compareFn!.call(visitor, [k1, k2]);
                if (result is int) return result;
                throw RuntimeError("Compare function must return an int.");
              };
            }
            return SplayTreeSet<dynamic>(actualCompare);
          },
          'from': (visitor, positionalArgs, namedArgs) {
            final elements = positionalArgs[0] as Iterable;
            InterpretedFunction? compareFn;
            if (positionalArgs.length > 1 && positionalArgs[1] != null) {
              compareFn = positionalArgs[1] as InterpretedFunction;
            }
            int Function(dynamic, dynamic)? actualCompare;
            if (compareFn != null) {
              actualCompare = (k1, k2) => compareFn!.call(visitor, [k1, k2]) as int;
            }
            return SplayTreeSet<dynamic>.from(elements, actualCompare);
          },
          'of': (visitor, positionalArgs, namedArgs) {
            final elements = positionalArgs[0] as Iterable;
            InterpretedFunction? compareFn;
            if (positionalArgs.length > 1 && positionalArgs[1] != null) {
              compareFn = positionalArgs[1] as InterpretedFunction;
            }
            int Function(dynamic, dynamic)? actualCompare;
            if (compareFn != null) {
              actualCompare = (k1, k2) => compareFn!.call(visitor, [k1, k2]) as int;
            }
            return SplayTreeSet<dynamic>.of(elements, actualCompare);
          },
        },
        methods: {
          'add': (visitor, target, positionalArgs, namedArgs) {
            return (target as SplayTreeSet).add(positionalArgs[0]);
          },
          'addAll': (visitor, target, positionalArgs, namedArgs) {
            (target as SplayTreeSet).addAll(positionalArgs[0] as Iterable);
            return null;
          },
          'clear': (visitor, target, positionalArgs, namedArgs) {
            (target as SplayTreeSet).clear();
            return null;
          },
          'contains': (visitor, target, positionalArgs, namedArgs) {
            return (target as SplayTreeSet).contains(positionalArgs[0]);
          },
          'remove': (visitor, target, positionalArgs, namedArgs) {
            return (target as SplayTreeSet).remove(positionalArgs[0]);
          },
          'removeAll': (visitor, target, positionalArgs, namedArgs) {
            (target as SplayTreeSet).removeAll(positionalArgs[0] as Iterable);
            return null;
          },
          'retainAll': (visitor, target, positionalArgs, namedArgs) {
            (target as SplayTreeSet).retainAll(positionalArgs[0] as Iterable);
            return null;
          },
          'lookup': (visitor, target, positionalArgs, namedArgs) {
            return (target as SplayTreeSet).lookup(positionalArgs[0]);
          },
          'union': (visitor, target, positionalArgs, namedArgs) {
            return (target as SplayTreeSet).union((positionalArgs[0] as Set).cast());
          },
          'intersection': (visitor, target, positionalArgs, namedArgs) {
            return (target as SplayTreeSet).intersection(positionalArgs[0] as Set);
          },
          'difference': (visitor, target, positionalArgs, namedArgs) {
            return (target as SplayTreeSet).difference(positionalArgs[0] as Set);
          },
          'toList': (visitor, target, positionalArgs, namedArgs) {
            final growable = namedArgs['growable'] as bool? ?? true;
            return (target as SplayTreeSet).toList(growable: growable);
          },
          'toSet': (visitor, target, positionalArgs, namedArgs) {
            return (target as SplayTreeSet).toSet();
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as SplayTreeSet).toString();
          },
        },
        getters: {
          'length': (visitor, target) => (target as SplayTreeSet).length,
          'isEmpty': (visitor, target) => (target as SplayTreeSet).isEmpty,
          'isNotEmpty': (visitor, target) => (target as SplayTreeSet).isNotEmpty,
          'first': (visitor, target) => (target as SplayTreeSet).first,
          'last': (visitor, target) => (target as SplayTreeSet).last,
          'iterator': (visitor, target) => (target as SplayTreeSet).iterator,
          'hashCode': (visitor, target) => (target as SplayTreeSet).hashCode,
          'runtimeType': (visitor, target) => (target as SplayTreeSet).runtimeType,
        },
      );
}
