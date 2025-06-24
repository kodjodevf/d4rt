import 'package:d4rt/d4rt.dart';

class NumCore {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        nativeType: num,
        name: 'num',
        typeParameterCount: 0,
        constructors: {},
        staticMethods: {
          'parse': (visitor, positionalArgs, namedArgs) {
            return num.parse(positionalArgs[0] as String);
          },
          'tryParse': (visitor, positionalArgs, namedArgs) {
            return num.tryParse(positionalArgs[0] as String);
          },
        },
        methods: {
          'abs': (visitor, target, positionalArgs, namedArgs) {
            return (target as num).abs();
          },
          'ceil': (visitor, target, positionalArgs, namedArgs) {
            return (target as num).ceil();
          },
          'floor': (visitor, target, positionalArgs, namedArgs) {
            return (target as num).floor();
          },
          'round': (visitor, target, positionalArgs, namedArgs) {
            return (target as num).round();
          },
          'truncate': (visitor, target, positionalArgs, namedArgs) {
            return (target as num).truncate();
          },
          'ceilToDouble': (visitor, target, positionalArgs, namedArgs) {
            return (target as num).ceilToDouble();
          },
          'floorToDouble': (visitor, target, positionalArgs, namedArgs) {
            return (target as num).floorToDouble();
          },
          'roundToDouble': (visitor, target, positionalArgs, namedArgs) {
            return (target as num).roundToDouble();
          },
          'truncateToDouble': (visitor, target, positionalArgs, namedArgs) {
            return (target as num).truncateToDouble();
          },
          'toDouble': (visitor, target, positionalArgs, namedArgs) {
            return (target as num).toDouble();
          },
          'toInt': (visitor, target, positionalArgs, namedArgs) {
            return (target as num).toInt();
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as num).toString();
          },
          'toStringAsFixed': (visitor, target, positionalArgs, namedArgs) {
            return (target as num).toStringAsFixed(positionalArgs[0] as int);
          },
          'toStringAsExponential':
              (visitor, target, positionalArgs, namedArgs) {
            final fractionDigits =
                positionalArgs.isNotEmpty ? positionalArgs[0] as int? : null;
            return (target as num).toStringAsExponential(fractionDigits);
          },
          'toStringAsPrecision': (visitor, target, positionalArgs, namedArgs) {
            return (target as num)
                .toStringAsPrecision(positionalArgs[0] as int);
          },
          'compareTo': (visitor, target, positionalArgs, namedArgs) {
            return (target as num).compareTo(positionalArgs[0] as num);
          },
          'clamp': (visitor, target, positionalArgs, namedArgs) {
            return (target as num)
                .clamp(positionalArgs[0] as num, positionalArgs[1] as num);
          },
          'remainder': (visitor, target, positionalArgs, namedArgs) {
            return (target as num).remainder(positionalArgs[0] as num);
          },
          '+': (visitor, target, positionalArgs, namedArgs) {
            return (target as num) + (positionalArgs[0] as num);
          },
          '-': (visitor, target, positionalArgs, namedArgs) {
            return (target as num) - (positionalArgs[0] as num);
          },
          '*': (visitor, target, positionalArgs, namedArgs) {
            return (target as num) * (positionalArgs[0] as num);
          },
          '/': (visitor, target, positionalArgs, namedArgs) {
            return (target as num) / (positionalArgs[0] as num);
          },
          '~/': (visitor, target, positionalArgs, namedArgs) {
            return (target as num) ~/ (positionalArgs[0] as num);
          },
          '%': (visitor, target, positionalArgs, namedArgs) {
            return (target as num) % (positionalArgs[0] as num);
          },
          'unary-': (visitor, target, positionalArgs, namedArgs) {
            return -(target as num);
          },
        },
        getters: {
          'hashCode': (visitor, target) => (target as num).hashCode,
          'runtimeType': (visitor, target) => (target as num).runtimeType,
          'sign': (visitor, target) => (target as num).sign,
          'isFinite': (visitor, target) => (target as num).isFinite,
          'isInfinite': (visitor, target) => (target as num).isInfinite,
          'isNaN': (visitor, target) => (target as num).isNaN,
          'isNegative': (visitor, target) => (target as num).isNegative,
        },
      );
}
