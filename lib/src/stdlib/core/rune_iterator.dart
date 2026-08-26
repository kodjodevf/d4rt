import 'package:d4rt/d4rt.dart';

class RuneIteratorCore {
  static BridgedClass get definition => BridgedClass(
        nativeType: RuneIterator,
        name: 'RuneIterator',
        typeParameterCount: 0,
        isSubtypeOfFunc: (value) => value is RuneIterator,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty || positionalArgs[0] is! String) {
              throw RuntimeError("RuneIterator constructor expects a String argument.");
            }
            return RuneIterator(positionalArgs[0] as String);
          },
          'at': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length < 2 ||
                positionalArgs[0] is! String ||
                positionalArgs[1] is! int) {
              throw RuntimeError("RuneIterator.at constructor expects a String and an int index.");
            }
            return RuneIterator.at(
                positionalArgs[0] as String, positionalArgs[1] as int);
          },
        },
        methods: {
          'moveNext': (visitor, target, positionalArgs, namedArgs) {
            return (target as RuneIterator).moveNext();
          },
          'movePrevious': (visitor, target, positionalArgs, namedArgs) {
            return (target as RuneIterator).movePrevious();
          },
          'reset': (visitor, target, positionalArgs, namedArgs) {
            final rawIndex =
                positionalArgs.isNotEmpty ? positionalArgs[0] as int : 0;
            (target as RuneIterator).reset(rawIndex);
            return null;
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as RuneIterator).toString();
          },
        },
        getters: {
          'current': (visitor, target) => (target as RuneIterator).current,
          'currentSize': (visitor, target) =>
              (target as RuneIterator).currentSize,
          'currentAsString': (visitor, target) =>
              (target as RuneIterator).currentAsString,
          'rawIndex': (visitor, target) => (target as RuneIterator).rawIndex,
          'string': (visitor, target) => (target as RuneIterator).string,
          'hashCode': (visitor, target) => (target as RuneIterator).hashCode,
          'runtimeType': (visitor, target) =>
              (target as RuneIterator).runtimeType,
        },
      );
}
