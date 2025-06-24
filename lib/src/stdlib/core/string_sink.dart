import 'package:d4rt/d4rt.dart';

class StringSinkCore {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        nativeType: StringSink,
        name: 'StringSink',
        typeParameterCount: 0,
        constructors: {},
        methods: {
          'write': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1) {
              throw RuntimeError(
                  'StringSink.write requires exactly one argument.');
            }
            (target as StringSink).write(positionalArgs[0]);
            return null;
          },
          'writeln': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length > 1) {
              throw RuntimeError(
                  'StringSink.writeln takes at most one argument.');
            }
            (target as StringSink)
                .writeln(positionalArgs.get<Object?>(0) ?? "");
            return null;
          },
          'writeAll': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty ||
                positionalArgs.length > 2 ||
                positionalArgs[0] is! Iterable) {
              throw RuntimeError(
                  'StringSink.writeAll requires an Iterable and an optional separator String.');
            }
            (target as StringSink).writeAll(positionalArgs[0] as Iterable,
                positionalArgs.get<String?>(1) ?? "");
            return null;
          },
          'writeCharCode': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! int) {
              throw RuntimeError(
                  'StringSink.writeCharCode requires one integer argument.');
            }
            (target as StringSink).writeCharCode(positionalArgs[0] as int);
            return null;
          },
          'hashCode': (visitor, target, positionalArgs, namedArgs) =>
              (target as StringSink).hashCode,
          'toString': (visitor, target, positionalArgs, namedArgs) =>
              (target as StringSink).toString(),
        },
        getters: {
          'hashCode': (visitor, target) => (target as StringSink).hashCode,
          'runtimeType': (visitor, target) =>
              (target as StringSink).runtimeType,
        },
      );
}
