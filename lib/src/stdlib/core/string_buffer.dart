import 'package:d4rt/src/bridge/registration.dart';

class StringBufferCore {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        nativeType: StringBuffer,
        name: 'StringBuffer',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            final contents =
                positionalArgs.isNotEmpty ? positionalArgs[0] as Object : '';
            return StringBuffer(contents);
          },
        },
        methods: {
          'write': (visitor, target, positionalArgs, namedArgs) {
            (target as StringBuffer).write(positionalArgs[0]);
            return null;
          },
          'writeAll': (visitor, target, positionalArgs, namedArgs) {
            final objects = positionalArgs[0] as Iterable;
            final separator =
                positionalArgs.length > 1 ? positionalArgs[1] as String : '';
            (target as StringBuffer).writeAll(objects, separator);
            return null;
          },
          'writeln': (visitor, target, positionalArgs, namedArgs) {
            final obj = positionalArgs.isNotEmpty ? positionalArgs[0] : '';
            (target as StringBuffer).writeln(obj);
            return null;
          },
          'writeCharCode': (visitor, target, positionalArgs, namedArgs) {
            (target as StringBuffer).writeCharCode(positionalArgs[0] as int);
            return null;
          },
          'clear': (visitor, target, positionalArgs, namedArgs) {
            (target as StringBuffer).clear();
            return null;
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as StringBuffer).toString();
          },
        },
        getters: {
          'length': (visitor, target) => (target as StringBuffer).length,
          'isEmpty': (visitor, target) => (target as StringBuffer).isEmpty,
          'isNotEmpty': (visitor, target) =>
              (target as StringBuffer).isNotEmpty,
          'hashCode': (visitor, target) => (target as StringBuffer).hashCode,
          'runtimeType': (visitor, target) =>
              (target as StringBuffer).runtimeType,
        },
      );
}
