import 'package:d4rt/d4rt.dart';

class DurationCore {
  static BridgedClass get definition => BridgedClass(
        nativeType: Duration,
        name: 'Duration',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            return Duration(
              days: namedArgs['days'] as int? ?? 0,
              hours: namedArgs['hours'] as int? ?? 0,
              minutes: namedArgs['minutes'] as int? ?? 0,
              seconds: namedArgs['seconds'] as int? ?? 0,
              milliseconds: namedArgs['milliseconds'] as int? ?? 0,
              microseconds: namedArgs['microseconds'] as int? ?? 0,
            );
          },
        },
        staticGetters: {
          'hoursPerDay': (visitor) {
            return Duration.hoursPerDay;
          },
          'microsecondsPerSecond': (visitor) {
            return Duration.microsecondsPerSecond;
          },
          'millisecondsPerSecond': (visitor) {
            return Duration.millisecondsPerSecond;
          },
          'secondsPerMinute': (visitor) {
            return Duration.secondsPerMinute;
          },
          'secondsPerHour': (visitor) {
            return Duration.secondsPerHour;
          },
          'zero': (visitor) {
            return Duration.zero;
          },
        },
        methods: {
          '+': (visitor, target, positionalArgs, namedArgs) {
            return (target as Duration) + (positionalArgs[0] as Duration);
          },
          '-': (visitor, target, positionalArgs, namedArgs) {
            return (target as Duration) - (positionalArgs[0] as Duration);
          },
          '*': (visitor, target, positionalArgs, namedArgs) {
            return (target as Duration) * (positionalArgs[0] as num);
          },
          '~/': (visitor, target, positionalArgs, namedArgs) {
            return (target as Duration) ~/ (positionalArgs[0] as int);
          },
          'unary-': (visitor, target, positionalArgs, namedArgs) {
            return -(target as Duration);
          },
          'abs': (visitor, target, positionalArgs, namedArgs) {
            return (target as Duration).abs();
          },
          'compareTo': (visitor, target, positionalArgs, namedArgs) {
            return (target as Duration)
                .compareTo(positionalArgs[0] as Duration);
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as Duration).toString();
          },
        },
        getters: {
          'inDays': (visitor, target) => (target as Duration).inDays,
          'inHours': (visitor, target) => (target as Duration).inHours,
          'inMinutes': (visitor, target) => (target as Duration).inMinutes,
          'inSeconds': (visitor, target) => (target as Duration).inSeconds,
          'inMilliseconds': (visitor, target) =>
              (target as Duration).inMilliseconds,
          'inMicroseconds': (visitor, target) =>
              (target as Duration).inMicroseconds,
          'isNegative': (visitor, target) => (target as Duration).isNegative,
          'hashCode': (visitor, target) => (target as Duration).hashCode,
          'runtimeType': (visitor, target) => (target as Duration).runtimeType,
        },
      );
}
