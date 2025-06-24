import 'package:d4rt/d4rt.dart';

class BigIntCore {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        nativeType: BigInt,
        name: 'BigInt',
        typeParameterCount: 0,
        constructors: {},
        staticMethods: {
          'from': (visitor, positionalArgs, namedArgs) {
            return BigInt.from(positionalArgs[0] as num);
          },
          'parse': (visitor, positionalArgs, namedArgs) {
            final source = positionalArgs[0] as String;
            final radix = namedArgs['radix'] as int?;
            return BigInt.parse(source, radix: radix);
          },
          'tryParse': (visitor, positionalArgs, namedArgs) {
            final source = positionalArgs[0] as String;
            final radix = namedArgs['radix'] as int?;
            return BigInt.tryParse(source, radix: radix);
          },
        },
        staticGetters: {
          'zero': (visito) => BigInt.zero,
          'one': (visito) => BigInt.one,
          'two': (visito) => BigInt.two,
        },
        methods: {
          '+': (visitor, target, positionalArgs, namedArgs) {
            return (target as BigInt) + (positionalArgs[0] as BigInt);
          },
          '-': (visitor, target, positionalArgs, namedArgs) {
            return (target as BigInt) - (positionalArgs[0] as BigInt);
          },
          '*': (visitor, target, positionalArgs, namedArgs) {
            return (target as BigInt) * (positionalArgs[0] as BigInt);
          },
          '~/': (visitor, target, positionalArgs, namedArgs) {
            return (target as BigInt) ~/ (positionalArgs[0] as BigInt);
          },
          '%': (visitor, target, positionalArgs, namedArgs) {
            return (target as BigInt) % (positionalArgs[0] as BigInt);
          },
          'remainder': (visitor, target, positionalArgs, namedArgs) {
            return (target as BigInt).remainder(positionalArgs[0] as BigInt);
          },
          'pow': (visitor, target, positionalArgs, namedArgs) {
            return (target as BigInt).pow(positionalArgs[0] as int);
          },
          'modPow': (visitor, target, positionalArgs, namedArgs) {
            return (target as BigInt).modPow(
                positionalArgs[0] as BigInt, positionalArgs[1] as BigInt);
          },
          'modInverse': (visitor, target, positionalArgs, namedArgs) {
            return (target as BigInt).modInverse(positionalArgs[0] as BigInt);
          },
          'gcd': (visitor, target, positionalArgs, namedArgs) {
            return (target as BigInt).gcd(positionalArgs[0] as BigInt);
          },
          'abs': (visitor, target, positionalArgs, namedArgs) {
            return (target as BigInt).abs();
          },
          'compareTo': (visitor, target, positionalArgs, namedArgs) {
            return (target as BigInt).compareTo(positionalArgs[0] as BigInt);
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as BigInt).toString();
          },
          'toRadixString': (visitor, target, positionalArgs, namedArgs) {
            return (target as BigInt).toRadixString(positionalArgs[0] as int);
          },
          'toInt': (visitor, target, positionalArgs, namedArgs) {
            return (target as BigInt).toInt();
          },
          'toDouble': (visitor, target, positionalArgs, namedArgs) {
            return (target as BigInt).toDouble();
          },
          'toUnsigned': (visitor, target, positionalArgs, namedArgs) {
            return (target as BigInt).toUnsigned(positionalArgs[0] as int);
          },
          'toSigned': (visitor, target, positionalArgs, namedArgs) {
            return (target as BigInt).toSigned(positionalArgs[0] as int);
          },
          'unary-': (visitor, target, positionalArgs, namedArgs) {
            return -(target as BigInt);
          },
          '&': (visitor, target, positionalArgs, namedArgs) {
            return (target as BigInt) & (positionalArgs[0] as BigInt);
          },
          '|': (visitor, target, positionalArgs, namedArgs) {
            return (target as BigInt) | (positionalArgs[0] as BigInt);
          },
          '^': (visitor, target, positionalArgs, namedArgs) {
            return (target as BigInt) ^ (positionalArgs[0] as BigInt);
          },
          '~': (visitor, target, positionalArgs, namedArgs) {
            return ~(target as BigInt);
          },
          '<<': (visitor, target, positionalArgs, namedArgs) {
            return (target as BigInt) << (positionalArgs[0] as int);
          },
          '>>': (visitor, target, positionalArgs, namedArgs) {
            return (target as BigInt) >> (positionalArgs[0] as int);
          },
          '==': (visitor, target, positionalArgs, namedArgs) {
            return (target as BigInt) == positionalArgs[0];
          },
          '<': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs[0] is BigInt) {
              return (target as BigInt) < (positionalArgs[0] as BigInt);
            }
            throw RuntimeError("BigInt comparison requires another BigInt");
          },
          '<=': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs[0] is BigInt) {
              return (target as BigInt) <= (positionalArgs[0] as BigInt);
            }
            throw RuntimeError("BigInt comparison requires another BigInt");
          },
          '>': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs[0] is BigInt) {
              return (target as BigInt) > (positionalArgs[0] as BigInt);
            }
            throw RuntimeError("BigInt comparison requires another BigInt");
          },
          '>=': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs[0] is BigInt) {
              return (target as BigInt) >= (positionalArgs[0] as BigInt);
            }
            throw RuntimeError("BigInt comparison requires another BigInt");
          },
        },
        getters: {
          'sign': (visitor, target) => (target as BigInt).sign,
          'isEven': (visitor, target) => (target as BigInt).isEven,
          'isOdd': (visitor, target) => (target as BigInt).isOdd,
          'isNegative': (visitor, target) => (target as BigInt).isNegative,
          'bitLength': (visitor, target) => (target as BigInt).bitLength,
          'isValidInt': (visitor, target) => (target as BigInt).isValidInt,
          'hashCode': (visitor, target) => (target as BigInt).hashCode,
          'runtimeType': (visitor, target) => (target as BigInt).runtimeType,
        },
      );
}
