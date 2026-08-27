import 'package:d4rt/d4rt.dart';

class RecordCore {
  static BridgedClass get definition => BridgedClass(
        nativeType: Record,
        name: 'Record',
        typeParameterCount: 0,
        nativeNames: ['_Record'],
        constructors: {},
        methods: {
          '==': (visitor, target, positionalArgs, namedArgs) =>
              target == positionalArgs[0],
          'toString': (visitor, target, positionalArgs, namedArgs) =>
              target.toString(),
          'noSuchMethod': (visitor, target, positionalArgs, namedArgs) =>
              (target as dynamic).noSuchMethod(positionalArgs[0] as Invocation),
        },
        getters: {
          'hashCode': (visitor, target) => target.hashCode,
          'runtimeType': (visitor, target) => target.runtimeType,
        },
      );
}
