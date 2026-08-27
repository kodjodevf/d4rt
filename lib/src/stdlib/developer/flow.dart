import 'dart:developer';
import 'package:d4rt/d4rt.dart';

class FlowDeveloper {
  static BridgedClass get definition => BridgedClass(
        nativeType: Flow,
        name: 'Flow',
        typeParameterCount: 0,
        isSubtypeOfFunc: (value) => value is Flow,
        staticMethods: {
          'begin': (visitor, positionalArgs, namedArgs) {
            final id = namedArgs['id'] as int? ??
                (positionalArgs.isNotEmpty ? positionalArgs[0] as int? : null);
            return id != null ? Flow.begin(id: id) : Flow.begin();
          },
          'step': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty || positionalArgs[0] is! int) {
              throw RuntimeError('Flow.step requires an int id.');
            }
            return Flow.step(positionalArgs[0] as int);
          },
          'end': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty || positionalArgs[0] is! int) {
              throw RuntimeError('Flow.end requires an int id.');
            }
            return Flow.end(positionalArgs[0] as int);
          },
        },
        constructors: {
          'begin': (visitor, positionalArgs, namedArgs) {
            final id = namedArgs['id'] as int? ??
                (positionalArgs.isNotEmpty ? positionalArgs[0] as int? : null);
            return id != null ? Flow.begin(id: id) : Flow.begin();
          },
          'step': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty || positionalArgs[0] is! int) {
              throw RuntimeError('Flow.step requires an int id.');
            }
            return Flow.step(positionalArgs[0] as int);
          },
          'end': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty || positionalArgs[0] is! int) {
              throw RuntimeError('Flow.end requires an int id.');
            }
            return Flow.end(positionalArgs[0] as int);
          },
        },
        getters: {
          'id': (visitor, target) => (target as Flow).id,
          'hashCode': (visitor, target) => (target as Flow).hashCode,
          'runtimeType': (visitor, target) => (target as Flow).runtimeType,
        },
      );
}
