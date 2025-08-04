import 'package:d4rt/d4rt.dart';

class ExceptionCore {
  static BridgedClass get definition => BridgedClass(
        nativeType: Exception,
        name: 'Exception',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            final message =
                positionalArgs.isNotEmpty ? positionalArgs[0] as String? : null;
            return Exception(message);
          },
        },
        methods: {
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as Exception).toString();
          },
        },
        getters: {
          'hashCode': (visitor, target) => (target as Exception).hashCode,
          'runtimeType': (visitor, target) => (target as Exception).runtimeType,
        },
      );
}

class FormatExceptionCore {
  static BridgedClass get definition => BridgedClass(
        nativeType: FormatException,
        name: 'FormatException',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            final message =
                positionalArgs.isNotEmpty ? positionalArgs[0] as String : '';
            final source = namedArgs['source'];
            final offset = namedArgs['offset'] as int?;
            return FormatException(message, source, offset);
          },
        },
        methods: {
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as FormatException).toString();
          },
        },
        getters: {
          'message': (visitor, target) => (target as FormatException).message,
          'source': (visitor, target) => (target as FormatException).source,
          'offset': (visitor, target) => (target as FormatException).offset,
          'hashCode': (visitor, target) => (target as FormatException).hashCode,
          'runtimeType': (visitor, target) =>
              (target as FormatException).runtimeType,
        },
      );
}
