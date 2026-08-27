import 'dart:async';
import 'package:d4rt/d4rt.dart';

class ZoneAsync {
  static Zone _unwrapZone(Object? obj) {
    if (obj is BridgedInstance) {
      return obj.nativeObject as Zone;
    }
    return obj as Zone;
  }

  static BridgedClass get definition => BridgedClass(
        nativeType: Zone,
        name: 'Zone',
        typeParameterCount: 0,
        nativeNames: ['_Zone', '_RootZone', '_CustomZone'],
        staticGetters: {
          'current': (visitor) => Zone.current,
          'root': (visitor) => Zone.root,
        },
        methods: {
          'run': (visitor, target, positionalArgs, namedArgs) {
            final zone = target as Zone;
            final fn = positionalArgs[0];
            if (fn is InterpretedFunction) {
              return zone.run(() => fn.call(visitor, []));
            } else if (fn is Function) {
              return zone.run(() => fn());
            }
            throw RuntimeError('Zone.run expects a callback function');
          },
          'runUnary': (visitor, target, positionalArgs, namedArgs) {
            final zone = target as Zone;
            final fn = positionalArgs[0];
            final arg = positionalArgs[1];
            if (fn is InterpretedFunction) {
              return zone.runUnary((a) => fn.call(visitor, [a]), arg);
            } else if (fn is Function) {
              return zone.runUnary((a) => (fn as dynamic)(a), arg);
            }
            throw RuntimeError('Zone.runUnary expects a callback function');
          },
          'runBinary': (visitor, target, positionalArgs, namedArgs) {
            final zone = target as Zone;
            final fn = positionalArgs[0];
            final arg1 = positionalArgs[1];
            final arg2 = positionalArgs[2];
            if (fn is InterpretedFunction) {
              return zone.runBinary((a, b) => fn.call(visitor, [a, b]), arg1, arg2);
            } else if (fn is Function) {
              return zone.runBinary((a, b) => (fn as dynamic)(a, b), arg1, arg2);
            }
            throw RuntimeError('Zone.runBinary expects a callback function');
          },
          'runGuarded': (visitor, target, positionalArgs, namedArgs) {
            final zone = target as Zone;
            final fn = positionalArgs[0];
            if (fn is InterpretedFunction) {
              return zone.runGuarded(() => fn.call(visitor, []));
            } else if (fn is Function) {
              return zone.runGuarded(() => fn());
            }
            throw RuntimeError('Zone.runGuarded expects a callback function');
          },
          '[]': (visitor, target, positionalArgs, namedArgs) {
            return (target as Zone)[positionalArgs[0]];
          },
          'inSameErrorZone': (visitor, target, positionalArgs, namedArgs) {
            final other = _unwrapZone(positionalArgs[0]);
            return (target as Zone).inSameErrorZone(other);
          },
          'handleUncaughtError': (visitor, target, positionalArgs, namedArgs) {
            final zone = target as Zone;
            final error = positionalArgs[0] as Object;
            final stackTrace = positionalArgs.length > 1 && positionalArgs[1] is StackTrace
                ? positionalArgs[1] as StackTrace
                : StackTrace.current;
            zone.handleUncaughtError(error, stackTrace);
            return null;
          },
          'registerCallback': (visitor, target, positionalArgs, namedArgs) {
            final zone = target as Zone;
            final fn = positionalArgs[0];
            if (fn is InterpretedFunction) {
              return zone.registerCallback(() => fn.call(visitor, []));
            }
            return zone.registerCallback(fn as dynamic);
          },
          'registerUnaryCallback': (visitor, target, positionalArgs, namedArgs) {
            final zone = target as Zone;
            final fn = positionalArgs[0];
            if (fn is InterpretedFunction) {
              return zone.registerUnaryCallback((a) => fn.call(visitor, [a]));
            }
            return zone.registerUnaryCallback(fn as dynamic);
          },
          'registerBinaryCallback': (visitor, target, positionalArgs, namedArgs) {
            final zone = target as Zone;
            final fn = positionalArgs[0];
            if (fn is InterpretedFunction) {
              return zone.registerBinaryCallback((a, b) => fn.call(visitor, [a, b]));
            }
            return zone.registerBinaryCallback(fn as dynamic);
          },
        },
        getters: {
          'parent': (visitor, target) => (target as Zone).parent,
          'errorZone': (visitor, target) => (target as Zone).errorZone,
        },
      );
}
