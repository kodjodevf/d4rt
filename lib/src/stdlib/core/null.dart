import 'package:d4rt/d4rt.dart';

class NullCore {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        nativeType: Null,
        name: 'Null',
        typeParameterCount: 0,
        methods: {
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as Null).toString();
          },
        },
        getters: {
          'hashCode': (visitor, target) => (target as Null).hashCode,
        },
      );
}
