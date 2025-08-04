import 'dart:math';
import 'package:d4rt/d4rt.dart';

class RandomMath {
  static BridgedClass get definition => BridgedClass(
        nativeType: Random,
        name: 'Random',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            final seed =
                positionalArgs.isNotEmpty ? positionalArgs[0] as int? : null;
            return seed != null ? Random(seed) : Random();
          },
          'secure': (visitor, positionalArgs, namedArgs) {
            return Random.secure();
          },
        },
        methods: {
          'nextInt': (visitor, target, positionalArgs, namedArgs) {
            return (target as Random).nextInt(positionalArgs[0] as int);
          },
          'nextDouble': (visitor, target, positionalArgs, namedArgs) {
            return (target as Random).nextDouble();
          },
          'nextBool': (visitor, target, positionalArgs, namedArgs) {
            return (target as Random).nextBool();
          },
        },
        getters: {
          'hashCode': (visitor, target) => (target as Random).hashCode,
          'runtimeType': (visitor, target) => (target as Random).runtimeType,
        },
      );
}
