import 'package:d4rt/d4rt.dart';

class FinalizerCore {
  static BridgedClass get definition => BridgedClass(
        nativeType: Finalizer,
        name: 'Finalizer',
        typeParameterCount: 1,
        isSubtypeOfFunc: (value) => value is Finalizer,
        nativeNames: ['_Finalizer'],
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty ||
                positionalArgs[0] is! InterpretedFunction) {
              throw RuntimeError(
                  "Finalizer constructor expects a callback function.");
            }
            final callback = positionalArgs[0] as InterpretedFunction;
            return Finalizer<dynamic>(
              (token) => callback.call(visitor, [token]),
            );
          },
        },
        methods: {
          'attach': (visitor, target, positionalArgs, namedArgs) {
            if (target is Finalizer &&
                positionalArgs.length >= 2 &&
                positionalArgs[0] != null) {
              final value = positionalArgs[0] as Object;
              final token = positionalArgs[1];
              final detach = namedArgs['detach'];
              target.attach(value, token, detach: detach);
              return null;
            }
            throw RuntimeError(
                "Finalizer.attach expects an Object value and a finalization token.");
          },
          'detach': (visitor, target, positionalArgs, namedArgs) {
            if (target is Finalizer &&
                positionalArgs.isNotEmpty &&
                positionalArgs[0] != null) {
              final detach = positionalArgs[0] as Object;
              target.detach(detach);
              return null;
            }
            throw RuntimeError("Finalizer.detach expects an Object detach token.");
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as Finalizer).toString();
          },
        },
        getters: {
          'hashCode': (visitor, target) => (target as Finalizer).hashCode,
          'runtimeType': (visitor, target) =>
              (target as Finalizer).runtimeType,
        },
      );
}
