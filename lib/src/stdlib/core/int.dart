import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/bridge/registration.dart';

class IntCore {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        nativeType: int,
        name: 'int',
        typeParameterCount: 0,
        constructors: {},
        staticMethods: {
          'parse': (visitor, positionalArgs, namedArgs) {
            final source = positionalArgs[0] as String;
            final radix = namedArgs['radix'] as int?;
            return int.parse(source, radix: radix);
          },
          'tryParse': (visitor, positionalArgs, namedArgs) {
            final source = positionalArgs[0] as String;
            final radix = namedArgs['radix'] as int?;
            return int.tryParse(source, radix: radix);
          },
          'fromEnvironment': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'int.fromEnvironment expects one String argument for the name.');
            }
            return int.fromEnvironment(positionalArgs[0] as String,
                defaultValue: namedArgs['defaultValue'] as int? ?? 0);
          },
        },
        methods: {
          'abs': (visitor, target, positionalArgs, namedArgs) {
            return (target as int).abs();
          },
          'ceil': (visitor, target, positionalArgs, namedArgs) {
            return (target as int).ceil();
          },
          'floor': (visitor, target, positionalArgs, namedArgs) {
            return (target as int).floor();
          },
          'round': (visitor, target, positionalArgs, namedArgs) {
            return (target as int).round();
          },
          'truncate': (visitor, target, positionalArgs, namedArgs) {
            return (target as int).truncate();
          },
          'toDouble': (visitor, target, positionalArgs, namedArgs) {
            return (target as int).toDouble();
          },
          'toInt': (visitor, target, positionalArgs, namedArgs) {
            return (target as int).toInt();
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as int).toString();
          },
          'toStringAsFixed': (visitor, target, positionalArgs, namedArgs) {
            return (target as int).toStringAsFixed(positionalArgs[0] as int);
          },
          'toStringAsExponential':
              (visitor, target, positionalArgs, namedArgs) {
            final fractionDigits =
                positionalArgs.isNotEmpty ? positionalArgs[0] as int? : null;
            return (target as int).toStringAsExponential(fractionDigits);
          },
          'toStringAsPrecision': (visitor, target, positionalArgs, namedArgs) {
            return (target as int)
                .toStringAsPrecision(positionalArgs[0] as int);
          },
          'toRadixString': (visitor, target, positionalArgs, namedArgs) {
            return (target as int).toRadixString(positionalArgs[0] as int);
          },
          'compareTo': (visitor, target, positionalArgs, namedArgs) {
            return (target as int).compareTo(positionalArgs[0] as num);
          },
          'clamp': (visitor, target, positionalArgs, namedArgs) {
            return (target as int)
                .clamp(positionalArgs[0] as num, positionalArgs[1] as num);
          },
          'remainder': (visitor, target, positionalArgs, namedArgs) {
            return (target as int).remainder(positionalArgs[0] as num);
          },
          'gcd': (visitor, target, positionalArgs, namedArgs) {
            return (target as int).gcd(positionalArgs[0] as int);
          },
          'modInverse': (visitor, target, positionalArgs, namedArgs) {
            return (target as int).modInverse(positionalArgs[0] as int);
          },
          'modPow': (visitor, target, positionalArgs, namedArgs) {
            return (target as int)
                .modPow(positionalArgs[0] as int, positionalArgs[1] as int);
          },
          'toSigned': (visitor, target, positionalArgs, namedArgs) {
            return (target as int).toSigned(positionalArgs[0] as int);
          },
          'toUnsigned': (visitor, target, positionalArgs, namedArgs) {
            return (target as int).toUnsigned(positionalArgs[0] as int);
          },
          '+': (visitor, target, positionalArgs, namedArgs) {
            return (target as int) + (positionalArgs[0] as num);
          },
          '-': (visitor, target, positionalArgs, namedArgs) {
            return (target as int) - (positionalArgs[0] as num);
          },
          '*': (visitor, target, positionalArgs, namedArgs) {
            return (target as int) * (positionalArgs[0] as num);
          },
          '/': (visitor, target, positionalArgs, namedArgs) {
            return (target as int) / (positionalArgs[0] as num);
          },
          '~/': (visitor, target, positionalArgs, namedArgs) {
            return (target as int) ~/ (positionalArgs[0] as num);
          },
          '%': (visitor, target, positionalArgs, namedArgs) {
            return (target as int) % (positionalArgs[0] as num);
          },
          '<<': (visitor, target, positionalArgs, namedArgs) {
            return (target as int) << (positionalArgs[0] as int);
          },
          '>>': (visitor, target, positionalArgs, namedArgs) {
            return (target as int) >> (positionalArgs[0] as int);
          },
          '&': (visitor, target, positionalArgs, namedArgs) {
            return (target as int) & (positionalArgs[0] as int);
          },
          '|': (visitor, target, positionalArgs, namedArgs) {
            return (target as int) | (positionalArgs[0] as int);
          },
          '^': (visitor, target, positionalArgs, namedArgs) {
            return (target as int) ^ (positionalArgs[0] as int);
          },
          'unary-': (visitor, target, positionalArgs, namedArgs) {
            return -(target as int);
          },
          '~': (visitor, target, positionalArgs, namedArgs) {
            return ~(target as int);
          },
        },
        getters: {
          'hashCode': (visitor, target) => (target as int).hashCode,
          'runtimeType': (visitor, target) => (target as int).runtimeType,
          'bitLength': (visitor, target) => (target as int).bitLength,
          'sign': (visitor, target) => (target as int).sign,
          'isEven': (visitor, target) => (target as int).isEven,
          'isOdd': (visitor, target) => (target as int).isOdd,
          'isFinite': (visitor, target) => (target as int).isFinite,
          'isInfinite': (visitor, target) => (target as int).isInfinite,
          'isNaN': (visitor, target) => (target as int).isNaN,
          'isNegative': (visitor, target) => (target as int).isNegative,
        },
      );
}
