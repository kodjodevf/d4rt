import 'package:d4rt/d4rt.dart';

class StopwatchCore {
  static BridgedClass get definition => BridgedClass(
        nativeType: Stopwatch,
        name: 'Stopwatch',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            return Stopwatch();
          },
          'createStarted': (visitor, positionalArgs, namedArgs) {
            return Stopwatch()..start();
          },
        },
        staticMethods: {
          'createStarted': (visitor, positionalArgs, namedArgs) {
            return Stopwatch()..start();
          },
        },
        methods: {
          'start': (visitor, target, positionalArgs, namedArgs) {
            (target as Stopwatch).start();
            return null;
          },
          'stop': (visitor, target, positionalArgs, namedArgs) {
            (target as Stopwatch).stop();
            return null;
          },
          'reset': (visitor, target, positionalArgs, namedArgs) {
            (target as Stopwatch).reset();
            return null;
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as Stopwatch).toString();
          },
        },
        getters: {
          'elapsed': (visitor, target) => (target as Stopwatch).elapsed,
          'elapsedMilliseconds': (visitor, target) =>
              (target as Stopwatch).elapsedMilliseconds,
          'elapsedMicroseconds': (visitor, target) =>
              (target as Stopwatch).elapsedMicroseconds,
          'elapsedTicks': (visitor, target) =>
              (target as Stopwatch).elapsedTicks,
          'frequency': (visitor, target) => (target as Stopwatch).frequency,
          'isRunning': (visitor, target) => (target as Stopwatch).isRunning,
          'hashCode': (visitor, target) => (target as Stopwatch).hashCode,
          'runtimeType': (visitor, target) => (target as Stopwatch).runtimeType,
        },
      );
}
