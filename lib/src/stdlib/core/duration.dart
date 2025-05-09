import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';
import 'package:d4rt/src/utils/extensions/map.dart'; // Assuming extension is here

class DurationCore implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'Duration',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          // Duration constructor uses named arguments exclusively
          return namedArguments.isEmpty
              ? Duration
              : Duration(
                  days: namedArguments.get<int?>('days') ?? 0,
                  hours: namedArguments.get<int?>('hours') ?? 0,
                  minutes: namedArguments.get<int?>('minutes') ?? 0,
                  seconds: namedArguments.get<int?>('seconds') ?? 0,
                  milliseconds: namedArguments.get<int?>('milliseconds') ?? 0,
                  microseconds: namedArguments.get<int?>('microseconds') ?? 0,
                );
        },
            arity: 0, // Arity is 0 positional, but named args are used
            name: 'Duration'));
    // Static constants handled in evalMethod
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is Duration) {
      switch (name) {
        case 'inDays':
          return target.inDays;
        case 'inHours':
          return target.inHours;
        case 'inMinutes':
          return target.inMinutes;
        case 'inSeconds':
          return target.inSeconds;
        case 'inMilliseconds':
          return target.inMilliseconds;
        case 'inMicroseconds':
          return target.inMicroseconds;
        case 'compareTo':
          return target.compareTo(arguments[0] as Duration);
        case 'isNegative':
          return target.isNegative;
        case 'abs':
          return target.abs();
        case 'toString':
          return target.toString();
        case 'hashCode':
          return target.hashCode;
        default:
          throw RuntimeError(
              'Duration has no instance method mapping for "$name"');
      }
    } else {
      // static constants
      switch (name) {
        case 'hoursPerDay':
          return Duration.hoursPerDay;
        case 'microsecondsPerDay':
          return Duration.microsecondsPerDay;
        case 'microsecondsPerHour':
          return Duration.microsecondsPerHour;
        case 'microsecondsPerMillisecond':
          return Duration.microsecondsPerMillisecond;
        case 'microsecondsPerMinute':
          return Duration.microsecondsPerMinute;
        case 'microsecondsPerSecond':
          return Duration.microsecondsPerSecond;
        case 'millisecondsPerDay':
          return Duration.millisecondsPerDay;
        case 'millisecondsPerHour':
          return Duration.millisecondsPerHour;
        case 'millisecondsPerMinute':
          return Duration.millisecondsPerMinute;
        case 'millisecondsPerSecond':
          return Duration.millisecondsPerSecond;
        case 'minutesPerDay':
          return Duration.minutesPerDay;
        case 'minutesPerHour':
          return Duration.minutesPerHour;
        case 'secondsPerDay':
          return Duration.secondsPerDay;
        case 'secondsPerHour':
          return Duration.secondsPerHour;
        case 'secondsPerMinute':
          return Duration.secondsPerMinute;
        case 'zero':
          return Duration.zero;
        default:
          throw RuntimeError(
              'Duration has no static member mapping for "$name"');
      }
    }
  }
}
