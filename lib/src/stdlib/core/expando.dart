import 'package:d4rt/d4rt.dart';

class ExpandoCore {
  static BridgedClass get definition => BridgedClass(
        nativeType: Expando,
        name: 'Expando',
        typeParameterCount: 1,
        isSubtypeOfFunc: (value) => value is Expando,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            final name =
                positionalArgs.isNotEmpty ? positionalArgs[0] as String? : null;
            return Expando<Object>(name);
          },
        },
        methods: {
          '[]': (visitor, target, positionalArgs, namedArgs) {
            final object = positionalArgs[0] as Object;
            return (target as Expando)[object];
          },
          '[]=': (visitor, target, positionalArgs, namedArgs) {
            final object = positionalArgs[0] as Object;
            final value = positionalArgs[1];
            (target as Expando)[object] = value;
            return value;
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as Expando).toString();
          },
        },
        getters: {
          'name': (visitor, target) => (target as Expando).name,
          'hashCode': (visitor, target) => (target as Expando).hashCode,
          'runtimeType': (visitor, target) => (target as Expando).runtimeType,
        },
      );
}
