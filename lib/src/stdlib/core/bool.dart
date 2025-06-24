import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/bridge/registration.dart';

class BoolCore {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        nativeType: bool,
        name: 'bool',
        typeParameterCount: 0,
        constructors: {},
        staticMethods: {
          'fromEnvironment': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'bool.fromEnvironment expects one String argument for the name.');
            }
            return bool.fromEnvironment(positionalArgs[0] as String,
                defaultValue: namedArgs['defaultValue'] as bool? ?? false);
          },
          'hasEnvironment': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'bool.hasEnvironment expects one String argument for the name.');
            }
            return bool.hasEnvironment(positionalArgs[0] as String);
          },
          'parse': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError('bool.parse expects one String argument.');
            }
            final caseSensitive = namedArgs['caseSensitive'] as bool? ?? true;
            return bool.parse(positionalArgs[0] as String,
                caseSensitive: caseSensitive);
          },
          'tryParse': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError('bool.tryParse expects one String argument.');
            }
            final caseSensitive = namedArgs['caseSensitive'] as bool? ?? true;
            return bool.tryParse(positionalArgs[0] as String,
                caseSensitive: caseSensitive);
          },
        },
        methods: {
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as bool).toString();
          },
        },
        getters: {
          'hashCode': (visitor, target) => (target as bool).hashCode,
          'runtimeType': (visitor, target) => (target as bool).runtimeType,
        },
      );
}
