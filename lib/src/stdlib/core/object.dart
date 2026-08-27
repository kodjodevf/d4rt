import 'package:d4rt/d4rt.dart';

class ObjectCore {
  static BridgedClass get definition => BridgedClass(
        nativeType: Object,
        name: 'Object',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) => Object(),
        },
        staticMethods: {
          'hash': (visitor, positionalArgs, namedArgs) {
            return Object.hashAll(positionalArgs);
          },
          'hashAll': (visitor, positionalArgs, namedArgs) {
            final iterable = positionalArgs[0] as Iterable;
            return Object.hashAll(iterable);
          },
          'hashAllUnordered': (visitor, positionalArgs, namedArgs) {
            final iterable = positionalArgs[0] as Iterable;
            return Object.hashAllUnordered(iterable);
          },
        },
        methods: {
          '==': (visitor, target, positionalArgs, namedArgs) {
            return target == positionalArgs[0];
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return target.toString();
          },
          'noSuchMethod': (visitor, target, positionalArgs, namedArgs) {
            return (target as dynamic).noSuchMethod(positionalArgs[0] as Invocation);
          },
        },
        getters: {
          'hashCode': (visitor, target) => target.hashCode,
          'runtimeType': (visitor, target) => target.runtimeType,
        },
      );
}
