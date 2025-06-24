import 'dart:async';
import 'package:d4rt/d4rt.dart';

class CompleterAsync {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        nativeType: Completer,
        name: 'Completer',
        typeParameterCount: 1, // Completer<T>
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isNotEmpty || namedArgs.isNotEmpty) {
              throw RuntimeError('Completer constructor takes no arguments.');
            }
            return Completer<dynamic>();
          },
        },
        staticMethods: {
          'sync': (visitor, positionalArgs, namedArgs) {
            return Completer<dynamic>.sync();
          },
        },
        methods: {
          'complete': (visitor, target, positionalArgs, namedArgs) {
            (target as Completer).complete(positionalArgs.get<dynamic>(0));
            return null;
          },
          'completeError': (visitor, target, positionalArgs, namedArgs) {
            final error = positionalArgs[0];
            if (error == null) {
              throw RuntimeError(
                  'Completer.completeError requires a non-null error object.');
            }
            (target as Completer)
                .completeError(error, positionalArgs.get<StackTrace?>(1));
            return null;
          },
        },
        getters: {
          'future': (visitor, target) => (target as Completer).future,
          'isCompleted': (visitor, target) => (target as Completer).isCompleted,
          'hashCode': (visitor, target) => (target as Completer).hashCode,
          'runtimeType': (visitor, target) => (target as Completer).runtimeType,
        },
      );
}

class CompleterStdlib {
  static void register(Environment environment) {
    environment.defineBridge(CompleterAsync.definition);
  }
}
