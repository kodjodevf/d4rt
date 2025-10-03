import 'package:d4rt/d4rt.dart';

class MapCore {
  static BridgedClass get definition => BridgedClass(
        nativeType: Map,
        name: 'Map',
        typeParameterCount: 2,
        nativeNames: [
          'UnmodifiableMapView',
          '_UnmodifiableMapView',
          '_CompactLinkedHashMap',
        ],
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            return <dynamic, dynamic>{};
          },
        },
        staticMethods: {
          'from': (visitor, positionalArgs, namedArgs) {
            return Map.from(positionalArgs[0] as Map);
          },
          'of': (visitor, positionalArgs, namedArgs) {
            return Map.of(positionalArgs[0] as Map);
          },
          'unmodifiable': (visitor, positionalArgs, namedArgs) {
            return Map.unmodifiable(positionalArgs[0] as Map);
          },
          'identity': (visitor, positionalArgs, namedArgs) {
            return Map.identity();
          },
          'fromIterable': (visitor, positionalArgs, namedArgs) {
            final iterable = positionalArgs[0] as Iterable;
            final key = namedArgs['key'] as InterpretedFunction?;
            final value = namedArgs['value'] as InterpretedFunction?;

            return Map.fromIterable(
              iterable,
              key: key == null
                  ? null
                  : (element) => key.call(visitor, [element]),
              value: value == null
                  ? null
                  : (element) => value.call(visitor, [element]),
            );
          },
          'fromIterables': (visitor, positionalArgs, namedArgs) {
            return Map.fromIterables(
              positionalArgs[0] as Iterable,
              positionalArgs[1] as Iterable,
            );
          },
          'fromEntries': (visitor, positionalArgs, namedArgs) {
            final entries = positionalArgs[0] as Iterable;
            // Unwrap BridgedInstance<MapEntry> to get native MapEntry objects
            final nativeEntries = entries.map((entry) {
              if (entry is BridgedInstance) {
                return entry.nativeObject as MapEntry;
              } else if (entry is MapEntry) {
                return entry;
              } else {
                throw RuntimeError(
                    'fromEntries expects Iterable<MapEntry>, got ${entry.runtimeType}');
              }
            });
            return Map.fromEntries(nativeEntries);
          },
        },
        methods: {
          '[]': (visitor, target, positionalArgs, namedArgs) {
            return (target as Map)[positionalArgs[0]];
          },
          '[]=': (visitor, target, positionalArgs, namedArgs) {
            (target as Map)[positionalArgs[0]] = positionalArgs[1];
            return null;
          },
          'addAll': (visitor, target, positionalArgs, namedArgs) {
            (target as Map).addAll(positionalArgs[0] as Map);
            return null;
          },
          'addEntries': (visitor, target, positionalArgs, namedArgs) {
            final entries = positionalArgs[0] as Iterable;
            // Unwrap BridgedInstance<MapEntry> to get native MapEntry objects
            final nativeEntries = entries.map((entry) {
              if (entry is BridgedInstance) {
                return entry.nativeObject as MapEntry;
              } else if (entry is MapEntry) {
                return entry;
              } else {
                throw RuntimeError(
                    'addEntries expects Iterable<MapEntry>, got ${entry.runtimeType}');
              }
            });
            (target as Map).addEntries(nativeEntries);
            return null;
          },
          'clear': (visitor, target, positionalArgs, namedArgs) {
            (target as Map).clear();
            return null;
          },
          'containsKey': (visitor, target, positionalArgs, namedArgs) {
            return (target as Map).containsKey(positionalArgs[0]);
          },
          'containsValue': (visitor, target, positionalArgs, namedArgs) {
            return (target as Map).containsValue(positionalArgs[0]);
          },
          'forEach': (visitor, target, positionalArgs, namedArgs) {
            final action = positionalArgs[0] as InterpretedFunction;
            (target as Map).forEach((key, value) {
              action.call(visitor, [key, value]);
            });
            return null;
          },
          'putIfAbsent': (visitor, target, positionalArgs, namedArgs) {
            final ifAbsent = positionalArgs[1] as InterpretedFunction;
            return (target as Map).putIfAbsent(
              positionalArgs[0],
              () => ifAbsent.call(visitor, []),
            );
          },
          'remove': (visitor, target, positionalArgs, namedArgs) {
            return (target as Map).remove(positionalArgs[0]);
          },
          'removeWhere': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            (target as Map).removeWhere((key, value) {
              return test.call(visitor, [key, value]) as bool;
            });
            return null;
          },
          'update': (visitor, target, positionalArgs, namedArgs) {
            final update = positionalArgs[1] as InterpretedFunction;
            final ifAbsent = namedArgs['ifAbsent'] as InterpretedFunction?;
            return (target as Map).update(
              positionalArgs[0],
              (value) => update.call(visitor, [value]),
              ifAbsent:
                  ifAbsent == null ? null : () => ifAbsent.call(visitor, []),
            );
          },
          'updateAll': (visitor, target, positionalArgs, namedArgs) {
            final update = positionalArgs[0] as InterpretedFunction;
            (target as Map).updateAll((key, value) {
              return update.call(visitor, [key, value]);
            });
            return null;
          },
          'map': (visitor, target, positionalArgs, namedArgs) {
            final convert = positionalArgs[0] as InterpretedFunction;
            return (target as Map).map((key, value) {
              final result = convert.call(visitor, [key, value]);
              // Accept both native MapEntry and BridgedInstance<MapEntry>
              if (result is MapEntry) {
                return result;
              } else if (result is BridgedInstance &&
                  result.nativeObject is MapEntry) {
                return result.nativeObject as MapEntry;
              } else {
                throw RuntimeError(
                    'Map.map callback must return a MapEntry, got ${result.runtimeType}');
              }
            });
          },
          'cast': (visitor, target, positionalArgs, namedArgs) {
            return (target as Map).cast();
          },
        },
        getters: {
          'length': (visitor, target) => (target as Map).length,
          'hashCode': (visitor, target) => (target as Map).hashCode,
          'isEmpty': (visitor, target) => (target as Map).isEmpty,
          'isNotEmpty': (visitor, target) => (target as Map).isNotEmpty,
          'keys': (visitor, target) => (target as Map).keys,
          'values': (visitor, target) => (target as Map).values,
          'entries': (visitor, target) => (target as Map).entries,
          'runtimeType': (visitor, target) => (target as Map).runtimeType,
        },
      );
}

class MapEntryCore {
  static BridgedClass get definition => BridgedClass(
        nativeType: MapEntry,
        name: 'MapEntry',
        typeParameterCount: 2,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 2) {
              throw RuntimeError(
                  'MapEntry constructor requires 2 arguments (key, value).');
            }
            return MapEntry(positionalArgs[0], positionalArgs[1]);
          },
        },
        methods: {
          'hashCode': (visitor, target, positionalArgs, namedArgs) =>
              (target as MapEntry).hashCode,
          'toString': (visitor, target, positionalArgs, namedArgs) =>
              (target as MapEntry).toString(),
        },
        getters: {
          'key': (visitor, target) => (target as MapEntry).key,
          'value': (visitor, target) => (target as MapEntry).value,
        },
      );
}
