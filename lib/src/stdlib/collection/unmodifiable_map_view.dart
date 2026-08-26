import 'dart:collection';
import 'package:d4rt/d4rt.dart';

class UnmodifiableMapViewCollection {
  static BridgedClass get definition => BridgedClass(
        nativeType: UnmodifiableMapView,
        name: 'UnmodifiableMapView',
        typeParameterCount: 2,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            final map = positionalArgs[0] as Map;
            return UnmodifiableMapView<dynamic, dynamic>(
                map.cast<dynamic, dynamic>());
          },
        },
        methods: {
          '[]': (visitor, target, positionalArgs, namedArgs) {
            return (target as UnmodifiableMapView)[positionalArgs[0]];
          },
          'containsKey': (visitor, target, positionalArgs, namedArgs) {
            return (target as UnmodifiableMapView)
                .containsKey(positionalArgs[0]);
          },
          'containsValue': (visitor, target, positionalArgs, namedArgs) {
            return (target as UnmodifiableMapView)
                .containsValue(positionalArgs[0]);
          },
          'forEach': (visitor, target, positionalArgs, namedArgs) {
            final action = positionalArgs[0] as InterpretedFunction;
            for (final entry in (target as UnmodifiableMapView).entries) {
              action.call(visitor, [entry.key, entry.value]);
            }
            return null;
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as UnmodifiableMapView).toString();
          },
        },
        getters: {
          'length': (visitor, target) => (target as UnmodifiableMapView).length,
          'isEmpty': (visitor, target) =>
              (target as UnmodifiableMapView).isEmpty,
          'isNotEmpty': (visitor, target) =>
              (target as UnmodifiableMapView).isNotEmpty,
          'keys': (visitor, target) => (target as UnmodifiableMapView).keys,
          'values': (visitor, target) => (target as UnmodifiableMapView).values,
          'entries': (visitor, target) =>
              (target as UnmodifiableMapView).entries,
          'hashCode': (visitor, target) =>
              (target as UnmodifiableMapView).hashCode,
          'runtimeType': (visitor, target) =>
              (target as UnmodifiableMapView).runtimeType,
        },
      );
}
