import 'package:d4rt/d4rt.dart';

class NullCore {
  static BridgedClass get definition => BridgedClass(
    nativeType: Null,
    name: 'Null',
    typeParameterCount: 0,
    methods: {
      'toString': (visitor, target, positionalArgs, namedArgs) {
        return 'null';
      },
    },
    getters: {'hashCode': (visitor, target) => 0},
  );
}
