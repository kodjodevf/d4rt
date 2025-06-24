import 'package:d4rt/d4rt.dart';

class SinkCore {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        nativeType: Sink,
        name: 'Sink',
        typeParameterCount: 1,
        constructors: {},
        methods: {
          'add': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1) {
              throw RuntimeError('Sink.add requires exactly one argument.');
            }
            (target as Sink).add(positionalArgs[0]);
            return null;
          },
          'close': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.isNotEmpty || namedArgs.isNotEmpty) {
              throw RuntimeError('Sink.close expects no arguments.');
            }
            (target as Sink).close();
            return null;
          },
          'hashCode': (visitor, target, positionalArgs, namedArgs) =>
              (target as Sink).hashCode,
          'toString': (visitor, target, positionalArgs, namedArgs) =>
              (target as Sink).toString(),
        },
        getters: {
          'hashCode': (visitor, target) => (target as Sink).hashCode,
          'runtimeType': (visitor, target) => (target as Sink).runtimeType,
        },
      );
}
