import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';
import 'package:d4rt/src/utils/extensions/list.dart';
import 'package:d4rt/src/utils/extensions/map.dart';

class DateTimeCore implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'DateTime',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          return arguments.isEmpty || arguments[0] is! int
              ? DateTime
              : DateTime(
                  arguments.get<int>(0)!,
                  arguments.get<int>(1) ?? 1,
                  arguments.get<int>(2) ?? 1,
                  arguments.get<int>(3) ?? 0,
                  arguments.get<int>(4) ?? 0,
                  arguments.get<int>(5) ?? 0,
                  arguments.get<int>(6) ?? 0,
                  arguments.get<int>(7) ?? 0);
        },
            arity: -1, // Variable arity or specific handling needed
            name: 'DateTime'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is DateTime) {
      switch (name) {
        case 'toString':
          return target.toString();
        case 'isBefore':
          return target.isBefore(arguments[0] as DateTime);
        case 'isAfter':
          return target.isAfter(arguments[0] as DateTime);
        case 'difference':
          return target.difference(arguments[0] as DateTime);
        case 'add':
          return target.add(arguments[0] as Duration);
        case 'subtract':
          return target.subtract(arguments[0] as Duration);
        case 'millisecondsSinceEpoch':
          return target.millisecondsSinceEpoch;
        case 'microsecondsSinceEpoch':
          return target.microsecondsSinceEpoch;
        case 'weekday':
          return target.weekday;
        case 'year':
          return target.year;
        case 'month':
          return target.month;
        case 'day':
          return target.day;
        case 'hour':
          return target.hour;
        case 'minute':
          return target.minute;
        case 'second':
          return target.second;
        case 'millisecond':
          return target.millisecond;
        case 'microsecond':
          return target.microsecond;
        case 'timeZoneName':
          return target.timeZoneName;
        case 'timeZoneOffset':
          return target.timeZoneOffset;
        case 'isUtc':
          return target.isUtc;
        case 'hashCode':
          return target.hashCode;
        case 'compareTo':
          return target.compareTo(arguments[0] as DateTime);
        case 'toUtc':
          return target.toUtc();
        case 'toLocal':
          return target.toLocal();
        case 'toIso8601String':
          return target.toIso8601String();
        default:
          throw RuntimeError(
              'DateTime has no instance method mapping for "$name"');
      }
    } else {
      // static methods
      switch (name) {
        case 'now':
          return DateTime.now();
        case 'parse':
          return DateTime.parse(arguments[0] as String);
        case 'tryParse':
          return DateTime.tryParse(arguments[0] as String);
        case 'fromMicrosecondsSinceEpoch':
          return DateTime.fromMicrosecondsSinceEpoch(arguments[0] as int,
              isUtc: namedArguments.get<bool?>('isUtc') ?? false);
        case 'fromMillisecondsSinceEpoch':
          return DateTime.fromMillisecondsSinceEpoch(arguments[0] as int,
              isUtc: namedArguments.get<bool?>('isUtc') ?? false);
        case 'timestamp': // Added based on dart:core
          return DateTime.timestamp();
        case 'utc':
          // DateTime.utc has positional arguments, not named
          return DateTime.utc(
              arguments[0] as int, // year
              arguments.get<int>(1) ?? 1, // month
              arguments.get<int>(2) ?? 1, // day
              arguments.get<int>(3) ?? 0, // hour
              arguments.get<int>(4) ?? 0, // minute
              arguments.get<int>(5) ?? 0, // second
              arguments.get<int>(6) ?? 0, // millisecond
              arguments.get<int>(7) ?? 0 // microsecond
              );
        default:
          throw RuntimeError(
              'DateTime has no static method mapping for "$name"');
      }
    }
  }
}

// class DateTimeCore {
//   final dateTimeBridgedClass = BridgedClassDefinition(
//     nativeType: DateTime,
//     name: 'DateTime',
//     constructors: {
//       '': (visitor, positionalArgs, namedArgs) {
//         return DateTime(
//             positionalArgs.get<int>(0)!,
//             positionalArgs.get<int>(1) ?? 1,
//             positionalArgs.get<int>(2) ?? 1,
//             positionalArgs.get<int>(3) ?? 0,
//             positionalArgs.get<int>(4) ?? 0,
//             positionalArgs.get<int>(5) ?? 0,
//             positionalArgs.get<int>(6) ?? 0,
//             positionalArgs.get<int>(7) ?? 0);
//       },
//       'now': (visitor, positionalArgs, namedArgs) => DateTime.now(),
//     },
//     staticMethods: {
//       'parse': (visitor, positionalArgs, namedArgs) =>
//           DateTime.parse(positionalArgs[0] as String),
//       'tryParse': (visitor, positionalArgs, namedArgs) =>
//           DateTime.tryParse(positionalArgs[0] as String),
//       'fromMicrosecondsSinceEpoch': (visitor, positionalArgs, namedArgs) =>
//           DateTime.fromMicrosecondsSinceEpoch(positionalArgs[0] as int,
//               isUtc: namedArgs.get<bool?>('isUtc') ?? false),
//       'fromMillisecondsSinceEpoch': (visitor, positionalArgs, namedArgs) =>
//           DateTime.fromMillisecondsSinceEpoch(positionalArgs[0] as int,
//               isUtc: namedArgs.get<bool?>('isUtc') ?? false),
//       'timestamp': (visitor, positionalArgs, namedArgs) => DateTime.timestamp(),
//       'utc': (visitor, positionalArgs, namedArgs) => DateTime.utc(
//           positionalArgs[0] as int,
//           positionalArgs.get<int>(1) ?? 1,
//           positionalArgs.get<int>(2) ?? 1,
//           positionalArgs.get<int>(3) ?? 0,
//           positionalArgs.get<int>(4) ?? 0,
//           positionalArgs.get<int>(5) ?? 0,
//           positionalArgs.get<int>(6) ?? 0,
//           positionalArgs.get<int>(7) ?? 0),
//     },
//     methods: {
//       'toString': (visitor, target, positionalArgs, namedArgs) =>
//           (target as DateTime).toString(),
//       'isBefore': (visitor, target, positionalArgs, namedArgs) =>
//           (target as DateTime).isBefore(positionalArgs[0] as DateTime),
//       'isAfter': (visitor, target, positionalArgs, namedArgs) =>
//           (target as DateTime).isAfter(positionalArgs[0] as DateTime),
//       'difference': (visitor, target, positionalArgs, namedArgs) =>
//           (target as DateTime).difference(positionalArgs[0] as DateTime),
//       'add': (visitor, target, positionalArgs, namedArgs) =>
//           (target as DateTime).add(positionalArgs[0] as Duration),
//       'subtract': (visitor, target, positionalArgs, namedArgs) =>
//           (target as DateTime).subtract(positionalArgs[0] as Duration),
//       'compareTo': (visitor, target, positionalArgs, namedArgs) =>
//           (target as DateTime).compareTo(positionalArgs[0] as DateTime),
//       'toUtc': (visitor, target, positionalArgs, namedArgs) =>
//           (target as DateTime).toUtc(),
//       'toLocal': (visitor, target, positionalArgs, namedArgs) =>
//           (target as DateTime).toLocal(),
//       'toIso8601String': (visitor, target, positionalArgs, namedArgs) =>
//           (target as DateTime).toIso8601String(),
//     },
//     getters: {
//       'millisecondsSinceEpoch': (visitor, target) =>
//           (target as DateTime).millisecondsSinceEpoch,
//       'microsecondsSinceEpoch': (visitor, target) =>
//           (target as DateTime).microsecondsSinceEpoch,
//       'weekday': (visitor, target) => (target as DateTime).weekday,
//       'year': (visitor, target) => (target as DateTime).year,
//       'month': (visitor, target) => (target as DateTime).month,
//       'day': (visitor, target) => (target as DateTime).day,
//       'hour': (visitor, target) => (target as DateTime).hour,
//       'minute': (visitor, target) => (target as DateTime).minute,
//       'second': (visitor, target) => (target as DateTime).second,
//       'millisecond': (visitor, target) => (target as DateTime).millisecond,
//       'microsecond': (visitor, target) => (target as DateTime).microsecond,
//       'timeZoneName': (visitor, target) => (target as DateTime).timeZoneName,
//       'timeZoneOffset': (visitor, target) =>
//           (target as DateTime).timeZoneOffset,
//       'isUtc': (visitor, target) => (target as DateTime).isUtc,
//       'hashCode': (visitor, target) => (target as DateTime).hashCode,
//     },
//   );

//   void setEnvironment(Environment environment) {
//     environment.defineBridge(dateTimeBridgedClass);
//   }
// }
