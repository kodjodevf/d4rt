import 'package:d4rt/src/bridge/registration.dart';

class DateTimeCore {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        nativeType: DateTime,
        name: 'DateTime',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isNotEmpty) {
              final year = positionalArgs[0] as int;
              final month =
                  positionalArgs.length > 1 ? positionalArgs[1] as int : 1;
              final day =
                  positionalArgs.length > 2 ? positionalArgs[2] as int : 1;
              final hour =
                  positionalArgs.length > 3 ? positionalArgs[3] as int : 0;
              final minute =
                  positionalArgs.length > 4 ? positionalArgs[4] as int : 0;
              final second =
                  positionalArgs.length > 5 ? positionalArgs[5] as int : 0;
              final millisecond =
                  positionalArgs.length > 6 ? positionalArgs[6] as int : 0;
              final microsecond =
                  positionalArgs.length > 7 ? positionalArgs[7] as int : 0;
              return DateTime(year, month, day, hour, minute, second,
                  millisecond, microsecond);
            }
            return DateTime.now();
          },
          'now': (visitor, positionalArgs, namedArgs) {
            return DateTime.now();
          },
          'utc': (visitor, positionalArgs, namedArgs) {
            final year = positionalArgs[0] as int;
            final month =
                positionalArgs.length > 1 ? positionalArgs[1] as int : 1;
            final day =
                positionalArgs.length > 2 ? positionalArgs[2] as int : 1;
            final hour =
                positionalArgs.length > 3 ? positionalArgs[3] as int : 0;
            final minute =
                positionalArgs.length > 4 ? positionalArgs[4] as int : 0;
            final second =
                positionalArgs.length > 5 ? positionalArgs[5] as int : 0;
            final millisecond =
                positionalArgs.length > 6 ? positionalArgs[6] as int : 0;
            final microsecond =
                positionalArgs.length > 7 ? positionalArgs[7] as int : 0;
            return DateTime.utc(year, month, day, hour, minute, second,
                millisecond, microsecond);
          },
          'fromMillisecondsSinceEpoch': (visitor, positionalArgs, namedArgs) {
            final millisecondsSinceEpoch = positionalArgs[0] as int;
            final isUtc = namedArgs['isUtc'] as bool? ?? false;
            return DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch,
                isUtc: isUtc);
          },
          'fromMicrosecondsSinceEpoch': (visitor, positionalArgs, namedArgs) {
            final microsecondsSinceEpoch = positionalArgs[0] as int;
            final isUtc = namedArgs['isUtc'] as bool? ?? false;
            return DateTime.fromMicrosecondsSinceEpoch(microsecondsSinceEpoch,
                isUtc: isUtc);
          },
        },
        staticMethods: {
          'parse': (visitor, positionalArgs, namedArgs) {
            return DateTime.parse(positionalArgs[0] as String);
          },
          'tryParse': (visitor, positionalArgs, namedArgs) {
            return DateTime.tryParse(positionalArgs[0] as String);
          },
        },
        methods: {
          'add': (visitor, target, positionalArgs, namedArgs) {
            return (target as DateTime).add(positionalArgs[0] as Duration);
          },
          'subtract': (visitor, target, positionalArgs, namedArgs) {
            return (target as DateTime).subtract(positionalArgs[0] as Duration);
          },
          'difference': (visitor, target, positionalArgs, namedArgs) {
            return (target as DateTime)
                .difference(positionalArgs[0] as DateTime);
          },
          'isBefore': (visitor, target, positionalArgs, namedArgs) {
            return (target as DateTime).isBefore(positionalArgs[0] as DateTime);
          },
          'isAfter': (visitor, target, positionalArgs, namedArgs) {
            return (target as DateTime).isAfter(positionalArgs[0] as DateTime);
          },
          'isAtSameMomentAs': (visitor, target, positionalArgs, namedArgs) {
            return (target as DateTime)
                .isAtSameMomentAs(positionalArgs[0] as DateTime);
          },
          'compareTo': (visitor, target, positionalArgs, namedArgs) {
            return (target as DateTime)
                .compareTo(positionalArgs[0] as DateTime);
          },
          'toLocal': (visitor, target, positionalArgs, namedArgs) {
            return (target as DateTime).toLocal();
          },
          'toUtc': (visitor, target, positionalArgs, namedArgs) {
            return (target as DateTime).toUtc();
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as DateTime).toString();
          },
          'toIso8601String': (visitor, target, positionalArgs, namedArgs) {
            return (target as DateTime).toIso8601String();
          },
        },
        getters: {
          'year': (visitor, target) => (target as DateTime).year,
          'month': (visitor, target) => (target as DateTime).month,
          'day': (visitor, target) => (target as DateTime).day,
          'hour': (visitor, target) => (target as DateTime).hour,
          'minute': (visitor, target) => (target as DateTime).minute,
          'second': (visitor, target) => (target as DateTime).second,
          'millisecond': (visitor, target) => (target as DateTime).millisecond,
          'microsecond': (visitor, target) => (target as DateTime).microsecond,
          'weekday': (visitor, target) => (target as DateTime).weekday,
          'millisecondsSinceEpoch': (visitor, target) =>
              (target as DateTime).millisecondsSinceEpoch,
          'microsecondsSinceEpoch': (visitor, target) =>
              (target as DateTime).microsecondsSinceEpoch,
          'timeZoneName': (visitor, target) =>
              (target as DateTime).timeZoneName,
          'timeZoneOffset': (visitor, target) =>
              (target as DateTime).timeZoneOffset,
          'isUtc': (visitor, target) => (target as DateTime).isUtc,
          'hashCode': (visitor, target) => (target as DateTime).hashCode,
          'runtimeType': (visitor, target) => (target as DateTime).runtimeType,
        },
      );
}
