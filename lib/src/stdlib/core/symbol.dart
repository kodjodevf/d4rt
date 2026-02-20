import 'package:d4rt/d4rt.dart';

class SymbolCore {
  static BridgedClass get definition => BridgedClass(
        nativeType: Symbol,
        name: 'Symbol',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'Symbol constructor requires exactly one String argument.');
            }
            return Symbol(positionalArgs[0] as String);
          },
        },
        methods: {
          '==': (visitor, target, positionalArgs, namedArgs) {
            return (target as Symbol) == positionalArgs[0];
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as Symbol).toString();
          },
        },
        staticGetters: {
          'empty': (visitor) => Symbol.empty,
          'unaryMinus': (visitor) => Symbol.unaryMinus,
        },
        getters: {
          'hashCode': (visitor, target) => (target as Symbol).hashCode,
          'runtimeType': (visitor, target) => (target as Symbol).runtimeType,
        },
      );
}
