import 'package:d4rt/d4rt.dart';

class StackTraceCore {
  static BridgedClass get definition => BridgedClass(
        nativeType: StackTrace,
        name: 'StackTrace',
        typeParameterCount: 0,
        constructors: {},
        staticMethods: {
          'current': (visitor, positionalArgs, namedArgs) {
            return StackTrace.current;
          },
          'empty': (visitor, positionalArgs, namedArgs) {
            return StackTrace.empty;
          },
        },
        methods: {
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as StackTrace).toString();
          },
        },
        getters: {
          'hashCode': (visitor, target) => (target as StackTrace).hashCode,
          'runtimeType': (visitor, target) =>
              (target as StackTrace).runtimeType,
        },
      );
}
