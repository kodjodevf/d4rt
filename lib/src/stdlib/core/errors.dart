import 'package:d4rt/d4rt.dart';

class ErrorCore {
  static BridgedClass get definition => BridgedClass(
        nativeType: Error,
        name: 'Error',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            return Error();
          },
        },
        staticMethods: {
          'safeToString': (visitor, positionalArgs, namedArgs) {
            final object = positionalArgs.required<Object?>(0, 'object');
            throw Error.safeToString(object);
          },
        },
        methods: {
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as Error).toString();
          },
        },
        getters: {
          'hashCode': (visitor, target) => (target as Error).hashCode,
          'runtimeType': (visitor, target) => (target as Error).runtimeType,
          'stackTrace': (visitor, target) => (target as Error).stackTrace,
        },
      );
}

class AssertionErrorCore {
  static BridgedClass get definition => BridgedClass(
        nativeType: AssertionError,
        name: 'AssertionError',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            final message =
                positionalArgs.optional<Object?>(0, 'message', null);
            return AssertionError(message);
          },
        },
        methods: {
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as AssertionError).toString();
          },
        },
        getters: {
          'message': (visitor, target) => (target as AssertionError).message,
          'stackTrace': (visitor, target) =>
              (target as AssertionError).stackTrace,
          'hashCode': (visitor, target) => (target as AssertionError).hashCode,
          'runtimeType': (visitor, target) =>
              (target as AssertionError).runtimeType,
        },
      );
}

class TypeErrorCore {
  static BridgedClass get definition => BridgedClass(
        nativeType: TypeError,
        name: 'TypeError',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            return TypeError();
          },
        },
        methods: {
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as TypeError).toString();
          },
        },
        getters: {
          'stackTrace': (visitor, target) => (target as TypeError).stackTrace,
          'hashCode': (visitor, target) => (target as TypeError).hashCode,
          'runtimeType': (visitor, target) => (target as TypeError).runtimeType,
        },
      );
}

class ArgumentErrorCore {
  static BridgedClass get definition => BridgedClass(
        nativeType: ArgumentError,
        name: 'ArgumentError',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            return ArgumentError();
          },
        },
        staticMethods: {
          'checkNotNull': (visitor, positionalArgs, namedArgs) {
            final argument = positionalArgs.required<Object?>(0, 'argument');
            final name = positionalArgs.optional<String?>(1, 'name', null);

            return ArgumentError.checkNotNull(
              argument,
              name,
            );
          },
          'notNull': (visitor, positionalArgs, namedArgs) {
            final name = positionalArgs.optional<String?>(1, 'name', null);

            return ArgumentError.notNull(name);
          },
          'value': (visitor, positionalArgs, namedArgs) {
            final value = positionalArgs.required<dynamic>(0, 'value');
            final name = positionalArgs.optional<String?>(1, 'name', null);
            final message =
                positionalArgs.optional<dynamic>(2, 'message', null);

            return ArgumentError.value(
              value,
              name,
              message,
            );
          },
        },
        methods: {
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as ArgumentError).toString();
          },
        },
        getters: {
          'stackTrace': (visitor, target) =>
              (target as ArgumentError).stackTrace,
          'hashCode': (visitor, target) => (target as ArgumentError).hashCode,
          'runtimeType': (visitor, target) =>
              (target as ArgumentError).runtimeType,
          'message': (visitor, target) => (target as ArgumentError).message,
          'invalidValue': (visitor, target) =>
              (target as ArgumentError).invalidValue,
        },
      );
}

class RangeErrorCore {
  static BridgedClass get definition => BridgedClass(
        nativeType: RangeError,
        name: 'RangeError',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            final message =
                positionalArgs.optional<dynamic>(0, 'message', null);
            return RangeError(message);
          },
        },
        staticMethods: {
          'checkValueInInterval': (visitor, positionalArgs, namedArgs) {
            final value = positionalArgs.required<int>(0, 'value');
            final minValue = positionalArgs.required<int>(1, 'minValue');
            final maxValue = positionalArgs.required<int>(2, 'maxValue');
            final name = positionalArgs.optional<String?>(3, 'name', null);
            final message =
                positionalArgs.optional<String?>(4, 'message', null);

            return RangeError.checkValueInInterval(
                value, minValue, maxValue, name, message);
          },
          'checkNotNegative': (visitor, positionalArgs, namedArgs) {
            final value = positionalArgs.required<int>(0, 'value');
            final name = positionalArgs.optional<String?>(1, 'name', null);
            final message =
                positionalArgs.optional<String?>(2, 'message', null);

            return RangeError.checkNotNegative(value, name, message);
          },
          'checkValidRange': (visitor, positionalArgs, namedArgs) {
            final start = positionalArgs.required<int>(0, 'start');
            final end = positionalArgs.required<int?>(1, 'end');
            final length = positionalArgs.required<int>(2, 'length');
            final startName =
                positionalArgs.optional<String?>(3, 'startName', null);
            final endName =
                positionalArgs.optional<String?>(4, 'endName', null);
            final message =
                positionalArgs.optional<String?>(5, 'message', null);

            return RangeError.checkValidRange(
                start, end, length, startName, endName, message);
          },
        },
        methods: {
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as RangeError).toString();
          },
        },
        getters: {
          'stackTrace': (visitor, target) => (target as RangeError).stackTrace,
          'hashCode': (visitor, target) => (target as RangeError).hashCode,
          'runtimeType': (visitor, target) =>
              (target as RangeError).runtimeType,
          'message': (visitor, target) => (target as RangeError).message,
          'invalidValue': (visitor, target) =>
              (target as RangeError).invalidValue,
        },
      );
}
