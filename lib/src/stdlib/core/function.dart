import 'package:d4rt/d4rt.dart';

class FunctionCore {
  static BridgedClass get definition => BridgedClass(
        nativeType: Function,
        name: 'Function',
        typeParameterCount: 0,
        constructors: {},
        staticMethods: {
          'apply': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty || positionalArgs[0] is! Callable) {
              throw RuntimeError(
                  'Function.apply requires a Callable as the first argument.');
            }
            final functionToApply = positionalArgs[0] as Callable;
            final argumentsToPass = positionalArgs.length > 1
                ? positionalArgs[1] as List<Object?>
                : <Object?>[];
            final namedArgumentsToPass = positionalArgs.length > 2
                ? positionalArgs[2] as Map<String, Object?>
                : namedArgs;

            return functionToApply.call(
                visitor, argumentsToPass, namedArgumentsToPass);
          },
        },
        methods: {
          'call': (visitor, target, positionalArgs, namedArgs) {
            if (target is Callable) {
              return target.call(visitor, positionalArgs, namedArgs);
            }
            throw RuntimeError('Cannot call non-Callable Function');
          },
          'hashCode': (visitor, target, positionalArgs, namedArgs) =>
              (target as Function).hashCode,
          'toString': (visitor, target, positionalArgs, namedArgs) =>
              (target as Function).toString(),
        },
        getters: {
          'hashCode': (visitor, target) => (target as Function).hashCode,
          'runtimeType': (visitor, target) => (target as Function).runtimeType,
        },
      );
}
