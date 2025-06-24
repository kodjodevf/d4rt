import 'package:d4rt/d4rt.dart';

class TypeCore {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        nativeType: Type,
        name: 'Type',
        typeParameterCount: 0,
        methods: {
          '==': (visitor, target, positionalArgs, namedArgs) {
            return (target as Type) == positionalArgs[0];
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as Type).toString();
          },
        },
        getters: {
          'hashCode': (visitor, target) => (target as Type).hashCode,
          'runtimeType': (visitor, target) => (target as Type).runtimeType,
        },
      );
}
