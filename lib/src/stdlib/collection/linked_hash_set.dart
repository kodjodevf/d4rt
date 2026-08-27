import 'dart:collection';
import 'package:d4rt/d4rt.dart';

Iterable<dynamic> _unwrapIterable(Object? obj) {
  if (obj is BridgedInstance) {
    return (obj.nativeObject as Iterable).cast<dynamic>();
  }
  if (obj is Iterable) {
    return obj.cast<dynamic>();
  }
  throw RuntimeError('Expected an Iterable, got ${obj?.runtimeType}');
}

Set<dynamic> _unwrapSet(Object? obj) {
  if (obj is BridgedInstance) {
    return (obj.nativeObject as Set).cast<dynamic>();
  }
  if (obj is Set) {
    return obj.cast<dynamic>();
  }
  throw RuntimeError('Expected a Set, got ${obj?.runtimeType}');
}

class LinkedHashSetCollection {
  static BridgedClass get definition => BridgedClass(
        nativeType: LinkedHashSet,
        name: 'LinkedHashSet',
        typeParameterCount: 1,
        isSubtypeOfFunc: (value) => value is LinkedHashSet,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            // ignore: prefer_collection_literals
            return LinkedHashSet<dynamic>();
          },
          'from': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1) {
              throw RuntimeError(
                  'Constructor LinkedHashSet.from(Iterable elements) expects one positional argument.');
            }
            final elements = _unwrapIterable(positionalArgs[0]);
            return LinkedHashSet<dynamic>.from(elements);
          },
          'of': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1) {
              throw RuntimeError(
                  'Constructor LinkedHashSet.of(Iterable elements) expects one positional argument.');
            }
            final elements = _unwrapIterable(positionalArgs[0]);
            return LinkedHashSet<dynamic>.of(elements);
          },
          'identity': (visitor, positionalArgs, namedArgs) {
            return LinkedHashSet<dynamic>.identity();
          },
        },
        methods: {
          'add': (visitor, target, positionalArgs, namedArgs) {
            return (target as Set).add(positionalArgs[0]);
          },
          'addAll': (visitor, target, positionalArgs, namedArgs) {
            final elements = _unwrapIterable(positionalArgs[0]);
            (target as Set).addAll(elements);
            return null;
          },
          'clear': (visitor, target, positionalArgs, namedArgs) {
            (target as Set).clear();
            return null;
          },
          'contains': (visitor, target, positionalArgs, namedArgs) {
            return (target as Set).contains(positionalArgs[0]);
          },
          'containsAll': (visitor, target, positionalArgs, namedArgs) {
            final elements = _unwrapIterable(positionalArgs[0]);
            return (target as Set).containsAll(elements);
          },
          'difference': (visitor, target, positionalArgs, namedArgs) {
            final other = _unwrapSet(positionalArgs[0]);
            return (target as Set).difference(other);
          },
          'intersection': (visitor, target, positionalArgs, namedArgs) {
            final other = _unwrapSet(positionalArgs[0]);
            return (target as Set).intersection(other);
          },
          'union': (visitor, target, positionalArgs, namedArgs) {
            final other = _unwrapSet(positionalArgs[0]);
            return (target as Set).union(other);
          },
          'lookup': (visitor, target, positionalArgs, namedArgs) {
            return (target as Set).lookup(positionalArgs[0]);
          },
          'remove': (visitor, target, positionalArgs, namedArgs) {
            return (target as Set).remove(positionalArgs[0]);
          },
          'removeAll': (visitor, target, positionalArgs, namedArgs) {
            final elements = _unwrapIterable(positionalArgs[0]);
            (target as Set).removeAll(elements);
            return null;
          },
          'removeWhere': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            (target as Set).removeWhere((element) {
              return test.call(visitor, [element]) as bool;
            });
            return null;
          },
          'retainAll': (visitor, target, positionalArgs, namedArgs) {
            final elements = _unwrapIterable(positionalArgs[0]);
            (target as Set).retainAll(elements);
            return null;
          },
          'retainWhere': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            (target as Set).retainWhere((element) {
              return test.call(visitor, [element]) as bool;
            });
            return null;
          },
          'toSet': (visitor, target, positionalArgs, namedArgs) {
            return (target as Set).toSet();
          },
          'toList': (visitor, target, positionalArgs, namedArgs) {
            final growable = namedArgs['growable'] as bool? ?? true;
            return (target as Set).toList(growable: growable);
          },
          'forEach': (visitor, target, positionalArgs, namedArgs) {
            final action = positionalArgs[0] as InterpretedFunction;
            for (final element in (target as Set)) {
              action.call(visitor, [element]);
            }
            return null;
          },
          'any': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            return (target as Set)
                .any((element) => test.call(visitor, [element]) as bool);
          },
          'every': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            return (target as Set)
                .every((element) => test.call(visitor, [element]) as bool);
          },
          'join': (visitor, target, positionalArgs, namedArgs) {
            final separator =
                positionalArgs.isNotEmpty ? positionalArgs[0] as String : '';
            return (target as Set).join(separator);
          },
          'cast': (visitor, target, positionalArgs, namedArgs) {
            return (target as Set).cast();
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as Set).toString();
          },
        },
        getters: {
          'length': (visitor, target) => (target as Set).length,
          'isEmpty': (visitor, target) => (target as Set).isEmpty,
          'isNotEmpty': (visitor, target) => (target as Set).isNotEmpty,
          'first': (visitor, target) => (target as Set).first,
          'last': (visitor, target) => (target as Set).last,
          'single': (visitor, target) => (target as Set).single,
          'iterator': (visitor, target) => (target as Set).iterator,
          'hashCode': (visitor, target) => (target as Set).hashCode,
          'runtimeType': (visitor, target) => (target as Set).runtimeType,
        },
      );
}
