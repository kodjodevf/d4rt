import 'package:d4rt/d4rt.dart';

class IteratorCore {
  static BridgedClass get definition => BridgedClass(
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
