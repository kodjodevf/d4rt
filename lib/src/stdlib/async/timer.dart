import 'dart:async';
import 'package:d4rt/d4rt.dart';

class TimerAsync {
  static BridgedClass get definition => BridgedClass(
        nativeType: Timer,
        name: 'Timer',
        nativeNames: ['TimerImpl'],
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 2 || namedArgs.isNotEmpty) {
              throw RuntimeError('Timer constructor takes 2 arguments.');
            }
            final duration = positionalArgs[0] as Duration;
            final callback = positionalArgs[1] as InterpretedFunction;
            return Timer(duration, () {
              callback.call(visitor, []);
            });
          },
        },
        staticMethods: {
          'periodic': (visitor, positionalArgs, namedArgs) {
            final duration = positionalArgs[0] as Duration;
            final callback = positionalArgs[1] as InterpretedFunction;
            return Timer.periodic(duration, (timer) {
              callback.call(visitor, [timer]);
            });
          },
          'run': (visitor, positionalArgs, namedArgs) {
            final callback = positionalArgs[1] as InterpretedFunction;
            return Timer.run(() {
              callback.call(visitor, []);
            });
          },
        },
        methods: {
          'cancel': (visitor, target, positionalArgs, namedArgs) {
            (target as Timer).cancel();
            return null;
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as Timer).toString();
          },
        },
        getters: {
          'isActive': (visitor, target) => (target as Timer).isActive,
          'tick': (visitor, target) => (target as Timer).tick,
          'hashCode': (visitor, target) => (target as Timer).hashCode,
          'runtimeType': (visitor, target) => (target as Timer).runtimeType,
        },
      );
}

class TimerStdlib {
  static void register(Environment environment) {
    environment.defineBridge(TimerAsync.definition);
  }
}
