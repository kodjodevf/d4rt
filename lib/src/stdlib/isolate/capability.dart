import 'dart:isolate';
import 'package:d4rt/d4rt.dart';

class CapabilityIsolate {
  static BridgedClass get definition => BridgedClass(
        nativeType: Capability,
        name: 'Capability',
        typeParameterCount: 0,
        isSubtypeOfFunc: (value) => value is Capability,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            return Capability();
          },
        },
        getters: {
          'hashCode': (visitor, target) => (target as Capability).hashCode,
          'runtimeType': (visitor, target) =>
              (target as Capability).runtimeType,
        },
      );
}
