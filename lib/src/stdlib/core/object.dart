import 'package:d4rt/d4rt.dart';

class ObjectCore {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        nativeType: Object,
        name: 'Object',
        typeParameterCount: 0,
        methods: {
          '==': (visitor, target, positionalArgs, namedArgs) {
            return target == positionalArgs[0];
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return target.toString();
          },
        },
        getters: {
          'hashCode': (visitor, target) => target.hashCode,
          'runtimeType': (visitor, target) => target.runtimeType,
        },
      );
}
