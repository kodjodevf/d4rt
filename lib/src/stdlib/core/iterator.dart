import 'package:d4rt/src/bridge/registration.dart';

class IteratorCore {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        nativeType: Iterator,
        name: 'Iterator',
        typeParameterCount: 1,
        nativeNames: ['_ListQueueIterator', '_HashSetIterator'],
        methods: {
          'moveNext': (visitor, target, positionalArgs, namedArgs) {
            return (target as Iterator).moveNext();
          },
        },
        getters: {
          'current': (visitor, target) => (target as Iterator).current,
          'hashCode': (visitor, target) => (target as Iterator).hashCode,
          'runtimeType': (visitor, target) => (target as Iterator).runtimeType,
        },
      );
}
