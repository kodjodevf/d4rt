import 'dart:collection';
import 'package:d4rt/d4rt.dart';

class MapViewCollection {
  static BridgedClass get definition => BridgedClass(
        nativeType: MapView,
        name: 'MapView',
        typeParameterCount: 2,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            final target = positionalArgs[0] as Map;
            return MapView(target);
          },
        },
        methods: {
          '[]': (visitor, target, positionalArgs, namedArgs) {
            return (target as MapView)[positionalArgs[0]];
          },
          '[]=': (visitor, target, positionalArgs, namedArgs) {
            (target as MapView)[positionalArgs[0]] = positionalArgs[1];
            return null;
          },
          'addAll': (visitor, target, positionalArgs, namedArgs) {
            (target as MapView).addAll(positionalArgs[0] as Map);
            return null;
          },
          'addEntries': (visitor, target, positionalArgs, namedArgs) {
            final entries = positionalArgs[0] as Iterable;
            final nativeEntries = entries.map((entry) {
              if (entry is BridgedInstance) {
                return entry.nativeObject as MapEntry;
              } else if (entry is MapEntry) {
                return entry;
              }
              throw RuntimeError('Invalid MapEntry type: ${entry.runtimeType}');
            });
            (target as MapView).addEntries(nativeEntries);
            return null;
          },
          'clear': (visitor, target, positionalArgs, namedArgs) {
            (target as MapView).clear();
            return null;
          },
          'containsKey': (visitor, target, positionalArgs, namedArgs) {
            return (target as MapView).containsKey(positionalArgs[0]);
          },
          'containsValue': (visitor, target, positionalArgs, namedArgs) {
            return (target as MapView).containsValue(positionalArgs[0]);
          },
          'forEach': (visitor, target, positionalArgs, namedArgs) {
            final action = positionalArgs[0] as InterpretedFunction;
            (target as MapView).forEach((key, value) {
              action.call(visitor, [key, value]);
            });
            return null;
          },
          'putIfAbsent': (visitor, target, positionalArgs, namedArgs) {
            final ifAbsent = positionalArgs[1] as InterpretedFunction;
            return (target as MapView).putIfAbsent(positionalArgs[0], () {
              return ifAbsent.call(visitor, []);
            });
          },
          'remove': (visitor, target, positionalArgs, namedArgs) {
            return (target as MapView).remove(positionalArgs[0]);
          },
          'removeWhere': (visitor, target, positionalArgs, namedArgs) {
            final predicate = positionalArgs[0] as InterpretedFunction;
            (target as MapView).removeWhere((key, value) {
              return predicate.call(visitor, [key, value]) as bool;
            });
            return null;
          },
          'update': (visitor, target, positionalArgs, namedArgs) {
            final update = positionalArgs[1] as InterpretedFunction;
            final ifAbsent = namedArgs['ifAbsent'] as InterpretedFunction?;
            return (target as MapView).update(
              positionalArgs[0],
              (value) => update.call(visitor, [value]),
              ifAbsent: ifAbsent != null ? () => ifAbsent.call(visitor, []) : null,
            );
          },
          'updateAll': (visitor, target, positionalArgs, namedArgs) {
            final update = positionalArgs[0] as InterpretedFunction;
            (target as MapView).updateAll((key, value) {
              return update.call(visitor, [key, value]);
            });
            return null;
          },
          'cast': (visitor, target, positionalArgs, namedArgs) {
            return (target as MapView).cast();
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as MapView).toString();
          },
        },
        getters: {
          'entries': (visitor, target) => (target as MapView).entries,
          'isEmpty': (visitor, target) => (target as MapView).isEmpty,
          'isNotEmpty': (visitor, target) => (target as MapView).isNotEmpty,
          'keys': (visitor, target) => (target as MapView).keys,
          'length': (visitor, target) => (target as MapView).length,
          'values': (visitor, target) => (target as MapView).values,
          'hashCode': (visitor, target) => (target as MapView).hashCode,
          'runtimeType': (visitor, target) => (target as MapView).runtimeType,
        },
      );
}
