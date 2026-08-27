import 'dart:developer';
import 'package:d4rt/d4rt.dart';

class TimelineDeveloper {
  static BridgedClass get definition => BridgedClass(
        nativeType: Timeline,
        name: 'Timeline',
        typeParameterCount: 0,
        isSubtypeOfFunc: (value) => value is Timeline,
        staticGetters: {
          'now': (visitor) => Timeline.now,
        },
        staticMethods: {
          'startSync': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty || positionalArgs[0] is! String) {
              throw RuntimeError("Timeline.startSync expects a String name.");
            }
            final name = positionalArgs[0] as String;
            final arguments = namedArgs['arguments'] as Map?;
            Timeline.startSync(name,
                arguments: arguments != null ? Map.from(arguments) : null);
            return null;
          },
          'finishSync': (visitor, positionalArgs, namedArgs) {
            Timeline.finishSync();
            return null;
          },
          'timeSync': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length < 2 ||
                positionalArgs[0] is! String) {
              throw RuntimeError(
                  "Timeline.timeSync expects a String name and a function callback.");
            }
            final name = positionalArgs[0] as String;
            final callback = positionalArgs[1];
            final arguments = namedArgs['arguments'] as Map?;
            return Timeline.timeSync(
              name,
              () {
                if (callback is InterpretedFunction) {
                  return callback.call(visitor, []);
                } else if (callback is Callable) {
                  return callback.call(visitor, [], {});
                } else if (callback is Function) {
                  return (callback as dynamic)();
                }
                throw RuntimeError("Invalid callback for Timeline.timeSync.");
              },
              arguments: arguments != null ? Map.from(arguments) : null,
            );
          },
          'now': (visitor, positionalArgs, namedArgs) {
            return Timeline.now;
          },
        },
      );
}

class TimelineTaskDeveloper {
  static BridgedClass get definition => BridgedClass(
        nativeType: TimelineTask,
        name: 'TimelineTask',
        typeParameterCount: 0,
        isSubtypeOfFunc: (value) => value is TimelineTask,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            final parent = namedArgs['parent'] as TimelineTask?;
            final filterKey = namedArgs['filterKey'] as String?;
            return TimelineTask(parent: parent, filterKey: filterKey);
          },
        },
        methods: {
          'start': (visitor, target, positionalArgs, namedArgs) {
            if (target is TimelineTask &&
                positionalArgs.isNotEmpty &&
                positionalArgs[0] is String) {
              final name = positionalArgs[0] as String;
              final arguments = namedArgs['arguments'] as Map?;
              target.start(name,
                  arguments: arguments != null ? Map.from(arguments) : null);
              return null;
            }
            throw RuntimeError("TimelineTask.start expects a String name.");
          },
          'finish': (visitor, target, positionalArgs, namedArgs) {
            if (target is TimelineTask) {
              final arguments = namedArgs['arguments'] as Map?;
              target.finish(
                  arguments: arguments != null ? Map.from(arguments) : null);
              return null;
            }
            throw RuntimeError("Target is not a TimelineTask for finish.");
          },
          'instant': (visitor, target, positionalArgs, namedArgs) {
            if (target is TimelineTask &&
                positionalArgs.isNotEmpty &&
                positionalArgs[0] is String) {
              final name = positionalArgs[0] as String;
              final arguments = namedArgs['arguments'] as Map?;
              target.instant(name,
                  arguments: arguments != null ? Map.from(arguments) : null);
              return null;
            }
            throw RuntimeError("TimelineTask.instant expects a String name.");
          },
          'pass': (visitor, target, positionalArgs, namedArgs) {
            if (target is TimelineTask) {
              target.pass();
              return null;
            }
            throw RuntimeError("Target is not a TimelineTask for pass.");
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as TimelineTask).toString();
          },
        },
        getters: {
          'hashCode': (visitor, target) => (target as TimelineTask).hashCode,
          'runtimeType': (visitor, target) =>
              (target as TimelineTask).runtimeType,
        },
      );
}
