import 'package:d4rt/d4rt.dart';

class DoubleCore {
  static BridgedClass get definition => BridgedClass(
        nativeType: double,
        name: 'double',
        typeParameterCount: 0,
        constructors: {},
        staticMethods: {
          'parse': (visitor, positionalArgs, namedArgs) {
            return double.parse(positionalArgs[0] as String);
          },
          'tryParse': (visitor, positionalArgs, namedArgs) {
            return double.tryParse(positionalArgs[0] as String);
          },
        },
        staticGetters: {
          'infinity': (visitor) => double.infinity,
          'negativeInfinity': (visitor) => double.negativeInfinity,
          'nan': (visitor) => double.nan,
          'maxFinite': (visitor) => double.maxFinite,
          'minPositive': (visitor) => double.minPositive,
        },
        methods: {
          'abs': (visitor, target, positionalArgs, namedArgs) {
            return (target as double).abs();
          },
          'ceil': (visitor, target, positionalArgs, namedArgs) {
            return (target as double).ceil();
          },
          'floor': (visitor, target, positionalArgs, namedArgs) {
            return (target as double).floor();
          },
          'round': (visitor, target, positionalArgs, namedArgs) {
            return (target as double).round();
          },
          'truncate': (visitor, target, positionalArgs, namedArgs) {
            return (target as double).truncate();
          },
          'ceilToDouble': (visitor, target, positionalArgs, namedArgs) {
            return (target as double).ceilToDouble();
          },
          'floorToDouble': (visitor, target, positionalArgs, namedArgs) {
            return (target as double).floorToDouble();
          },
          'roundToDouble': (visitor, target, positionalArgs, namedArgs) {
            return (target as double).roundToDouble();
          },
          'truncateToDouble': (visitor, target, positionalArgs, namedArgs) {
            return (target as double).truncateToDouble();
          },
          'toDouble': (visitor, target, positionalArgs, namedArgs) {
            return (target as double).toDouble();
          },
          'toInt': (visitor, target, positionalArgs, namedArgs) {
            return (target as double).toInt();
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as double).toString();
          },
          'toStringAsFixed': (visitor, target, positionalArgs, namedArgs) {
            return (target as double).toStringAsFixed(positionalArgs[0] as int);
          },
          'toStringAsExponential':
              (visitor, target, positionalArgs, namedArgs) {
            final fractionDigits =
                positionalArgs.isNotEmpty ? positionalArgs[0] as int? : null;
            return (target as double).toStringAsExponential(fractionDigits);
          },
          'toStringAsPrecision': (visitor, target, positionalArgs, namedArgs) {
            return (target as double)
                .toStringAsPrecision(positionalArgs[0] as int);
          },
          'compareTo': (visitor, target, positionalArgs, namedArgs) {
            return (target as double).compareTo(positionalArgs[0] as num);
          },
          'clamp': (visitor, target, positionalArgs, namedArgs) {
            return (target as double)
                .clamp(positionalArgs[0] as num, positionalArgs[1] as num);
          },
          'remainder': (visitor, target, positionalArgs, namedArgs) {
            return (target as double).remainder(positionalArgs[0] as num);
          },
          '+': (visitor, target, positionalArgs, namedArgs) {
            return (target as double) + (positionalArgs[0] as num);
          },
          '-': (visitor, target, positionalArgs, namedArgs) {
            return (target as double) - (positionalArgs[0] as num);
          },
          '*': (visitor, target, positionalArgs, namedArgs) {
            return (target as double) * (positionalArgs[0] as num);
          },
          '/': (visitor, target, positionalArgs, namedArgs) {
            return (target as double) / (positionalArgs[0] as num);
          },
          '~/': (visitor, target, positionalArgs, namedArgs) {
            return (target as double) ~/ (positionalArgs[0] as num);
          },
          '%': (visitor, target, positionalArgs, namedArgs) {
            return (target as double) % (positionalArgs[0] as num);
          },
          'unary-': (visitor, target, positionalArgs, namedArgs) {
            return -(target as double);
          },
        },
        getters: {
          'hashCode': (visitor, target) => (target as double).hashCode,
          'runtimeType': (visitor, target) => (target as double).runtimeType,
          'sign': (visitor, target) => (target as double).sign,
          'isFinite': (visitor, target) => (target as double).isFinite,
          'isInfinite': (visitor, target) => (target as double).isInfinite,
          'isNaN': (visitor, target) => (target as double).isNaN,
          'isNegative': (visitor, target) => (target as double).isNegative,
        },
      );
}
